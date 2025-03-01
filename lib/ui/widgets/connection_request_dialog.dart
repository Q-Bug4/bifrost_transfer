import 'package:flutter/material.dart';

/// 连接请求对话框组件
class ConnectionRequestDialog extends StatefulWidget {
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

  /// 测试模式，跳过延迟
  final bool testMode;

  /// 构造函数
  const ConnectionRequestDialog({
    Key? key,
    required this.initiatorIp,
    required this.initiatorName,
    required this.pairingCode,
    required this.onAccept,
    required this.onReject,
    this.testMode = false,
  }) : super(key: key);

  @override
  State<ConnectionRequestDialog> createState() =>
      _ConnectionRequestDialogState();
}

class _ConnectionRequestDialogState extends State<ConnectionRequestDialog> {
  /// 是否正在处理接受请求
  bool _isAccepting = false;

  /// 是否正在处理拒绝请求
  bool _isRejecting = false;

  /// 处理接受请求
  void _handleAccept() async {
    setState(() {
      _isAccepting = true;
    });

    // 在测试模式下跳过延迟
    if (!widget.testMode) {
      // 延迟执行回调，以便显示加载状态
      await Future.delayed(const Duration(milliseconds: 500));
    }

    widget.onAccept();
  }

  /// 处理拒绝请求
  void _handleReject() async {
    setState(() {
      _isRejecting = true;
    });

    // 在测试模式下跳过延迟
    if (!widget.testMode) {
      // 延迟执行回调，以便显示加载状态
      await Future.delayed(const Duration(milliseconds: 300));
    }

    widget.onReject();
  }

  @override
  Widget build(BuildContext context) {
    // 是否正在处理中
    final bool isProcessing = _isAccepting || _isRejecting;

    return AlertDialog(
      title: const Text('收到连接请求'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
              '设备 "${widget.initiatorName}" (${widget.initiatorIp}) 请求连接到您的设备。'),
          const SizedBox(height: 16),
          const Text('请确认对方设备上显示的配对码与下方一致：'),
          const SizedBox(height: 8),
          Center(
            child: Text(
              widget.pairingCode,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: isProcessing ? null : _handleReject,
          child: Text(_isRejecting ? '正在拒绝...' : '拒绝'),
        ),
        ElevatedButton(
          onPressed: isProcessing ? null : _handleAccept,
          child: Text(_isAccepting ? '正在连接...' : '接受'),
        ),
      ],
    );
  }
}
