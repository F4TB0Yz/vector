import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/user.dart';

class AuthLocalDataSource {
  static const _keyUser = 'jt_auth_user';
  static const _keyToken = 'jt_auth_token';
  
  static const String _ansiCyan = '\x1B[36m';
  static const String _ansiGreen = '\x1B[32m';
  static const String _ansiRed = '\x1B[31m';
  static const String _ansiReset = '\x1B[0m';

  Future<void> saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    
    final userMap = {
      'account': user.account,
      'token': user.token,
      'uuid': user.uuid,
      'id': user.id,
      'name': user.name,
      'staffNo': user.staffNo,
      'networkName': user.networkName,
      'networkCode': user.networkCode,
      'mobile': user.mobile,
      'email': user.email,
      'financialCenterDesc': user.financialCenterDesc,
      'deptName': user.deptName,
      'postName': user.postName,
      'loginTime': user.loginTime,
    };
    
    await prefs.setString(_keyUser, jsonEncode(userMap));
    await prefs.setString(_keyToken, user.token);
    
    _debugLog('💾 USER & TOKEN SAVED TO LOCAL STORAGE', _ansiGreen);
    _debugLog('Token: ${user.token.substring(0, 20)}...', _ansiCyan);
  }

  Future<User?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_keyUser);
    
    if (userJson == null) {
      _debugLog('❌ NO USER FOUND IN LOCAL STORAGE', _ansiRed);
      return null;
    }
    
    try {
      final userMap = jsonDecode(userJson) as Map<String, dynamic>;
      final user = User(
        account: userMap['account'] ?? '',
        token: userMap['token'] ?? '',
        uuid: userMap['uuid'] ?? '',
        id: userMap['id'] ?? 0,
        name: userMap['name'] ?? '',
        staffNo: userMap['staffNo'] ?? '',
        networkName: userMap['networkName'] ?? '',
        networkCode: userMap['networkCode'] ?? '',
        mobile: userMap['mobile'] ?? '',
        email: userMap['email'] ?? '',
        financialCenterDesc: userMap['financialCenterDesc'] ?? '',
        deptName: userMap['deptName'] ?? '',
        postName: userMap['postName'] ?? '',
        loginTime: userMap['loginTime'] ?? '',
      );
      
      _debugLog('✅ USER LOADED FROM LOCAL STORAGE', _ansiGreen);
      _debugLog('Name: ${user.name}', _ansiCyan);
      return user;
    } catch (e) {
      _debugLog('💥 ERROR LOADING USER: $e', _ansiRed);
      return null;
    }
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_keyToken);
    
    if (token != null) {
      _debugLog('🔑 TOKEN RETRIEVED: ${token.substring(0, 20)}...', _ansiCyan);
    } else {
      _debugLog('❌ NO TOKEN FOUND', _ansiRed);
    }
    
    return token;
  }

  Future<void> clearAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUser);
    await prefs.remove(_keyToken);
    _debugLog('🗑️ AUTH DATA CLEARED', _ansiRed);
  }

  void _debugLog(String message, String color) {
    if (kDebugMode) {
      print('$color[AuthLocalDataSource] $message$_ansiReset');
    }
  }
}
