import 'dart:convert';

enum DeviceType {
  windows,
  android,
  linux,
  macos,
  ios,
  unknown
}

enum ConnectionStatus {
  connected,
  disconnected,
  connecting,
  pairing
}

class DeviceInfo {
  final String deviceId;
  final String deviceName;
  final String ipAddress;
  final DeviceType deviceType;
  ConnectionStatus connectionStatus;
  bool isPaired;

  DeviceInfo({
    required this.deviceId,
    required this.deviceName,
    required this.ipAddress,
    required this.deviceType,
    this.connectionStatus = ConnectionStatus.disconnected,
    this.isPaired = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'deviceName': deviceName,
      'ipAddress': ipAddress,
      'deviceType': deviceType.toString(),
      'connectionStatus': connectionStatus.toString(),
      'isPaired': isPaired,
    };
  }

  factory DeviceInfo.fromJson(Map<String, dynamic> json) {
    return DeviceInfo(
      deviceId: json['deviceId'],
      deviceName: json['deviceName'],
      ipAddress: json['ipAddress'],
      deviceType: DeviceType.values.firstWhere(
        (e) => e.toString() == json['deviceType'],
        orElse: () => DeviceType.unknown,
      ),
      connectionStatus: ConnectionStatus.values.firstWhere(
        (e) => e.toString() == json['connectionStatus'],
        orElse: () => ConnectionStatus.disconnected,
      ),
      isPaired: json['isPaired'] ?? false,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeviceInfo &&
          runtimeType == other.runtimeType &&
          deviceId == other.deviceId;

  @override
  int get hashCode => deviceId.hashCode;
} 