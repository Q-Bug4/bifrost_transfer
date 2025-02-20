import 'dart:async';
import 'dart:typed_data';

/// Represents a file transfer operation
class FileTransfer {
  final String fileName;
  final int fileSize;
  final DateTime startTime;
  double progress;
  String status;

  FileTransfer({
    required this.fileName,
    required this.fileSize,
    required this.startTime,
    this.progress = 0.0,
    this.status = 'pending',
  });
}

/// Interface defining the core file transfer functionality
abstract class FileTransferService {
  /// Start sending a file to the connected device
  /// Returns a stream of the transfer progress
  Stream<FileTransfer> sendFile(String filePath);

  /// Start receiving a file from the connected device
  /// Returns a stream of the transfer progress
  Stream<FileTransfer> receiveFile();

  /// Cancel an ongoing file transfer
  Future<void> cancelTransfer(String fileName);

  /// Pause an ongoing file transfer
  Future<void> pauseTransfer(String fileName);

  /// Resume a paused file transfer
  Future<void> resumeTransfer(String fileName);

  /// Get a list of all ongoing and completed transfers
  List<FileTransfer> getTransfers();

  /// Get the current transfer speed in bytes per second
  double getCurrentSpeed();

  /// Get the default save path for received files
  String? getSavePath();

  /// Set the default save path for received files
  Future<void> setSavePath(String path);

  /// Event stream for new incoming file transfers
  Stream<FileTransfer> get incomingTransfers;
} 