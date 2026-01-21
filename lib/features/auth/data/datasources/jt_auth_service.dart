import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import '../../../../core/utils/device_utils.dart';
import '../../domain/entities/user.dart';

class JtAuthService {
  final Dio _dio;

  JtAuthService(this._dio);

  Future<User> login(String account, String password) async {
    final deviceData = await DeviceUtils.getJtDeviceData();
    
    // MD5 Hash password
    final bytes = utf8.encode(password);
    final passwordMd5 = md5.convert(bytes).toString();

    final headers = {
      'Host': 'gw.jtexpress.co',
      'Appid': 'AhW1qjZi',
      'Timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
      'Signature': 'N0JCODc0ODNFNkZGNjU1QkNDMDdGMjI1NzQ3ODgxRDk=',
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
      'Content-Type': 'application/json; charset=utf-8',
      'Connection': 'keep-alive',
    };

    final body = {
      'account': account,
      'password': passwordMd5,
      'appVersion': 'V0.0.7',
      'appDeviceCode': 'WA-${deviceData.deviceId}',
      'serialnumber': deviceData.deviceId,
      'brand': deviceData.brand,
      'macAddr': deviceData.deviceId,
      'latitudeAndLongitude': '0.0,0.0', // TODO: Integrate Geolocator
    };

    _debugLog('📤 SENDING J&T LOGIN REQUEST', color: _AnsiColor.yellow);
    _debugLog('URL: https://gw.jtexpress.co/bc/out/loginV2');
    _debugLog('HEADERS:', color: _AnsiColor.cyan);
    headers.forEach((key, value) {
      _debugLog('  $key: $value', color: _AnsiColor.cyan);
    });
    _debugLog('BODY:', color: _AnsiColor.magenta);
    body.forEach((key, value) {
      final displayValue = key == 'password' ? '***HIDDEN***' : value;
      _debugLog('  $key: $displayValue', color: _AnsiColor.magenta);
    });

    try {
      final response = await _dio.post(
        'https://gw.jtexpress.co/bc/out/loginV2',
        options: Options(headers: headers),
        data: body,
      );

      _debugLog('📥 RESPONSE RECEIVED', color: _AnsiColor.green);
      _debugLog('Status Code: ${response.statusCode}', color: _AnsiColor.green);
      _debugLog('Response Data: ${response.data}', color: _AnsiColor.green);

      final data = response.data;
      if (data != null && data['code'] == 1 && data['data'] != null) {
        final userData = data['data'];
        _debugLog('✅ LOGIN SUCCESS!', color: _AnsiColor.green);
        _debugLog('User Info:', color: _AnsiColor.green);
        _debugLog('  Name: ${userData['name']}', color: _AnsiColor.green);
        _debugLog('  Staff No: ${userData['staffNo']}', color: _AnsiColor.green);
        _debugLog('  Network: ${userData['networkName']}', color: _AnsiColor.green);
        _debugLog('  Department: ${userData['deptName']}', color: _AnsiColor.green);
        _debugLog('  Token: ${userData['token']?.substring(0, 20) ?? 'N/A'}...', color: _AnsiColor.green);
        
        return User(
          account: account,
          token: userData['token'] ?? '',
          uuid: userData['uuid'] ?? '',
          id: userData['id'] ?? 0,
          name: userData['name'] ?? '',
          staffNo: userData['staffNo'] ?? '',
          networkName: userData['networkName'] ?? '',
          networkCode: userData['networkCode'] ?? '',
          mobile: userData['mobile'] ?? '',
          email: userData['email'] ?? '',
          financialCenterDesc: userData['financialCenterDesc'] ?? '',
          deptName: userData['deptName'] ?? '',
          postName: userData['postName'] ?? '',
          loginTime: userData['loginTime'] ?? '',
        );
      } else {
        final errorMsg = data['msg'] ?? 'Login failed';
        _debugLog('❌ LOGIN FAILED: $errorMsg', color: _AnsiColor.red);
        throw Exception(errorMsg);
      }
    } catch (e) {
      _debugLog('💥 EXCEPTION CAUGHT: $e', color: _AnsiColor.red);
      rethrow;
    }
  }

  void _debugLog(String message, {_AnsiColor color = _AnsiColor.white}) {
    const reset = '\x1B[0m';
    final colorCode = _getColorCode(color);
    // ignore: avoid_print
    print('$colorCode[JtAuthService] $message$reset');
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
