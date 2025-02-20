import 'package:flutter/material.dart';
import '../../application/di/service_locator.dart';
import '../../application/services/text_transfer_service.dart';
import '../../application/services/network_service.dart';

class TextTransferWidget extends StatefulWidget {
  const TextTransferWidget({super.key});

  @override
  State<TextTransferWidget> createState() => _TextTransferWidgetState();
}

class _TextTransferWidgetState extends State<TextTransferWidget> {
  final _textTransferService = getIt<TextTransferService>();
  final _networkService = getIt<NetworkService>();
  final _textController = TextEditingController();
  final List<TextMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    _setupMessageListeners();
    _loadMessages();
  }

  void _setupMessageListeners() {
    _textTransferService.incomingMessages.listen((message) {
      setState(() {
        _messages.insert(0, message);
      });
    });

    _textTransferService.outgoingMessages.listen((message) {
      setState(() {
        _messages.insert(0, message);
      });
    });
  }

  void _loadMessages() {
    setState(() {
      _messages.addAll(_textTransferService.getMessages());
    });
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    try {
      await _textTransferService.sendText(text);
      _textController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send message: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ConnectionStatus>(
      stream: _networkService.connectionStatus,
      builder: (context, snapshot) {
        final isConnected = snapshot.data == ConnectionStatus.connected;

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Title Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '文本传输',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.history),
                    onPressed: () {
                      // TODO: Show history
                    },
                    color: Colors.grey,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Message List
              Expanded(
                child: ListView.builder(
                  reverse: true,
                  padding: EdgeInsets.zero,
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    return _MessageBubble(message: message);
                  },
                ),
              ),

              // Text Input Area
              Container(
                margin: const EdgeInsets.only(top: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF3D3D3D), // dark-300
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        maxLines: 3,
                        minLines: 1,
                        enabled: isConnected,
                        decoration: const InputDecoration(
                          hintText: '输入要传输的文本内容...',
                          contentPadding: EdgeInsets.all(12),
                          border: InputBorder.none,
                        ),
                        onSubmitted: isConnected ? (_) => _sendMessage() : null,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ElevatedButton(
                        onPressed: isConnected ? _sendMessage : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1), // primary
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                        child: const Text('发送'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}

class _MessageBubble extends StatelessWidget {
  final TextMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF3D3D3D), // dark-300
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                message.isOutgoing ? '发送至：王总的工作站' : '接收自：刘经理的手机',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              Text(
                _formatTimestamp(message.timestamp),
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            message.content,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }
} 