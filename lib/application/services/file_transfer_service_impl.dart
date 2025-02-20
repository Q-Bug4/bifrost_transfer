import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

import 'file_transfer_service.dart';
import 'network_service.dart';

class FileTransferServiceImpl implements FileTransferService {
  static const chunkSize = 1024 * 64; // 64KB chunks
  
  final NetworkService _networkService;
  final Map<String, FileTransfer> _transfers = {};
  final _incomingTransfersController = StreamController<FileTransfer>.broadcast();
  
  FileTransferServiceImpl(this._networkService) {
    _setupDataListener();
  }

  void _setupDataListener() {
    _networkService.incomingData.listen((data) {
      // Handle incoming file data
      _handleIncomingData(data);
    });
  }

  @override
  Stream<FileTransfer> get incomingTransfers => _incomingTransfersController.stream;

  @override
  Future<void> cancelTransfer(String fileName) async {
    final transfer = _transfers[fileName];
    if (transfer != null) {
      transfer.status = 'cancelled';
      _transfers.remove(fileName);
    }
  }

  @override
  double getCurrentSpeed() {
    // Calculate average speed of ongoing transfers
    final ongoingTransfers = _transfers.values.where((t) => t.status == 'transferring');
    if (ongoingTransfers.isEmpty) return 0;

    double totalSpeed = 0;
    for (var transfer in ongoingTransfers) {
      final duration = DateTime.now().difference(transfer.startTime).inSeconds;
      if (duration > 0) {
        totalSpeed += (transfer.fileSize * transfer.progress) / duration;
      }
    }
    return totalSpeed / ongoingTransfers.length;
  }

  @override
  List<FileTransfer> getTransfers() {
    return _transfers.values.toList();
  }

  @override
  Stream<FileTransfer> receiveFile() {
    // This will be triggered by incoming file data
    final controller = StreamController<FileTransfer>();
    return controller.stream;
  }

  @override
  Stream<FileTransfer> sendFile(String filePath) async* {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('File not found: $filePath');
    }

    final fileName = file.path.split(Platform.pathSeparator).last;
    final fileSize = await file.length();
    
    final transfer = FileTransfer(
      fileName: fileName,
      fileSize: fileSize,
      startTime: DateTime.now(),
      status: 'transferring',
    );
    _transfers[fileName] = transfer;

    try {
      // Send file metadata
      final metadata = {
        'type': 'file_start',
        'fileName': fileName,
        'fileSize': fileSize,
      };
      await _networkService.sendData(utf8.encode(json.encode(metadata)));

      // Send file in chunks
      final stream = file.openRead();
      int bytesTransferred = 0;

      await for (final chunk in stream.cast<List<int>>()) {
        for (var i = 0; i < chunk.length; i += chunkSize) {
          final end = (i + chunkSize < chunk.length) ? i + chunkSize : chunk.length;
          final chunkData = chunk.sublist(i, end);
          
          await _networkService.sendData(chunkData);
          
          bytesTransferred += chunkData.length;
          transfer.progress = bytesTransferred / fileSize;
          yield transfer;
        }
      }

      // Send end marker
      final endMarker = {
        'type': 'file_end',
        'fileName': fileName,
      };
      await _networkService.sendData(utf8.encode(json.encode(endMarker)));

      transfer.status = 'completed';
      yield transfer;
    } catch (e) {
      transfer.status = 'error';
      yield transfer;
      rethrow;
    }
  }

  void _handleIncomingData(List<int> data) {
    try {
      // Try to parse as JSON metadata
      final metadata = json.decode(utf8.decode(data));
      if (metadata['type'] == 'file_start') {
        final transfer = FileTransfer(
          fileName: metadata['fileName'],
          fileSize: metadata['fileSize'],
          startTime: DateTime.now(),
          status: 'receiving',
        );
        _transfers[transfer.fileName] = transfer;
        _incomingTransfersController.add(transfer);
      }
    } catch (_) {
      // Not metadata, treat as file chunk
      // Implementation would need to handle reassembly of chunks
      // and write to file system
    }
  }

  void dispose() {
    _incomingTransfersController.close();
  }

  @override
  Future<void> pauseTransfer(String fileName) async {
    final transfer = _transfers[fileName];
    if (transfer != null && transfer.status == 'transferring') {
      transfer.status = 'paused';
    }
  }

  @override
  Future<void> resumeTransfer(String fileName) async {
    final transfer = _transfers[fileName];
    if (transfer != null && transfer.status == 'paused') {
      transfer.status = 'transferring';
    }
  }

  String? _savePath;

  @override
  String? getSavePath() => _savePath;

  @override
  Future<void> setSavePath(String path) async {
    _savePath = path;
  }
} 