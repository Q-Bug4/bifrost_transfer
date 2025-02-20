enum DeviceType {
  computer,
  mobile,
  tablet,
  server,
  other,
}

class Device {
  final String name;
  final String address;
  final DeviceType type;
  final bool isConnected;

  Device({
    required this.name,
    required this.address,
    required this.type,
    this.isConnected = false,
  });

  Device copyWith({
    String? name,
    String? address,
    DeviceType? type,
    bool? isConnected,
  }) {
    return Device(
      name: name ?? this.name,
      address: address ?? this.address,
      type: type ?? this.type,
      isConnected: isConnected ?? this.isConnected,
    );
  }
} 