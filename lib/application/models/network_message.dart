import 'dart:convert';

class NetworkMessage {
  final String type;
  final String deviceId;
  final Map<String, dynamic> data;

  NetworkMessage({
    required this.type,
    required this.deviceId,
    required this.data,
  });

  Map<String, dynamic> toJson() => {
    'type': type,
    'deviceId': deviceId,
    'data': data,
  };

  factory NetworkMessage.fromJson(Map<String, dynamic> json) => NetworkMessage(
    type: json['type'],
    deviceId: json['deviceId'],
    data: json['data'],
  );

  @override
  String toString() => jsonEncode(toJson());
} 