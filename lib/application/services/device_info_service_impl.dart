import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import '../models/device_info_model.dart';
import 'device_info_service.dart';
import '../../infrastructure/utils/network_utils.dart';

/// 设备信息服务实现
class DeviceInfoServiceImpl implements DeviceInfoService {
  /// 设备信息插件
  final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();

  @override
  Future<DeviceInfoModel> getDeviceInfo() async {
    String deviceName = 'Unknown Device';
    String ipAddress = 'Unknown IP';

    try {
      // 获取设备名称
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfoPlugin.androidInfo;
        deviceName = androidInfo.model;
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfoPlugin.iosInfo;
        deviceName = iosInfo.name ?? 'iOS Device';
      } else if (Platform.isWindows) {
        final windowsInfo = await _deviceInfoPlugin.windowsInfo;
        deviceName = windowsInfo.computerName;
      } else if (Platform.isMacOS) {
        final macOsInfo = await _deviceInfoPlugin.macOsInfo;
        deviceName = macOsInfo.computerName;
      } else if (Platform.isLinux) {
        final linuxInfo = await _deviceInfoPlugin.linuxInfo;
        deviceName = linuxInfo.prettyName;
      }

      // 使用 NetworkUtils 获取IP地址
      ipAddress = await NetworkUtils.getLocalIpAddress();
    } catch (e) {
      // 出错时使用默认值
      print('获取设备信息失败: $e');
    }

    return DeviceInfoModel(
      deviceName: deviceName,
      ipAddress: ipAddress,
    );
  }
}
