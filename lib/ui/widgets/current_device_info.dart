import 'package:flutter/material.dart';
import '../../common/theme.dart';
import '../../application/services/device_info_service.dart';
import '../../application/di/service_locator.dart';

class CurrentDeviceInfo extends StatefulWidget {
  const CurrentDeviceInfo({super.key});

  @override
  State<CurrentDeviceInfo> createState() => _CurrentDeviceInfoState();
}

class _CurrentDeviceInfoState extends State<CurrentDeviceInfo> {
  final DeviceInfoService _deviceInfoService = getIt<DeviceInfoService>();
  String _deviceName = 'Loading...';
  String _ipAddress = 'Loading...';
  bool _isOnline = false;
  IconData _deviceIcon = Icons.devices;

  @override
  void initState() {
    super.initState();
    _loadDeviceInfo();
  }

  Future<void> _loadDeviceInfo() async {
    try {
      final deviceName = await _deviceInfoService.getDeviceName();
      final ipAddress = await _deviceInfoService.getDeviceIpAddress();
      final isOnline = await _deviceInfoService.isOnline();
      
      if (mounted) {
        setState(() {
          _deviceName = deviceName;
          _ipAddress = ipAddress;
          _isOnline = isOnline;
          _deviceIcon = _deviceInfoService.getDeviceIcon();
        });
      }
    } catch (e) {
      // Handle error state
      if (mounted) {
        setState(() {
          _deviceName = 'Error';
          _ipAddress = 'Error';
          _isOnline = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.dark300,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '本机设备',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isOnline ? Colors.green : Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                _deviceIcon,
                color: AppColors.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _deviceName,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      _ipAddress,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
} 