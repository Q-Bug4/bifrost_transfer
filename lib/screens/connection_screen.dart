import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/connection_provider.dart';
import '../services/device_info_service.dart';

class ConnectionScreen extends ConsumerStatefulWidget {
  const ConnectionScreen({super.key});

  @override
  ConsumerState<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends ConsumerState<ConnectionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ipController = TextEditingController();
  DeviceInfo? _deviceInfo;

  @override
  void initState() {
    super.initState();
    _loadDeviceInfo();
  }

  Future<void> _loadDeviceInfo() async {
    final deviceInfoService = ref.read(deviceInfoProvider);
    final deviceInfo = await deviceInfoService.getDeviceInfo();
    if (mounted) {
      setState(() {
        _deviceInfo = deviceInfo;
      });
    }
  }

  Widget _buildDeviceInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '本机信息',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text('设备名称: ${_deviceInfo?.name ?? '未知'}'),
            if (_deviceInfo?.ipAddress != null)
              Text('IP地址: ${_deviceInfo!.ipAddress}')
            else if (_deviceInfo?.error != null)
              Text(
                _deviceInfo!.error!,
                style: const TextStyle(color: Colors.red),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(DeviceConnectionState state) {
    if (state.status == ConnectionStatus.error) {
      return Card(
        color: Colors.red[100],
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 8),
              Text(
                state.errorMessage ?? '连接失败',
                style: const TextStyle(color: Colors.red),
              ),
            ],
          ),
        ),
      );
    }

    if (state.status == ConnectionStatus.receivingRequest) {
      return Card(
        color: Colors.blue[100],
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Icon(Icons.device_hub, color: Colors.blue, size: 48),
              const SizedBox(height: 8),
              Text('收到来自 ${state.device?.name} 的连接请求'),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      ref.read(connectionStateProvider.notifier).acceptConnection();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: const Text('接受'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      ref.read(connectionStateProvider.notifier).rejectConnection();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: const Text('拒绝'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    if (state.status == ConnectionStatus.connecting) {
      return Card(
        color: Colors.orange[100],
        child: const Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 8),
              Text('正在连接...'),
            ],
          ),
        ),
      );
    }

    if (state.status == ConnectionStatus.awaitingConfirmation) {
      return Card(
        color: Colors.orange[100],
        child: const Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 8),
              Text('等待对方确认...'),
            ],
          ),
        ),
      );
    }

    if (state.status == ConnectionStatus.connected) {
      return Card(
        color: Colors.green[100],
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.green, size: 48),
              const SizedBox(height: 8),
              Text('已连接到 ${state.device?.name}'),
            ],
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildConnectionForm(DeviceConnectionState state) {
    final isFormEnabled = state.status == ConnectionStatus.disconnected;

    return Form(
      key: _formKey,
      child: TextFormField(
        controller: _ipController,
        enabled: isFormEnabled,
        decoration: const InputDecoration(
          labelText: '目标IP地址',
          border: OutlineInputBorder(),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return '请输入IP地址';
          }
          final parts = value.split('.');
          if (parts.length != 4) {
            return '请输入有效的IP地址';
          }
          for (final part in parts) {
            final number = int.tryParse(part);
            if (number == null || number < 0 || number > 255) {
              return '请输入有效的IP地址';
            }
          }
          return null;
        },
      ),
    );
  }

  Widget _buildActionButtons(DeviceConnectionState state) {
    if (state.status == ConnectionStatus.awaitingConfirmation) {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                ref.read(connectionStateProvider.notifier).acceptConnection();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('接受连接', style: TextStyle(fontSize: 18)),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                ref.read(connectionStateProvider.notifier).rejectConnection();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('拒绝连接', style: TextStyle(fontSize: 18)),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton(
          onPressed: state.status == ConnectionStatus.disconnected
              ? () async {
                  if (_formKey.currentState!.validate()) {
                    await ref.read(connectionStateProvider.notifier).connect(
                          _deviceInfo?.name ?? 'Unknown Device',
                          _ipController.text,
                        );
                  }
                }
              : null,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              state.status == ConnectionStatus.disconnected ? '连接' : '已连接',
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ),
        if (state.status != ConnectionStatus.disconnected) ...[
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () {
              ref.read(connectionStateProvider.notifier).disconnect();
            },
            child: const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('断开连接', style: TextStyle(fontSize: 18)),
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(connectionStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('连接设备'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDeviceInfoCard(),
              const SizedBox(height: 16),
              _buildStatusCard(state),
              const SizedBox(height: 24),
              _buildConnectionForm(state),
              const SizedBox(height: 24),
              _buildActionButtons(state),
              if (state.messages.isNotEmpty) ...[
                const SizedBox(height: 24),
                const Text(
                  '连接日志',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: state.messages.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        dense: true,
                        title: Text(state.messages[index]),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }
}
