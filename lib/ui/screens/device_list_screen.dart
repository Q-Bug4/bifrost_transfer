import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../application/models/device_info.dart';
import '../../application/states/device_state.dart';
import '../widgets/device_card.dart';
import '../widgets/add_device_dialog.dart';

class DeviceListScreen extends StatefulWidget {
  const DeviceListScreen({super.key});

  @override
  State<DeviceListScreen> createState() => _DeviceListScreenState();
}

class _DeviceListScreenState extends State<DeviceListScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<DeviceInfo> _filteredDevices = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DeviceState>().initialize();
    });
  }

  void _filterDevices(String query, List<DeviceInfo> devices) {
    setState(() {
      if (query.isEmpty) {
        _filteredDevices = devices;
      } else {
        _filteredDevices = devices.where((device) {
          return device.deviceName.toLowerCase().contains(query.toLowerCase()) ||
              device.ipAddress.contains(query);
        }).toList();
      }
    });
  }

  Future<void> _showAddDeviceDialog() async {
    await showDialog(
      context: context,
      builder: (context) => const AddDeviceDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DeviceState>(
      builder: (context, deviceState, child) {
        if (_filteredDevices.isEmpty) {
          _filteredDevices = deviceState.pairedDevices;
        }

        return Scaffold(
          backgroundColor: const Color(0xFF1E1E1E),
          body: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                color: const Color(0xFF2D2D2D),
                child: Column(
                  children: [
                    // 本机设备信息
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3D3D3D),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                '本机设备',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
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
                                FontAwesomeIcons.windows,
                                color: Color(0xFF6366F1),
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '我的电脑',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    '192.168.1.100',
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // 搜索框
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3D3D3D),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) =>
                            _filterDevices(value, deviceState.pairedDevices),
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: '搜索设备或IP地址',
                          hintStyle: TextStyle(color: Colors.grey),
                          border: InputBorder.none,
                          icon: Icon(Icons.search, color: Colors.grey),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: deviceState.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredDevices.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: DeviceCard(device: _filteredDevices[index]),
                          );
                        },
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _showAddDeviceDialog,
            backgroundColor: const Color(0xFF6366F1),
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              '添加设备',
              style: TextStyle(color: Colors.white),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
} 