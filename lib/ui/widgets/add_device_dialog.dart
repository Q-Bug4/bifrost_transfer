import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../application/models/device_info.dart';
import '../../application/states/device_state.dart';

class AddDeviceDialog extends StatefulWidget {
  const AddDeviceDialog({super.key});

  @override
  State<AddDeviceDialog> createState() => _AddDeviceDialogState();
}

class _AddDeviceDialogState extends State<AddDeviceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _ipController = TextEditingController();
  final _deviceNameController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _ipController.dispose();
    _deviceNameController.dispose();
    super.dispose();
  }

  Future<void> _handleAddDevice() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final deviceState = context.read<DeviceState>();
      final isValidIp = await deviceState.validateIpAddress(_ipController.text);

      if (!isValidIp) {
        setState(() {
          _errorMessage = 'IP地址无效或设备不可达';
          _isLoading = false;
        });
        return;
      }

      // 创建新设备
      final newDevice = DeviceInfo(
        deviceId: DateTime.now().millisecondsSinceEpoch.toString(),
        deviceName: _deviceNameController.text,
        ipAddress: _ipController.text,
        deviceType: DeviceType.unknown,
        connectionStatus: ConnectionStatus.disconnected,
      );

      // 生成配对码
      final pairingCode = deviceState.generatePairingCode();

      // 开始配对流程
      await deviceState.selectDevice(newDevice, pairingCode: pairingCode);
      if (deviceState.error != null) {
        setState(() {
          _errorMessage = deviceState.error;
          _isLoading = false;
        });
        return;
      }

      if (!mounted) return;

      // 显示配对码对话框
      final bool? confirmed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => PairingCodeDialog(
          pairingCode: pairingCode,
          isInitiator: true,
        ),
      );

      if (!mounted) return;

      if (confirmed == true) {
        await deviceState.confirmPairing(newDevice);
        if (deviceState.error == null) {
          Navigator.of(context).pop();
        } else {
          setState(() {
            _errorMessage = deviceState.error;
          });
        }
      } else {
        await deviceState.rejectPairing(newDevice);
      }
    } catch (e) {
      setState(() {
        _errorMessage = '添加设备失败：$e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF2D2D2D),
      title: const Text(
        '添加设备',
        style: TextStyle(color: Colors.white),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _ipController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'IP地址',
                labelStyle: TextStyle(color: Colors.grey),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF6366F1)),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'IP地址不能为空';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _deviceNameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: '设备名称',
                labelStyle: TextStyle(color: Colors.grey),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF6366F1)),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '设备名称不能为空';
                }
                return null;
              },
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: Text(
            '取消',
            style: TextStyle(
              color: _isLoading ? Colors.grey : Colors.white,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleAddDevice,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('添加'),
        ),
      ],
    );
  }
}

class PairingCodeDialog extends StatelessWidget {
  final String pairingCode;
  final bool isInitiator;

  const PairingCodeDialog({
    super.key,
    required this.pairingCode,
    required this.isInitiator,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF2D2D2D),
      title: const Text(
        '设备配对',
        style: TextStyle(color: Colors.white),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isInitiator
                ? '请在另一台设备上确认以下配对码：'
                : '请确认配对码是否匹配：',
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 16),
          Text(
            pairingCode,
            style: const TextStyle(
              color: Color(0xFF6366F1),
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 8,
            ),
          ),
          if (!isInitiator) ...[
            const SizedBox(height: 16),
            const Text(
              '请仔细核对配对码，确保与发起方显示的配对码一致',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            isInitiator ? '关闭' : '拒绝配对',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        if (!isInitiator) // 只有接收方显示确认按钮
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
            ),
            child: const Text(
              '确认配对',
              style: TextStyle(color: Colors.white),
            ),
          ),
      ],
    );
  }
} 