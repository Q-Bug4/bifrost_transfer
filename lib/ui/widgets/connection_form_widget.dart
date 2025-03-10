import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../application/models/connection_model.dart';
import '../../application/states/connection_state_notifier.dart';
import 'package:flutter/services.dart';
import '../../application/models/connection_status.dart';

/// 连接表单组件
class ConnectionFormWidget extends StatefulWidget {
  const ConnectionFormWidget({Key? key}) : super(key: key);

  @override
  State<ConnectionFormWidget> createState() => _ConnectionFormWidgetState();
}

class _ConnectionFormWidgetState extends State<ConnectionFormWidget> {
  /// IP地址输入控制器
  final _ipAddressController = TextEditingController();

  /// 表单键
  final _formKey = GlobalKey<FormState>();

  /// 错误信息
  String? _ipError;

  @override
  void dispose() {
    _ipAddressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final connectionState = Provider.of<ConnectionStateNotifier>(context);
    final connectionStatus = connectionState.connectionState.status;
    final isConnecting = connectionStatus == ConnectionStatus.connecting;
    final isAwaitingConfirmation =
        connectionStatus == ConnectionStatus.awaitingConfirmation;
    final isConnected = connectionStatus == ConnectionStatus.connected;
    final hasFailed = connectionStatus == ConnectionStatus.failed;

    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  '连接到设备',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _ipAddressController,
                    decoration: InputDecoration(
                      labelText: 'IP地址',
                      hintText: '输入目标设备的IP地址',
                      errorText: _ipError,
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 12.0,
                        horizontal: 16.0,
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _ipError = null;
                      });
                    },
                    enabled: !(isConnecting || isAwaitingConfirmation),
                  ),
                ),
                const SizedBox(width: 16.0),
                ElevatedButton(
                  onPressed: (isConnecting || isAwaitingConfirmation)
                      ? () => _cancelConnection(connectionState)
                      : () => _connect(connectionState),
                  child: Text(
                    (isConnecting || isAwaitingConfirmation) ? '取消' : '连接',
                  ),
                ),
              ],
            ),
            if (isConnecting || isAwaitingConfirmation)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: _buildConnectingStatus(context, connectionState),
              ),
            if (isConnected)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: _buildConnectedStatus(context, connectionState),
              ),
            if (hasFailed)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: _buildFailedMessage(context),
              ),
          ],
        ),
      ),
    );
  }

  /// 构建连接中状态的UI
  Widget _buildConnectingStatus(
      BuildContext context, ConnectionStateNotifier connectionState) {
    final status = connectionState.connectionState.status;
    final pairingCode = connectionState.connectionState.pairingCode;
    final targetIp = connectionState.connectionState.remoteIpAddress;

    String statusText = '正在连接到 $targetIp...';
    if (status == ConnectionStatus.awaitingConfirmation) {
      statusText = '等待设备确认连接...';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(statusText),
        if (pairingCode != null && pairingCode.isNotEmpty) ...[
          const SizedBox(height: 16.0),
          Text(
            '配对码: $pairingCode',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8.0),
          const Text('请确保目标设备上输入相同的配对码'),
        ],
      ],
    );
  }

  /// 构建已连接状态的UI
  Widget _buildConnectedStatus(
      BuildContext context, ConnectionStateNotifier connectionState) {
    final remoteDeviceName = connectionState.connectionState.remoteDeviceName;
    final remoteIp = connectionState.connectionState.remoteIpAddress;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('已连接到 $remoteDeviceName ($remoteIp)'),
      ],
    );
  }

  /// 构建连接失败状态的UI
  Widget _buildFailedMessage(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '连接失败',
          style: TextStyle(color: Colors.red),
        ),
        SizedBox(height: 8.0),
        Text('请检查IP地址是否正确，并确保目标设备已开启'),
      ],
    );
  }

  /// 发起连接
  Future<void> _connect(ConnectionStateNotifier connectionState) async {
    // 验证IP地址
    final ipAddress = _ipAddressController.text;
    if (ipAddress.isEmpty) {
      setState(() {
        _ipError = '请输入IP地址';
      });
      return;
    }

    // 完整的IP地址格式验证
    final ipRegex = RegExp(r'^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$');
    if (!ipRegex.hasMatch(ipAddress)) {
      setState(() {
        _ipError = '请输入有效的IP地址格式';
      });
      return;
    }

    // 验证每个段的数值范围
    final parts = ipAddress.split('.');
    for (var part in parts) {
      final intValue = int.parse(part);
      if (intValue < 0 || intValue > 255) {
        setState(() {
          _ipError = '请输入有效的IP地址（每段为0-255的数字）';
        });
        return;
      }
    }

    try {
      await connectionState.initiateConnection(ipAddress);
    } catch (e) {
      if (mounted) {
        setState(() {
          _ipError = e.toString();
        });
      }
    }
  }

  void _cancelConnection(ConnectionStateNotifier connectionState) {
    connectionState.cancelConnection();
  }
}
