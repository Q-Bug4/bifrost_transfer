import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:network_info_plus/network_info_plus.dart';

final networkServiceProvider = Provider((ref) => NetworkService());

class NetworkService {
  final _networkInfo = NetworkInfo();
  
  Future<String?> getLocalIpAddress() async {
    try {
      return await _networkInfo.getWifiIP();
    } catch (e) {
      return null;
    }
  }

  Future<bool> testConnection(String address) async {
    try {
      // 简单的连接测试，后续会改进
      await Future.delayed(const Duration(seconds: 1));
      return address.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
