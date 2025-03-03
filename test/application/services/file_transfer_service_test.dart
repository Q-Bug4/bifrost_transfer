import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:path/path.dart' as path;
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:bifrost_transfer/application/services/file_transfer_service.dart';
import 'package:bifrost_transfer/application/services/file_transfer_service_impl.dart';
import 'package:bifrost_transfer/application/services/socket_communication_service.dart';
import 'package:bifrost_transfer/application/models/file_transfer_model.dart';
import 'package:bifrost_transfer/application/models/socket_message_model.dart';
import 'file_transfer_service_test.mocks.dart';

@GenerateNiceMocks([MockSpec<SocketCommunicationService>()])
void main() {
  late FileTransferService fileTransferService;
  late MockSocketCommunicationService mockSocketService;
  late Directory tempDir;

  setUp(() async {
    mockSocketService = MockSocketCommunicationService();
    fileTransferService =
        FileTransferServiceImpl(socketService: mockSocketService);
    tempDir = await Directory.systemTemp.createTemp('file_transfer_test_');

    // 设置基本的mock行为
    when(mockSocketService.isConnected).thenReturn(true);
    when(mockSocketService.messageStream)
        .thenAnswer((_) => Stream<SocketMessageModel>.empty());
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  group('FileTransferService - 发送文件测试', () {
    test('成功发送单个文件', () async {
      // 准备测试文件
      final testFile = File(path.join(tempDir.path, 'test.txt'));
      await testFile.writeAsString('test content');

      // 计算文件哈希
      final fileBytes = await testFile.readAsBytes();
      final fileHash = base64.encode(sha256.convert(fileBytes).bytes);

      // 设置mock响应
      when(mockSocketService.sendMessage(any))
          .thenAnswer((_) => Future.value());

      // 执行测试
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

      // 设置mock响应
      when(mockSocketService.sendMessage(any))
          .thenAnswer((_) => Future.value());

      // 执行测试
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

  group('FileTransferService - 取消传输测试', () {
    test('成功取消文件传输', () async {
      // 准备测试文件
      final testFile = File(path.join(tempDir.path, 'test.txt'));
      await testFile.writeAsString('test content');

      // 设置mock响应
      when(mockSocketService.sendMessage(any))
          .thenAnswer((_) => Future.value());

      // 发送文件
      final transferId = await fileTransferService.sendFile(testFile.path);

      // 执行测试
      await fileTransferService.cancelFileTransfer(transferId);

      // 验证结果
      verify(mockSocketService.sendMessage(argThat(
          predicate<SocketMessageModel>((message) =>
              message.type == SocketMessageType.FILE_TRANSFER_CANCEL &&
              message.data['fileName'] == 'test.txt')))).called(1);

      // 验证传输状态
      final transfer = fileTransferService.getFileTransfer(transferId);
      expect(transfer?.status, equals(FileTransferStatus.cancelled));
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

  group('FileTransferService - 传输状态测试', () {
    test('获取活动传输列表', () async {
      // 准备测试文件
      final testFile = File(path.join(tempDir.path, 'test.txt'));
      await testFile.writeAsString('test content');

      // 设置mock响应
      when(mockSocketService.sendMessage(any))
          .thenAnswer((_) => Future.value());

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

      // 设置mock响应
      when(mockSocketService.sendMessage(any))
          .thenAnswer((_) => Future.value());

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
}
