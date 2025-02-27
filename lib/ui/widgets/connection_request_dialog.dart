import 'package:flutter/material.dart';

/// 连接请求对话框组件
class ConnectionRequestDialog extends StatelessWidget {
  /// 发起方IP地址
  final String initiatorIp;
  
  /// 发起方设备名称
  final String initiatorName;
  
  /// 配对码
  final String pairingCode;
  
  /// 接受连接回调
  final VoidCallback onAccept;
  
  /// 拒绝连接回调
  final VoidCallback onReject;

  /// 构造函数
  const ConnectionRequestDialog({
    Key? key,
    required this.initiatorIp,
    required this.initiatorName,
    required this.pairingCode,
    required this.onAccept,
    required this.onReject,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('收到连接请求'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('设备 "$initiatorName" (${initiatorIp}) 请求连接到您的设备。'),
          const SizedBox(height: 16),
          _buildPairingCodeDisplay(),
          const SizedBox(height: 16),
          const Text('请确认发起方显示的配对码与上方一致，以确保连接安全。'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onReject();
          },
          child: const Text('拒绝'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            onAccept();
          },
          child: const Text('接受'),
        ),
      ],
    );
  }

  /// 构建配对码显示
  Widget _buildPairingCodeDisplay() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.blue.withOpacity(0.3),
        ),
      ),
      child: Center(
        child: Text(
          '配对码: $pairingCode',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 4,
          ),
        ),
      ),
    );
  }
} 