class Device {
  final String name;
  final String ipAddress;
  final bool isConnected;

  Device({
    required this.name,
    required this.ipAddress,
    this.isConnected = false,
  });

  Device copyWith({
    String? name,
    String? ipAddress,
    bool? isConnected,
  }) {
    return Device(
      name: name ?? this.name,
      ipAddress: ipAddress ?? this.ipAddress,
      isConnected: isConnected ?? this.isConnected,
    );
  }
}
