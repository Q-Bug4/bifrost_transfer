import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../application/models/device_info.dart';
import '../../application/states/device_state.dart';

class DeviceListScreen extends StatefulWidget {
  const DeviceListScreen({super.key});

  @override
  _DeviceListScreenState createState() => _DeviceListScreenState();
}

class _DeviceListScreenState extends State<DeviceListScreen> {
  late DeviceState _deviceState;

  @override
  void initState() {
    super.initState();
    _deviceState = context.read<DeviceState>();
    _deviceState.addListener(_handleStateChange);
  }

  void _handleStateChange() {
    final deviceState = _deviceState;
    if (deviceState.currentDevice != null && deviceState.pairingCode != null) {
      _showPairingRequestDialog(deviceState.currentDevice!, deviceState.pairingCode!);
    }
  }

  // 显示配对请求对话框
  void _showPairingRequestDialog(DeviceInfo device, String pairingCode) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('配对请求'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('设备名称: ${device.deviceName}'),
            Text('设备ID: ${device.deviceId}'),
            Text('IP地址: ${device.ipAddress}'),
            const SizedBox(height: 16),
            Text('配对码: $pairingCode'),
            const SizedBox(height: 16),
            const Text('请确认配对码是否匹配'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deviceState.rejectPairing(device);
            },
            child: const Text('拒绝'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deviceState.confirmPairing(device);
            },
            child: const Text('确认'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设备列表'),
      ),
      body: Consumer<DeviceState>(
        builder: (context, deviceState, child) {
          final devices = deviceState.devices;
          if (devices.isEmpty) {
            return const Center(
              child: Text('没有可用设备'),
            );
          }
          return ListView.builder(
            itemCount: devices.length,
            itemBuilder: (context, index) {
              final device = devices[index];
              return ListTile(
                title: Text(device.deviceName),
                subtitle: Text(device.ipAddress),
                trailing: Text(device.connectionStatus.toString()),
                onTap: () => deviceState.selectDevice(device),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _deviceState.startDiscovery(),
        child: const Icon(Icons.search),
      ),
    );
  }

  @override
  void dispose() {
    _deviceState.removeListener(_handleStateChange);
    super.dispose();
  }
} 