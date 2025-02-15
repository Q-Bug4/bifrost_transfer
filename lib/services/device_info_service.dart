import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final deviceInfoProvider = Provider((ref) => DeviceInfoService());

class DeviceInfo {
  final String name;
  final String? ipAddress;
  final String? error;

  DeviceInfo({
    required this.name,
    this.ipAddress,
    this.error,
  });
}

class DeviceInfoService {
  Future<DeviceInfo> getDeviceInfo() async {
    try {
      // 获取主机名
      final hostname = Platform.localHostname;
      
      // 获取IP地址
      String? ipAddress;
      String? error;
      
      try {
        final interfaces = await NetworkInterface.list(
          includeLinkLocal: false,
          type: InternetAddressType.IPv4,
        );

        // 过滤和排序网络接口
        final validInterfaces = interfaces.where((interface) {
          final name = interface.name.toLowerCase();
          // 排除虚拟网卡和无关接口
          if (name.contains('virtual') ||
              name.contains('vmware') ||
              name.contains('hamachi') ||
              name.contains('loopback') ||
              name.contains('pseudo') ||
              name.contains('docker')) {
            return false;
          }

          return interface.addresses.any((addr) => 
            !addr.address.startsWith('127.') && 
            !addr.address.startsWith('169.') &&
            !addr.address.startsWith('0.'));
        }).toList();

        // 对接口进行优先级排序
        validInterfaces.sort((a, b) {
          final aName = a.name.toLowerCase();
          final bName = b.name.toLowerCase();
          
          // 优先选择以太网
          if (aName.contains('ethernet') && !bName.contains('ethernet')) {
            return -1;
          }
          if (!aName.contains('ethernet') && bName.contains('ethernet')) {
            return 1;
          }
          
          // 其次选择WiFi
          if (aName.contains('wi-fi') && !bName.contains('wi-fi')) {
            return -1;
          }
          if (!aName.contains('wi-fi') && bName.contains('wi-fi')) {
            return 1;
          }
          
          return 0;
        });

        if (validInterfaces.isEmpty) {
          error = '未找到有效的网络连接';
        } else {
          // 遍历排序后的接口，选择第一个有效IP
          for (final interface in validInterfaces) {
            final validAddresses = interface.addresses.where(
              (addr) => !addr.address.startsWith('127.') && 
                       !addr.address.startsWith('169.') &&
                       !addr.address.startsWith('0.')
            ).toList();

            if (validAddresses.isNotEmpty) {
              ipAddress = validAddresses.first.address;
              break;
            }
          }

          if (ipAddress == null) {
            error = '未找到有效的IP地址';
          }
        }
      } catch (e) {
        error = '获取IP地址失败: $e';
      }

      return DeviceInfo(
        name: hostname,
        ipAddress: ipAddress,
        error: error,
      );
    } catch (e) {
      return DeviceInfo(
        name: 'Unknown Device',
        error: '获取设备信息失败: $e',
      );
    }
  }
}
