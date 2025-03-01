import '../models/device_info_model.dart';

/// 设备信息服务接口，用于获取设备信息
abstract class DeviceInfoService {
  /// 获取本地设备信息
  Future<DeviceInfoModel> getDeviceInfo();
}
