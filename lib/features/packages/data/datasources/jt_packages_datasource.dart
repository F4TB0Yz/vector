import 'package:dio/dio.dart';
import 'dart:convert';
import '../../../../core/utils/device_utils.dart';
import '../models/jt_package_model.dart';

abstract class JTPackagesDataSource {
  Future<List<JTPackageModel>> getPackages(String authToken);
}

class JTPackagesDataSourceImpl implements JTPackagesDataSource {
  final Dio _dio;

  JTPackagesDataSourceImpl(this._dio);

  @override
  Future<List<JTPackageModel>> getPackages(String authToken) async {
    final deviceData = await DeviceUtils.getJtDeviceData();
    final now = DateTime.now();
    final startTime = now
        .subtract(const Duration(days: 7))
        .toString()
        .substring(0, 19);
    final endTime = now
        .add(const Duration(days: 1))
        .toString()
        .substring(0, 19);

    final headers = {
      'Host': 'gw.jtexpress.co',
      'Appid': 'AhW1qjZi',
      'Timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
      'Signature': 'RjcyMkE5RkY2NDgyMDMwODBBNkJERTkzNTc4NTE3RTA=',
      'Device-Id': deviceData.deviceId,
      'Device-Version': 'Android-${deviceData.androidVersion}',
      'Device-Name': deviceData.model,
      'App-Platform': 'Android_com.jtexpress.standardout',
      'User-Agent': 'Android-${deviceData.model}/app_out',
      'Devicefrom': 'android',
      'App-Version': '0.0.7',
      'App-Channel': 'Outfield Deliver',
      'Langtype': 'ES',
      'Countrycode': 'CO',
      'Timezone': 'GMT-0500',
      'X-Api-Key': 'IvV71IO6kf1xcVuCKehlk50Okoly2VBL5qHzlf0K',
      'Authtoken': authToken,
      'Content-Type': 'application/json; charset=UTF-8',
      'Connection': 'keep-alive',
    };

    final body = {
      'isAbnormal': 0,
      'address': '',
      'phone': '',
      'orderFlag': 11,
      'waybillId': '',
      'staffLngLat': '0.0,0.0',
      'startTime': startTime,
      'endTime': endTime,
      'pageNum': 1,
      'taskStatus': 3,
      'customerName': '',
    };

    _debugLog('📤 SENDING J&T PACKAGES REQUEST', color: _AnsiColor.yellow);
    _debugLog('URL: https://gw.jtexpress.co/bc/task/mergeAwaitDelivery/all');
    _debugLog('HEADERS:', color: _AnsiColor.cyan);
    headers.forEach((key, value) {
      if (key == 'Authtoken' || key == 'Signature') {
        _debugLog(
          '  $key: ${value.toString().substring(0, 5)}...',
          color: _AnsiColor.cyan,
        );
      } else {
        _debugLog('  $key: $value', color: _AnsiColor.cyan);
      }
    });
    _debugLog('BODY:', color: _AnsiColor.magenta);
    _debugLog(body.toString(), color: _AnsiColor.magenta);

    try {
      final response = await _dio.post(
        'https://gw.jtexpress.co/bc/task/mergeAwaitDelivery/all',
        options: Options(headers: headers),
        data: body,
      );

      _debugLog('📥 RESPONSE RECEIVED', color: _AnsiColor.green);
      _debugLog('Status Code: ${response.statusCode}', color: _AnsiColor.green);

      if (response.statusCode == 200 && response.data != null) {
        dynamic data = response.data;
        _debugLog(
          'Response Data Type: ${data.runtimeType}',
          color: _AnsiColor.cyan,
        );

        // If data is String, try to decode it
        if (data is String) {
          try {
            _debugLog(
              'ℹ️ Response is String. Attempting to decode JSON...',
              color: _AnsiColor.yellow,
            );
            data = jsonDecode(data);
            _debugLog('✅ JSON Decoded successfully', color: _AnsiColor.green);
          } catch (e) {
            _debugLog(
              '❌ Failed to decode JSON string: $e',
              color: _AnsiColor.red,
            );
            throw Exception('Invalid JSON response from server');
          }
        }

        // Log snippet after potential decoding
        _debugLog(
          'Response Data Snippet: ${data.toString().substring(0, data.toString().length > 200 ? 200 : data.toString().length)}...',
          color: _AnsiColor.cyan,
        );

        if (data is Map) {
          // Check for specific error codes
          // 135010037 = "没有访问权限" (No access permission) -> Token expired or invalid
          if (data['code'] == 135010037) {
            _debugLog(
              '❌ AUTH ERROR: Session expired/Invalid token (Code 135010037)',
              color: _AnsiColor.red,
            );
            throw Exception(
              'Sesión expirada. Por favor inicia sesión nuevamente.',
            );
          }

          if (data['code'] == 1 && data['data'] != null) {
            final dynamic innerData = data['data'];
            List<dynamic> list = [];

            if (innerData is List) {
              _debugLog(
                'ℹ️ data["data"] is a List. Using it directly.',
                color: _AnsiColor.yellow,
              );
              list = innerData;
            } else if (innerData is Map && innerData['list'] != null) {
              _debugLog(
                'ℹ️ data["data"] is a Map. Accessing ["list"].',
                color: _AnsiColor.yellow,
              );
              list = innerData['list'];
            }

            if (list.isNotEmpty) {
              // Data-Sync: Process and expand grouped packages
              final packages = _processPackageList(list);

              _debugLog(
                '✅ PACKAGES FOUND: ${packages.length} (from ${list.length} items)',
                color: _AnsiColor.green,
              );
              return packages;
            }
          }

          // If we are here, it means success code but no list, or error code
          if (data['code'] != 1) {
            _debugLog('❌ API ERROR: ${data['msg']}', color: _AnsiColor.red);
            throw Exception(data['msg'] ?? 'Unknown API error');
          }
          _debugLog(
            '⚠️ NO PACKAGES FOUND (Empty List)',
            color: _AnsiColor.yellow,
          );
          return [];
        } else {
          _debugLog(
            '⚠️ Unexpected root structure: ${data.runtimeType}',
            color: _AnsiColor.red,
          );
          return [];
        }
      } else {
        _debugLog(
          '❌ HTTP ERROR: ${response.statusCode}',
          color: _AnsiColor.red,
        );
        throw Exception('Failed to load packages: ${response.statusCode}');
      }
    } catch (e) {
      _debugLog('💥 EXCEPTION: $e', color: _AnsiColor.red);
      rethrow;
    }
  }

