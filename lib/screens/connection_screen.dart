import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/connection_provider.dart';
import '../services/network_service.dart';

class ConnectionScreen extends ConsumerStatefulWidget {
  const ConnectionScreen({super.key});

  @override
  ConsumerState<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends ConsumerState<ConnectionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ipController = TextEditingController();
  String? _localIp;

  @override
  void initState() {
    super.initState();
    _loadLocalIp();
  }

  Future<void> _loadLocalIp() async {
    final networkService = ref.read(networkServiceProvider);
    final ip = await networkService.getLocalIpAddress();
    if (mounted) {
      setState(() {
        _localIp = ip;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final device = ref.watch(connectionStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('连接设备'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_localIp != null)
              Card(
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
                      Text('IP地址: $_localIp'),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 24),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: '设备名称',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '请输入设备名称';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _ipController,
                    decoration: const InputDecoration(
                      labelText: 'IP地址',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '请输入IP地址';
                      }
                      // 简单的IP地址格式验证
                      final parts = value.split('.');
                      if (parts.length != 4) {
                        return '请输入有效的IP地址';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: device == null
                          ? () async {
                              if (_formKey.currentState!.validate()) {
                                await ref
                                    .read(connectionStateProvider.notifier)
                                    .connect(
                                      _nameController.text,
                                      _ipController.text,
                                    );
                              }
                            }
                          : null,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          device == null ? '连接' : '已连接',
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                  ),
                  if (device != null) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          ref.read(connectionStateProvider.notifier).disconnect();
                        },
                        child: const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            '断开连接',
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ipController.dispose();
    super.dispose();
  }
}
