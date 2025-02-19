import 'package:flutter/material.dart';

abstract class DeviceInfoService {
  /// Get the current device name
  Future<String> getDeviceName();
  
  /// Get the current device IP address
  /// Returns the first non-loopback IPv4 address
  Future<String> getDeviceIpAddress();
  
  /// Get the device type icon
  /// Returns the appropriate icon based on the platform
  IconData getDeviceIcon();
  
  /// Check if the device is online
  Future<bool> isOnline();
} 