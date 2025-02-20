import 'package:flutter/material.dart';
import '../../application/di/service_locator.dart';
import '../../application/services/network_service.dart';
import '../../application/services/device_info_service.dart';
import '../../domain/models/device.dart';

class DeviceList extends StatefulWidget {
  const DeviceList({super.key});

  @override
  State<DeviceList> createState() => _DeviceListState();
}

class _DeviceListState extends State<DeviceList> {
  final _networkService = getIt<NetworkService>();
  final _deviceInfoService = getIt<DeviceInfoService>();
  final _searchController = TextEditingController();
  String? _currentDeviceAddress;
  List<Device> _devices = [];
  String? _currentDeviceName;
  
  @override
  void initState() {
    super.initState();
    _startListening();
    _getCurrentDeviceInfo();
    _setupDeviceListener();
  }

  void _setupDeviceListener() {
    _networkService.discoveredDevices.listen((devices) {
      setState(() {
        _devices = devices;
      });
    });
  }

  Future<void> _getCurrentDeviceInfo() async {
    try {
      final name = await _deviceInfoService.getDeviceName();
      final address = await _networkService.getCurrentDeviceAddress();
      setState(() {
        _currentDeviceName = name;
        _currentDeviceAddress = address;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to get device info: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _startListening() async {
    try {
      await _networkService.startListening();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start listening: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _connectToDevice(String address) async {
    try {
      final success = await _networkService.connectToDevice(address);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connected successfully')),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to connect'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connection error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Logo
          const Row(
            children: [
              Text(
                'Bifrost',
                style: TextStyle(
                  fontSize: 24,
                  fontFamily: 'Pacifico',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Current Device Info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF3D3D3D), // dark-300
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '本机设备',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.computer,
                      color: Color(0xFF6366F1), // primary
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _currentDeviceName ?? '未知设备',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (_currentDeviceAddress != null)
                            Text(
                              _currentDeviceAddress!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Search Bar
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF3D3D3D), // dark-300
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: '搜索设备或IP地址',
                prefixIcon: Icon(Icons.search, color: Colors.grey),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Device List
          Expanded(
            child: StreamBuilder<ConnectionStatus>(
              stream: _networkService.connectionStatus,
              builder: (context, snapshot) {
                final filteredDevices = _devices.where((device) {
                  final searchTerm = _searchController.text.toLowerCase();
                  return device.name.toLowerCase().contains(searchTerm) ||
                      device.address.toLowerCase().contains(searchTerm);
                }).toList();

                if (filteredDevices.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.devices,
                          size: 48,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchController.text.isEmpty
                              ? '未发现设备'
                              : '未找到匹配的设备',
                          style: const TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: filteredDevices.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final device = filteredDevices[index];
                    return _DeviceListItem(
                      name: device.name,
                      address: device.address,
                      icon: _getDeviceIcon(device.type),
                      isConnected: device.isConnected,
                      onTap: () => _connectToDevice(device.address),
                    );
                  },
                );
              },
            ),
          ),
          
          // Add Device Button
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => _AddDeviceDialog(
                  onDeviceAdded: (address) {
                    _connectToDevice(address);
                  },
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1), // primary
              minimumSize: const Size.fromHeight(40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add),
                SizedBox(width: 8),
                Text('添加设备'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  IconData _getDeviceIcon(DeviceType type) {
    switch (type) {
      case DeviceType.computer:
        return Icons.computer;
      case DeviceType.mobile:
        return Icons.phone_android;
      case DeviceType.tablet:
        return Icons.tablet_android;
      case DeviceType.server:
        return Icons.dns;
      default:
        return Icons.devices_other;
    }
  }
}

class _DeviceListItem extends StatelessWidget {
  final String name;
  final String address;
  final IconData icon;
  final bool isConnected;
  final VoidCallback onTap;

  const _DeviceListItem({
    required this.name,
    required this.address,
    required this.icon,
    required this.isConnected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF3D3D3D), // dark-300
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Icon(
                icon,
                color: const Color(0xFF6366F1), // primary
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      address,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isConnected ? Colors.green : Colors.grey,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddDeviceDialog extends StatefulWidget {
  final Function(String) onDeviceAdded;

  const _AddDeviceDialog({required this.onDeviceAdded});

  @override
  State<_AddDeviceDialog> createState() => _AddDeviceDialogState();
}

class _AddDeviceDialogState extends State<_AddDeviceDialog> {
  final _ipController = TextEditingController();
  bool _isValidIP = false;

  @override
  void initState() {
    super.initState();
    _ipController.addListener(_validateIP);
  }

  void _validateIP() {
    final ip = _ipController.text;
    final ipRegex = RegExp(
      r'^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$',
    );
    setState(() {
      _isValidIP = ipRegex.hasMatch(ip);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('添加设备'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _ipController,
            decoration: const InputDecoration(
              labelText: 'IP地址',
              hintText: '例如: 192.168.1.100',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isValidIP ? '✓ IP地址格式正确' : '请输入有效的IP地址',
            style: TextStyle(
              color: _isValidIP ? Colors.green : Colors.red,
              fontSize: 12,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _isValidIP
              ? () {
                  widget.onDeviceAdded(_ipController.text);
                  Navigator.of(context).pop();
                }
              : null,
          child: const Text('连接'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }
} 