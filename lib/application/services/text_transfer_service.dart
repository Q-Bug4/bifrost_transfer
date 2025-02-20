import 'dart:async';

/// Represents a text message
class TextMessage {
  final String content;
  final DateTime timestamp;
  final bool isOutgoing;
  final String status;

  TextMessage({
    required this.content,
    required this.timestamp,
    required this.isOutgoing,
    this.status = 'sent',
  });
}

/// Interface defining the core text transfer functionality
abstract class TextTransferService {
  /// Send a text message to the connected device
  Future<void> sendText(String text);

  /// Get a stream of incoming text messages
  Stream<TextMessage> get incomingMessages;

  /// Get a stream of outgoing text messages
  Stream<TextMessage> get outgoingMessages;

  /// Get all messages in chronological order
  List<TextMessage> getMessages();
} 