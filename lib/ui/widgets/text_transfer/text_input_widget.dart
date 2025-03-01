import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../application/states/text_transfer_state_notifier.dart';

/// 文本输入组件
class TextInputWidget extends StatelessWidget {
  /// 构造函数
  const TextInputWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textTransferState = Provider.of<TextTransferStateNotifier>(context);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 文本输入区域
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: theme.dividerColor),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 文本输入框
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  maxLines: 10,
                  minLines: 5,
                  decoration: const InputDecoration(
                    hintText: '请输入要发送的文本...',
                    border: InputBorder.none,
                  ),
                  onChanged: (value) {
                    textTransferState.currentText = value;
                  },
                  controller: TextEditingController(
                      text: textTransferState.currentText),
                ),
              ),

              // 文本信息和发送按钮
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  border: Border(
                    top: BorderSide(color: theme.dividerColor),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 文本信息
                    Text(
                      '${textTransferState.currentTextSize} 字节 | ${textTransferState.currentTextLineCount} 行',
                      style: theme.textTheme.bodySmall,
                    ),

                    // 发送按钮
                    ElevatedButton(
                      onPressed: textTransferState.currentText.isEmpty ||
                              textTransferState.isTextSizeExceeded
                          ? null
                          : () async {
                              try {
                                await textTransferState.sendText();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('文本发送成功')),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('文本发送失败: $e')),
                                );
                              }
                            },
                      child: const Text('发送'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // 错误提示
        if (textTransferState.isTextSizeExceeded)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              '文本超过32KB限制，请减少文本内容',
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
      ],
    );
  }
}
