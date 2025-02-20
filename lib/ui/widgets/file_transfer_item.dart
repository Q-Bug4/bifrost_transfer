import 'package:flutter/material.dart';
import '../../common/theme.dart';

class FileTransferItem extends StatelessWidget {
  final String fileName;
  final String fileSize;
  final IconData fileIcon;
  final double progress;
  final String speed;
  final VoidCallback? onPause;
  final VoidCallback? onCancel;

  const FileTransferItem({
    super.key,
    required this.fileName,
    required this.fileSize,
    required this.fileIcon,
    this.progress = 0,
    this.speed = '',
    this.onPause,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF3D3D3D), // dark-300
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                fileIcon,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(fileName, style: Theme.of(context).textTheme.bodyMedium),
                    Text(fileSize, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              if (speed.isNotEmpty) Text(speed, style: Theme.of(context).textTheme.bodySmall),
              if (onPause != null) IconButton(
                icon: const Icon(Icons.pause),
                onPressed: onPause,
              ),
              if (onCancel != null) IconButton(
                icon: const Icon(Icons.close),
                onPressed: onCancel,
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.dark100,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ],
      ),
    );
  }
} 