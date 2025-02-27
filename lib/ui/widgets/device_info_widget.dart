import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../application/states/connection_state_notifier.dart';

/// 设备信息显示组件
class DeviceInfoWidget extends StatelessWidget {
  const DeviceInfoWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectionStateNotifier>(
      builder: (context, connectionStateNotifier, child) {
        final deviceInfo = connectionStateNotifier.localDeviceInfo;
        
        // 如果设备信息为空，显示加载中
        if (deviceInfo == null) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        
        return Row(
          children: [
            _buildInfoItem(
              context,
              label: '本机 IP:',
              value: deviceInfo.ipAddress,
              canCopy: true,
            ),
            const SizedBox(width: 16),
            _buildInfoItem(
              context,
              label: '设备名称:',
              value: deviceInfo.deviceName,
              canCopy: false,
            ),
          ],
        );
      },
    );
  }

  /// 构建信息项
  Widget _buildInfoItem(
    BuildContext context, {
    required String label,
    required String value,
    required bool canCopy,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (canCopy) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.copy, size: 16),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              tooltip: '复制到剪贴板',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('已复制到剪贴板'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
} 