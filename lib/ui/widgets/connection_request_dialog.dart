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
  State<ConnectionRequestDialog> createState() =>
      _ConnectionRequestDialogState();
}

class _ConnectionRequestDialogState extends State<ConnectionRequestDialog> {
  /// 是否正在处理接受连接
  bool _isAccepting = false;

  /// 是否正在处理拒绝连接
  bool _isRejecting = false;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // 禁止通过返回键关闭对话框
      onWillPop: () async => false,
      child: AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.link,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 8),
            const Text('收到连接请求'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '设备 "${widget.initiatorName}" (${widget.initiatorIp}) 请求连接到您的设备。',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            _buildPairingCodeDisplay(),
            const SizedBox(height: 16),
            const Text(
              '请确认发起方显示的配对码与上方一致，以确保连接安全。',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _isAccepting || _isRejecting ? null : _handleReject,
            child: _isRejecting
                ? const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text('正在拒绝...'),
                    ],
                  )
                : const Text('拒绝'),
          ),
          ElevatedButton(
            onPressed: _isAccepting || _isRejecting ? null : _handleAccept,
            child: _isAccepting
                ? const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text('正在连接...'),
                    ],
                  )
                : const Text('接受'),
          ),
        ],
      ),
    );
  }

  /// 构建配对码显示
  Widget _buildPairingCodeDisplay() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Text(
            '配对码',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.pairingCode,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: 8,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  /// 处理接受连接
  void _handleAccept() {
    setState(() {
      _isAccepting = true;
    });

    // 立即关闭对话框，避免在测试中留下未处理的计时器
    Navigator.of(context).pop();
    widget.onAccept();
  }

  /// 处理拒绝连接
  void _handleReject() {
    setState(() {
      _isRejecting = true;
    });

    // 立即关闭对话框，避免在测试中留下未处理的计时器
    Navigator.of(context).pop();
    widget.onReject();
  }
}
