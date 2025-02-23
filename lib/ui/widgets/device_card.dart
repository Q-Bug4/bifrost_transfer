import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import '../../application/models/device_info.dart';
import '../../application/states/device_state.dart';

class DeviceCard extends StatelessWidget {
  final DeviceInfo device;

  const DeviceCard({
    super.key,
    required this.device,
  });

  IconData _getDeviceIcon() {
    switch (device.deviceType) {
      case DeviceType.windows:
        return FontAwesomeIcons.windows;
      case DeviceType.android:
        return FontAwesomeIcons.android;
      case DeviceType.linux:
        return FontAwesomeIcons.linux;
      case DeviceType.macos:
        return FontAwesomeIcons.apple;
      case DeviceType.ios:
        return FontAwesomeIcons.mobileScreen;
      default:
        return FontAwesomeIcons.desktop;
    }
  }

  Color _getStatusColor() {
    switch (device.connectionStatus) {
      case ConnectionStatus.connected:
        return Colors.green;
      case ConnectionStatus.connecting:
        return Colors.orange;
      case ConnectionStatus.pairing:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF3D3D3D),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            _getDeviceIcon(),
            color: const Color(0xFF6366F1),
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.deviceName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                Text(
                  device.ipAddress,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _getStatusColor(),
              shape: BoxShape.circle,
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.more_vert,
              color: Colors.white,
            ),
            color: const Color(0xFF2D2D2D),
            onSelected: (value) async {
              switch (value) {
                case 'connect':
                  context.read<DeviceState>().setCurrentDevice(device);
                  break;
                case 'remove':
                  await context
                      .read<DeviceState>()
                      .removePairedDevice(device.deviceId);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'connect',
                child: Text(
                  '连接',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              const PopupMenuItem(
                value: 'remove',
                child: Text(
                  '移除配对',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
} 