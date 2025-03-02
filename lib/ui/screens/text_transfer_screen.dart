import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../application/services/text_transfer_service.dart';
import '../../application/services/text_transfer_service_impl.dart';
import '../../application/services/socket_communication_service.dart';
import '../../application/states/text_transfer_state_notifier.dart';
import '../../infrastructure/di/service_locator.dart';
import '../widgets/text_transfer/text_input_widget.dart';
import '../widgets/text_transfer/text_transfer_detail_widget.dart';
import '../widgets/text_transfer/text_transfer_list_widget.dart';

/// 文本传输页面
class TextTransferScreen extends StatefulWidget {
  /// 构造函数
  const TextTransferScreen({Key? key}) : super(key: key);

  @override
  State<TextTransferScreen> createState() => _TextTransferScreenState();
}

class _TextTransferScreenState extends State<TextTransferScreen> {
  /// 文本传输服务
  late final TextTransferService _textTransferService;

  /// 文本传输状态管理
  late final TextTransferStateNotifier _textTransferStateNotifier;

  @override
  void initState() {
    super.initState();

    // 初始化服务和状态管理
    _textTransferService = serviceLocator<TextTransferService>();
    _textTransferStateNotifier = TextTransferStateNotifier(
      textTransferService: _textTransferService,
    );
  }

  @override
  void dispose() {
    _textTransferStateNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _textTransferStateNotifier,
      child: const _TextTransferScreenContent(),
    );
  }
}

/// 文本传输页面内容
class _TextTransferScreenContent extends StatelessWidget {
  /// 构造函数
  const _TextTransferScreenContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textTransferState = Provider.of<TextTransferStateNotifier>(context);
    final selectedTransfer = textTransferState.selectedTextTransfer;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 文本输入区域
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: const TextInputWidget(),
            ),

            // 分隔线
            const Divider(),

            // 标题
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                '文本传输记录',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),

            // 传输列表和详情区域
            SizedBox(
              height: 300,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 传输列表
                  Expanded(
                    flex: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        border:
                            Border.all(color: Theme.of(context).dividerColor),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      margin: const EdgeInsets.fromLTRB(16.0, 0.0, 8.0, 16.0),
                      child: const TextTransferListWidget(),
                    ),
                  ),

                  // 传输详情
                  Expanded(
                    flex: 2,
                    child: Container(
                      decoration: BoxDecoration(
                        border:
                            Border.all(color: Theme.of(context).dividerColor),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      margin: const EdgeInsets.fromLTRB(8.0, 0.0, 16.0, 16.0),
                      child: const TextTransferDetailWidget(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
