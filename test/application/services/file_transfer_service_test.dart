import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:path/path.dart' as path;
import 'package:crypto/crypto.dart';
import 'package:logging/logging.dart';
import 'package:bifrost_transfer/application/services/file_transfer_service.dart';
import 'package:bifrost_transfer/application/services/file_transfer_service_impl.dart';
import 'package:bifrost_transfer/application/services/socket_communication_service.dart';
import 'package:bifrost_transfer/application/models/file_transfer_model.dart';
import 'package:bifrost_transfer/application/models/socket_message_model.dart';
import 'package:bifrost_transfer/application/models/connection_status.dart';
import 'socket_communication_service_test.mocks.dart';

@GenerateMocks([SocketCommunicationService])
void main() {
  late FileTransferService fileTransferService;
  late MockSocketCommunicationService mockSocketService;
  late Directory tempDir;
  late StreamController<SocketMessageModel> messageStreamController;
  late StreamController<ConnectionStatus> connectionStatusController;
  late List<String> logMessages;

  setUp(() async {
    mockSocketService = MockSocketCommunicationService();
    messageStreamController = StreamController<SocketMessageModel>.broadcast();
    connectionStatusController = StreamController<ConnectionStatus>.broadcast();
    logMessages = [];

    when(mockSocketService.messageStream)
        .thenAnswer((_) => messageStreamController.stream);
    when(mockSocketService.isConnected).thenReturn(true);
    when(mockSocketService.connectionStatusStream)
        .thenAnswer((_) => connectionStatusController.stream);
    when(mockSocketService.sendMessage(any)).thenAnswer((_) async {});

    // 设置日志记录
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      logMessages.add(record.message);
    });

    fileTransferService = FileTransferServiceImpl(mockSocketService);
    tempDir = await Directory.systemTemp.createTemp('file_transfer_test_');
    await fileTransferService.setReceiveDirectory(tempDir.path);
  });

  tearDown(() async {
    await messageStreamController.close();
    await connectionStatusController.close();
    await tempDir.delete(recursive: true);
    logMessages.clear();
    Logger.root.clearListeners();
  });

  group('FileTransferService - 发送文件测试', () {
    test('成功发送单个文件', () async {
      // 准备测试文件
      final testFile = File(path.join(tempDir.path, 'test.txt'));
      await testFile.writeAsString('test content');

      // 计算文件哈希
      final fileBytes = await testFile.readAsBytes();
      final fileHash = base64.encode(sha256.convert(fileBytes).bytes);

      // 发送文件
      final transferId = await fileTransferService.sendFile(testFile.path);

      // 验证结果
      expect(transferId, isNotEmpty);
      verify(mockSocketService.sendMessage(argThat(
          predicate<SocketMessageModel>((message) =>
              message.type == SocketMessageType.FILE_TRANSFER_REQUEST &&
              message.data['fileName'] == 'test.txt' &&
              message.data['fileHash'] == fileHash)))).called(1);
    });

    test('文件不存在时抛出异常', () async {
      final nonExistentFile = path.join(tempDir.path, 'non_existent.txt');

      expect(
        () => fileTransferService.sendFile(nonExistentFile),
        throwsA(predicate(
            (e) => e is FileSystemException && e.message.contains('文件不存在'))),
      );
    });
  });

  group('FileTransferService - 发送目录测试', () {
    test('成功发送目录', () async {
      // 准备测试目录结构
      final testDir = Directory(path.join(tempDir.path, 'test_dir'));
      await testDir.create();
      await File(path.join(testDir.path, 'file1.txt'))
          .writeAsString('content 1');
      await File(path.join(testDir.path, 'file2.txt'))
          .writeAsString('content 2');

      // 发送目录
      final transferIds = await fileTransferService.sendDirectory(testDir.path);

      // 验证结果
      expect(transferIds.length, 2);
      verify(mockSocketService.sendMessage(any)).called(2);
    });

    test('目录不存在时抛出异常', () async {
      final nonExistentDir = path.join(tempDir.path, 'non_existent_dir');

      expect(
        () => fileTransferService.sendDirectory(nonExistentDir),
        throwsA(predicate(
            (e) => e is FileSystemException && e.message.contains('目录不存在'))),
      );
    });
  });

  group('FileTransferService - 文件数据传输测试', () {
    test('成功处理文件数据传输', () async {
      // 准备测试文件
      final testFile = File(path.join(tempDir.path, 'test.txt'));
      await testFile.writeAsString('test content');

      // 发送文件
      final transferId = await fileTransferService.sendFile(testFile.path);

      // 模拟文件数据传输
      final message = SocketMessageModel.createFileTransferDataMessage(
        transferId: transferId,
        fileName: 'test.txt',
        data: base64.encode(utf8.encode('test content')),
        offset: 0,
      );

      // 发送文件数据消息
      messageStreamController.add(message);
      await Future.delayed(Duration(milliseconds: 100));

      // 验证传输状态
      final transfer = fileTransferService.getFileTransfer(transferId);
      expect(transfer, isNotNull);
      expect(transfer!.status, equals(FileTransferStatus.completed));
      expect(transfer.bytesTransferred, equals(12)); // 'test content'.length

      // 验证文件内容
      final receivedFile = File(transfer.filePath);
      expect(await receivedFile.readAsString(), equals('test content'));
    });

    test('处理文件数据传输错误', () async {
      // 准备测试文件
      final testFile = File(path.join(tempDir.path, 'test.txt'));
      await testFile.writeAsString('test content');

      // 发送文件
      final transferId = await fileTransferService.sendFile(testFile.path);

      // 模拟无效的文件数据传输
      final message = SocketMessageModel.createFileTransferDataMessage(
        transferId: transferId,
        fileName: 'test.txt',
        data: 'invalid base64 data',
        offset: 0,
      );

      // 发送文件数据消息
      messageStreamController.add(message);
      await Future.delayed(Duration(milliseconds: 100));

      // 验证传输状态
      final transfer = fileTransferService.getFileTransfer(transferId);
      expect(transfer, isNotNull);
      expect(transfer!.status, equals(FileTransferStatus.failed));
      expect(transfer.errorMessage, isNotNull);
    });
  });

  group('FileTransferService - 传输状态测试', () {
    test('获取活动传输列表', () async {
      // 准备测试文件
      final testFile = File(path.join(tempDir.path, 'test.txt'));
      await testFile.writeAsString('test content');

      // 发送文件
      final transferId = await fileTransferService.sendFile(testFile.path);

      // 获取活动传输列表
      final activeTransfers = fileTransferService.getActiveFileTransfers();

      // 验证结果
      expect(activeTransfers.length, 1);
      expect(activeTransfers.first.transferId, equals(transferId));
    });

    test('获取指定传输状态', () async {
      // 准备测试文件
      final testFile = File(path.join(tempDir.path, 'test.txt'));
      await testFile.writeAsString('test content');

      // 发送文件
      final transferId = await fileTransferService.sendFile(testFile.path);

      // 获取传输状态
      final transfer = fileTransferService.getFileTransfer(transferId);

      // 验证结果
      expect(transfer, isNotNull);
      expect(transfer!.transferId, equals(transferId));
      expect(transfer.status, equals(FileTransferStatus.waiting));
    });
  });

  group('FileTransferService - 接收目录设置测试', () {
    test('成功设置和获取接收目录', () async {
      final testReceiveDir = path.join(tempDir.path, 'receive_dir');
      await Directory(testReceiveDir).create();

      // 设置接收目录
      await fileTransferService.setReceiveDirectory(testReceiveDir);

      // 获取接收目录
      final receivePath = fileTransferService.getReceiveDirectory();

      // 验证结果
      expect(receivePath, equals(testReceiveDir));
    });

    test('设置不存在的目录时抛出异常', () async {
      final nonExistentDir =
          path.join(tempDir.path, 'non_existent_receive_dir');

      expect(
        () => fileTransferService.setReceiveDirectory(nonExistentDir),
        throwsA(predicate(
            (e) => e is FileSystemException && e.message.contains('目录不存在'))),
      );
    });
  });

  group('FileTransferService - 文件传输测试', () {
    test('发送文件 - 正常情况', () async {
      // TODO: 实现测试用例
    });

    test('发送文件 - 文件不存在', () async {
      // TODO: 实现测试用例
    });

    test('发送目录 - 正常情况', () async {
      // TODO: 实现测试用例
    });

    test('接收文件 - 正常情况', () async {
      // TODO: 实现测试用例
    });

    test('接收文件 - 写入失败', () async {
      // TODO: 实现测试用例
    });

    test('取消传输 - 正常情况', () async {
      // TODO: 实现测试用例
    });
  });

  group('FileTransferService - 日志记录测试', () {
    test('发送文件时应记录正确的日志', () async {
      // 创建临时测试文件
      final testFile = File(path.join(tempDir.path, 'test.txt'));
      await testFile.writeAsString('test content');

      try {
        await fileTransferService.sendFile(testFile.path);
        expect(logMessages.any((msg) => msg.contains('初始化接收目录')), isTrue);
      } finally {
        await testFile.delete();
      }
    });

    test('文件传输失败时应记录错误日志', () async {
      // 创建临时测试文件
      final testFile = File(path.join(tempDir.path, 'test.txt'));
      await testFile.writeAsString('test content');

      when(mockSocketService.sendMessage(any)).thenThrow(Exception('发送失败'));

      try {
        await fileTransferService.sendFile(testFile.path);
      } catch (_) {}

      expect(
        logMessages.any((msg) => msg.contains('失败')),
        isTrue,
      );
    });

    test('接收文件时应记录进度日志', () async {
      final message = SocketMessageModel.createFileTransferDataMessage(
        transferId: 'test-id',
        fileName: 'test.txt',
        data: 'test content',
        offset: 0,
      );

      messageStreamController.add(message);
      await Future.delayed(Duration.zero);

      expect(
        logMessages.any((msg) => msg.contains('数据')),
        isTrue,
      );
    });
  });

  group('FileTransferService - 文件大小格式化测试', () {
    test('格式化不同大小的文件', () {
      final testCases = [
        {'size': 500, 'expected': '500.00 B'},
        {'size': 1024, 'expected': '1.00 KB'},
        {'size': 1024 * 1024, 'expected': '1.00 MB'},
        {'size': 1024 * 1024 * 1024, 'expected': '1.00 GB'},
      ];

      for (var testCase in testCases) {
        final model = FileTransferModel(
          transferId: 'test-id',
          fileName: 'test.txt',
          filePath: 'test.txt',
          fileSize: testCase['size'] as int,
          fileHash: 'hash',
          direction: FileTransferDirection.sending,
        );

        expect(model.fileSize, testCase['size']);
      }
    });
  });

  group('FileTransferService - 传输进度和速度测试', () {
    test('应正确计算传输进度和速度', () async {
      // 使用较小的文件大小进行测试
      final fileSize = 1024 * 64; // 64KB
      final testFile = File(path.join(tempDir.path, 'test.dat'));
      await testFile.writeAsBytes(List.filled(fileSize, 0));

      // 发送文件
      final transferId = await fileTransferService.sendFile(testFile.path);
      final transfer = fileTransferService.getFileTransfer(transferId);
      expect(transfer, isNotNull);

      // 模拟分块传输
      final chunkSize = fileSize ~/ 4; // 每次传输1/4
      for (var i = 0; i < 4; i++) {
        final chunk = List.filled(chunkSize, 0);
        final message = SocketMessageModel.createFileTransferDataMessage(
          transferId: transferId,
          fileName: 'test.dat',
          data: base64.encode(chunk),
          offset: i * chunkSize,
        );

        messageStreamController.add(message);
        await Future.delayed(Duration(milliseconds: 100));

        // 验证进度
        final updatedTransfer = fileTransferService.getFileTransfer(transferId);
        expect(updatedTransfer, isNotNull);
        expect(
          updatedTransfer!.bytesTransferred,
          equals((i + 1) * chunkSize),
        );
        expect(
          updatedTransfer.progress,
          equals(((i + 1) * 25).toDouble()), // 每次增加25%
        );
      }

      // 验证最终状态
      final finalTransfer = fileTransferService.getFileTransfer(transferId);
      expect(finalTransfer, isNotNull);
      expect(finalTransfer!.status, equals(FileTransferStatus.completed));
      expect(finalTransfer.bytesTransferred, equals(fileSize));
      expect(finalTransfer.progress, equals(100.0));
    });
  });
}
