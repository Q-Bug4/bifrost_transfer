import 'package:flutter/material.dart';
import '../../common/theme.dart';
import '../widgets/device_list_item.dart';
import '../widgets/file_transfer_item.dart';
import 'package:dotted_border/dotted_border.dart';
import '../widgets/current_device_info.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Left Panel - Device List
          Container(
            width: 320,
            color: AppColors.dark200,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Logo
                const Text(
                  'Bifrost',
                  style: TextStyle(
                    fontSize: 24,
                    fontFamily: 'Pacifico',
                  ),
                ),
                const SizedBox(height: 24),
                
                // Current Device Info
                const CurrentDeviceInfo(),
                const SizedBox(height: 16),
                
                // Search Bar
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search devices or IP',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: AppColors.dark300,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Device List
                Expanded(
                  child: ListView(
                    children: const [
                      DeviceListItem(
                        name: "Windows Workstation",
                        ipAddress: "192.168.1.100",
                        deviceIcon: Icons.computer,
                        isConnected: true,
                      ),
                      SizedBox(height: 8),
                      DeviceListItem(
                        name: "Android Phone",
                        ipAddress: "192.168.1.101",
                        deviceIcon: Icons.phone_android,
                      ),
                    ],
                  ),
                ),
                
                // Add Device Button
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size.fromHeight(40),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add),
                      SizedBox(width: 8),
                      Text('Add Device'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Middle Panel - File Transfer
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Connected Device Info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.dark200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.computer),
                        const SizedBox(width: 12),
                        const Text('Windows Workstation'),
                        const SizedBox(width: 12),
                        Text('Connected', style: Theme.of(context).textTheme.bodySmall),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.settings),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Drag Drop Zone
                  Expanded(
                    child: DragTarget<String>(
                      onWillAccept: (data) => true,
                      onAccept: (data) {},
                      builder: (context, candidateData, rejectedData) {
                        return DottedBorder(
                          color: AppColors.dark300,
                          strokeWidth: 2,
                          borderType: BorderType.RRect,
                          radius: const Radius.circular(8),
                          padding: EdgeInsets.zero,
                          child: Container(
                            width: double.infinity,
                            height: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.cloud_upload, size: 48),
                                  SizedBox(height: 16),
                                  Text('Drag and drop files here, or click to select'),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Transfer List
                  const FileTransferItem(
                    fileName: "document.pdf",
                    fileSize: "15.2 MB",
                    fileIcon: Icons.picture_as_pdf,
                    progress: 0.75,
                    speed: "12.8 MB/s",
                  ),
                ],
              ),
            ),
          ),

          // Right Panel - Text Transfer
          Container(
            width: 380,
            color: AppColors.dark200,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Text Transfer'),
                    Icon(Icons.history),
                  ],
                ),
                const SizedBox(height: 16),
                
                Expanded(
                  child: ListView(
                    children: [
                      _buildTextMessage(
                        "Meeting link: https://example.com",
                        "10:30",
                        "To: Windows Workstation",
                      ),
                      const SizedBox(height: 8),
                      _buildTextMessage(
                        "Please check the latest sales report.",
                        "10:25",
                        "From: Android Phone",
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                TextField(
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Type text to transfer...',
                    filled: true,
                    fillColor: AppColors.dark300,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ElevatedButton(
                        onPressed: () {},
                        child: const Text('Send'),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextMessage(String message, String time, String meta) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.dark300,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(meta, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              Text(time, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          Text(message),
        ],
      ),
    );
  }
} 