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
      // Try to get IP using network_info_plus
      String? ip = await _networkInfo.getWifiIP();
      
      // If that fails, try alternative method
      if (ip == null || ip.isEmpty) {
        final interfaces = await NetworkInterface.list(
          type: InternetAddressType.IPv4,
          includeLinkLocal: false,
        );

        for (var interface in interfaces) {
          for (var addr in interface.addresses) {
            if (!addr.isLoopback && addr.type == InternetAddressType.IPv4) {
              ip = addr.address;
              break;
            }
          }
          if (ip != null) break;
        }
      }

      // Update cache
      _cachedIpAddress = ip ?? 'Unknown IP';
      _lastIpCheck = DateTime.now();
      
      return _cachedIpAddress!;
    } catch (e) {
      return 'Unknown IP';
    }
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