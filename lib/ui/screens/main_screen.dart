import 'package:flutter/material.dart';
import '../widgets/device_list.dart';
import '../widgets/file_transfer.dart';
import '../widgets/text_transfer.dart';

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
            color: const Color(0xFF2D2D2D), // dark-200
            child: const DeviceList(),
          ),
          
          // Middle Panel - File Transfer
          Expanded(
            child: Container(
              color: const Color(0xFF1E1E1E), // dark-100
              child: const FileTransferWidget(),
            ),
          ),
          
          // Right Panel - Text Transfer
          Container(
            width: 380,
            color: const Color(0xFF2D2D2D), // dark-200
            child: const TextTransferWidget(),
          ),
        ],
      ),
    );
  }
} 