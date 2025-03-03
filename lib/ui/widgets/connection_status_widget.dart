import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../application/models/connection_model.dart';
import '../../application/states/connection_state_notifier.dart';
import '../../application/models/connection_status.dart';

/// 连接状态显示组件
class ConnectionStatusWidget extends StatelessWidget {
  const ConnectionStatusWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectionStateNotifier>(
      builder: (context, connectionStateNotifier, child) {
        final connectionState = connectionStateNotifier.connectionState;

        // 根据连接状态返回不同的显示
        return _buildStatusIndicator(connectionState);
      },
    );
  }

  /// 构建状态指示器
  Widget _buildStatusIndicator(ConnectionModel connectionState) {
    // 根据连接状态设置不同的颜色和文本
    Color backgroundColor;
    Color textColor;
    String statusText;
    IconData iconData;

    switch (connectionState.status) {
      case ConnectionStatus.disconnected:
        backgroundColor = Colors.grey.withOpacity(0.2);
        textColor = Colors.grey;
        statusText = '未连接';
        iconData = Icons.cloud_off;
        break;
      case ConnectionStatus.connecting:
        backgroundColor = Colors.orange.withOpacity(0.2);
        textColor = Colors.orange;
        statusText = '连接中...';
        iconData = Icons.sync;
        break;
      case ConnectionStatus.awaitingConfirmation:
        backgroundColor = Colors.blue.withOpacity(0.2);
        textColor = Colors.blue;
        statusText = '等待确认...';
        iconData = Icons.hourglass_empty;
        break;
      case ConnectionStatus.connected:
        backgroundColor = Colors.green.withOpacity(0.2);
        textColor = Colors.green;
        statusText = '已连接';
        iconData = Icons.cloud_done;
        break;
      case ConnectionStatus.failed:
        backgroundColor = Colors.red.withOpacity(0.2);
        textColor = Colors.red;
        statusText = '连接失败';
        iconData = Icons.error_outline;
        break;
      case ConnectionStatus.cancelled:
        backgroundColor = Colors.grey.withOpacity(0.2);
        textColor = Colors.grey;
        statusText = '已取消';
        iconData = Icons.cancel_outlined;
        break;
    }

    // 如果已连接，显示远程设备名称
    if (connectionState.status == ConnectionStatus.connected &&
        connectionState.remoteDeviceName != null) {
      statusText = '已连接到 ${connectionState.remoteDeviceName}';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            iconData,
            size: 12,
            color: textColor,
          ),
          const SizedBox(width: 8),
          Text(
            statusText,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
