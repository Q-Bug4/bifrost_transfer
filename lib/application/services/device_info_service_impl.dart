import 'dart:io';
import 'package:flutter/material.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'device_info_service.dart';

class DeviceInfoServiceImpl implements DeviceInfoService {
  final NetworkInfo _networkInfo = NetworkInfo();
  String? _cachedIpAddress;
  DateTime? _lastIpCheck;
  static const ipCacheDuration = Duration(seconds: 30);

  @override
  Future<String> getDeviceName() async {
    try {
      if (Platform.isWindows) {
        return Platform.environment['COMPUTERNAME'] ?? 'Windows Device';
      } else if (Platform.isLinux) {
        final result = await Process.run('hostname', []);
        return (result.stdout as String).trim().isNotEmpty 
            ? (result.stdout as String).trim()
            : 'Linux Device';
      } else {
        return 'Unknown Device';
      }
    } catch (e) {
      return 'Unknown Device';
    }
  }

  @override
  Future<String> getDeviceIpAddress() async {
    // Check cache first
    if (_cachedIpAddress != null && 
        _lastIpCheck != null &&
        DateTime.now().difference(_lastIpCheck!) < ipCacheDuration) {
      return _cachedIpAddress!;
    }

    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );

      String? ip;
      
      // First try: Look for interfaces with real network names
      for (var interface in interfaces) {
        // Skip virtual and loopback interfaces
        if (_isVirtualInterface(interface.name)) {
          continue;
        }

        for (var addr in interface.addresses) {
          if (_isValidLocalIP(addr.address)) {
            ip = addr.address;
            break;
          }
        }
        if (ip != null) break;
      }

      // If no IP found, try network_info_plus as fallback
      if (ip == null) {
        ip = await _networkInfo.getWifiIP();
      }

      // Update cache
      _cachedIpAddress = ip ?? 'Unknown IP';
      _lastIpCheck = DateTime.now();
      
      return _cachedIpAddress!;
    } catch (e) {
      return 'Unknown IP';
    }
  }

  bool _isVirtualInterface(String name) {
    final virtualPatterns = [
      RegExp(r'vEthernet', caseSensitive: false),
      RegExp(r'VMware', caseSensitive: false),
      RegExp(r'VirtualBox', caseSensitive: false),
      RegExp(r'WSL', caseSensitive: false),
      RegExp(r'Hyper-V', caseSensitive: false),
    ];

    return virtualPatterns.any((pattern) => pattern.hasMatch(name));
  }

  bool _isValidLocalIP(String ip) {
    // Skip link-local and special purpose addresses
    if (ip.startsWith('169.254.') || // Link-local addresses
        ip.startsWith('172.') ||     // Docker and other virtual networks often use these
        ip == '127.0.0.1') {         // Loopback
      return false;
    }

    // Common local network ranges
    final localPatterns = [
      RegExp(r'^192\.168\.\d{1,3}\.\d{1,3}$'),
      RegExp(r'^10\.\d{1,3}\.\d{1,3}\.\d{1,3}$'),
    ];

    return localPatterns.any((pattern) => pattern.hasMatch(ip));
  }

  @override
  IconData getDeviceIcon() {
    if (Platform.isWindows) {
      return Icons.computer;
    } else if (Platform.isLinux) {
      return Icons.computer;  // Could use different icon for Linux
    } else {
      return Icons.devices;
    }
  }

  @override
  Future<bool> isOnline() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
} 