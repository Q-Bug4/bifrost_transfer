import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../application/models/connection_model.dart';
import '../../application/states/connection_state_notifier.dart';

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
        backgroundColor = Colors.red.withOpacity(0.2);
        textColor = Colors.red.shade400;
        statusText = '未连接';
        iconData = Icons.circle;
        break;
      case ConnectionStatus.connecting:
        backgroundColor = Colors.orange.withOpacity(0.2);
        textColor = Colors.orange.shade400;
        statusText = '连接中...';
        iconData = Icons.sync;
        break;
      case ConnectionStatus.awaitingConfirmation:
        backgroundColor = Colors.orange.withOpacity(0.2);
        textColor = Colors.orange.shade400;
        statusText = '等待确认...';
        iconData = Icons.hourglass_empty;
        break;
      case ConnectionStatus.connected:
        backgroundColor = Colors.green.withOpacity(0.2);
        textColor = Colors.green.shade400;
        statusText = '已连接';
        iconData = Icons.check_circle;
        break;
      case ConnectionStatus.failed:
        backgroundColor = Colors.red.withOpacity(0.2);
        textColor = Colors.red.shade400;
        statusText = '连接失败';
        iconData = Icons.error;
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