  /// Data-Sync: Process package list and expand grouped packages
  ///
  /// J&T API returns grouped packages in a special format:
  /// - ifMerge: true indicates a grouped package
  /// - opsDeliverTaskAPIVOS: array containing individual packages
  ///
  /// This method expands grouped packages into individual ones and marks them accordingly.
  List<JTPackageModel> _processPackageList(List<dynamic> list) {
    final List<JTPackageModel> packages = [];

    for (final item in list) {
      // Check for grouped packages
      if (item['ifMerge'] == true && item['opsDeliverTaskAPIVOS'] != null) {
        final subList = item['opsDeliverTaskAPIVOS'] as List;
        _debugLog(
          '📦 Found grouped package with ${subList.length} items',
          color: _AnsiColor.cyan,
        );

        // Extract and mark each package as grouped
        for (final subItem in subList) {
          packages.add(JTPackageModel.fromJson(subItem, isGrouped: true));
        }
      } else if (item['waybillNo'] != null) {
        // Regular individual package
        packages.add(JTPackageModel.fromJson(item, isGrouped: false));
      }
    }

    return packages;
  }

  void _debugLog(String message, {_AnsiColor color = _AnsiColor.white}) {
    // ignore: avoid_print
    print('${_getColorCode(color)}[JTPackages] $message\x1B[0m');
  }

  String _getColorCode(_AnsiColor color) {
    switch (color) {
      case _AnsiColor.green:
        return '\x1B[32m';
      case _AnsiColor.yellow:
        return '\x1B[33m';
      case _AnsiColor.cyan:
        return '\x1B[36m';
      case _AnsiColor.magenta:
        return '\x1B[35m';
      case _AnsiColor.red:
        return '\x1B[31m';
      case _AnsiColor.white:
        return '\x1B[37m';
    }
  }
}

enum _AnsiColor { green, yellow, cyan, magenta, red, white }
