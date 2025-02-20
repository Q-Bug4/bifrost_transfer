import 'dart:async';
import 'dart:convert';

import 'text_transfer_service.dart';
import 'network_service.dart';

class TextTransferServiceImpl implements TextTransferService {
  final NetworkService _networkService;
  final List<TextMessage> _messages = [];
  final _incomingController = StreamController<TextMessage>.broadcast();
  final _outgoingController = StreamController<TextMessage>.broadcast();

  TextTransferServiceImpl(this._networkService) {
    _setupDataListener();
  }

  void _setupDataListener() {
    _networkService.incomingData.listen((data) {
      try {
        final json = utf8.decode(data);
        final Map<String, dynamic> messageData = jsonDecode(json);
        
        if (messageData['type'] == 'text') {
          final message = TextMessage(
            content: messageData['content'],
            timestamp: DateTime.now(),
            isOutgoing: false,
          );
          
          _messages.add(message);
          _incomingController.add(message);
        }
      } catch (e) {
        // Ignore non-text data
      }
    });
  }

  @override
  Stream<TextMessage> get incomingMessages => _incomingController.stream;

  @override
  Stream<TextMessage> get outgoingMessages => _outgoingController.stream;

  @override
  List<TextMessage> getMessages() {
    return List.from(_messages)..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  @override
  Future<void> sendText(String text) async {
    final message = TextMessage(
      content: text,
      timestamp: DateTime.now(),
      isOutgoing: true,
    );

    final messageData = {
      'type': 'text',
      'content': text,
      'timestamp': message.timestamp.toIso8601String(),
    };

    try {
      await _networkService.sendData(utf8.encode(json.encode(messageData)));
      _messages.add(message);
      _outgoingController.add(message);
    } catch (e) {
      final errorMessage = TextMessage(
        content: text,
        timestamp: message.timestamp,
        isOutgoing: true,
        status: 'error',
      );
      _messages.add(errorMessage);
      _outgoingController.add(errorMessage);
      rethrow;
    }
  }

  void dispose() {
    _incomingController.close();
    _outgoingController.close();
  }
} 