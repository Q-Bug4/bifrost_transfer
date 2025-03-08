import 'dart:io';
import 'package:logging/logging.dart';

/// 网络工具类，用于获取网络相关信息
class NetworkUtils {
  static final _logger = Logger('NetworkUtils');

  /// 需要过滤的网卡名称关键词
  static const List<String> _filteredAdapterKeywords = [
    'VMware',
    'Virtual',
    'WSL',
    'VirtualBox',
    'Hyper-V',
    'Loopback',
    'Bluetooth',
    'Docker',
    'vEthernet',
    'VPN',
    'TAP',
    'TUN',
  ];

  /// 获取本机IP地址
  ///
  /// 返回第一个有效的非虚拟网卡IPv4地址
  /// 如果没有找到有效地址，返回"127.0.0.1"
  static Future<String> getLocalIpAddress() async {
    try {
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        includeLinkLocal: false,
        type: InternetAddressType.IPv4,
      );

      // 过滤掉虚拟网卡
      final filteredInterfaces = interfaces.where((interface) {
        final name = interface.name.toLowerCase();
        return !_filteredAdapterKeywords
            .any((keyword) => name.contains(keyword.toLowerCase()));
      }).toList();

      _logger.info('找到 ${filteredInterfaces.length} 个有效网卡');

      for (var interface in filteredInterfaces) {
        _logger.info(
            '网卡: ${interface.name}, 地址: ${interface.addresses.map((a) => a.address).join(', ')}');

        // 获取第一个有效的IPv4地址
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4) {
            return addr.address;
          }
        }
      }

      // 如果没有找到有效地址，尝试使用任何可用的IPv4地址
      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 &&
              !addr.address.startsWith('127.') &&
              !addr.address.startsWith('169.254.')) {
            _logger.warning('使用备选网卡: ${interface.name}, 地址: ${addr.address}');
            return addr.address;
          }
        }
      }

      _logger.warning('未找到有效IP地址，使用本地回环地址');
      return '127.0.0.1';
    } catch (e) {
      _logger.severe('获取本机IP地址失败: $e');
      return '127.0.0.1';
    }
  }

  /// 获取本机设备名称
  ///
  /// 返回操作系统主机名
  /// 如果获取失败，返回"未知设备"
  static Future<String> getDeviceName() async {
    try {
      return Platform.localHostname;
    } catch (e) {
      _logger.severe('获取设备名称失败: $e');
      return '未知设备';
    }
  }
}
