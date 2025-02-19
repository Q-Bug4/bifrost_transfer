import 'package:flutter/material.dart';
import '../../common/theme.dart';

class DeviceListItem extends StatelessWidget {
  final String name;
  final String ipAddress;
  final IconData deviceIcon;
  final bool isConnected;

  const DeviceListItem({
    super.key,
    required this.name,
    required this.ipAddress,
    required this.deviceIcon,
    this.isConnected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.dark300,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(deviceIcon, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: Theme.of(context).textTheme.bodyMedium),
                Text(ipAddress, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isConnected ? Colors.green : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
} 