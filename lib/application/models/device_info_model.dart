/// 设备信息模型类，用于表示设备的基本信息
class DeviceInfoModel {
  /// 设备名称
  final String deviceName;
  
  /// 设备IP地址
  final String ipAddress;

  /// 构造函数
  DeviceInfoModel({
    required this.deviceName,
    required this.ipAddress,
  });

  /// 创建一个新的设备信息模型实例，用于信息更新
  DeviceInfoModel copyWith({
    String? deviceName,
    String? ipAddress,
  }) {
    return DeviceInfoModel(
      deviceName: deviceName ?? this.deviceName,
      ipAddress: ipAddress ?? this.ipAddress,
    );
  }
} 