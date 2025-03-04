import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../../application/models/connection_model.dart';
import '../../application/services/connection_service_impl.dart';
import '../../application/states/connection_state_notifier.dart';
import '../widgets/connection_form_widget.dart';
import '../widgets/connection_request_dialog.dart';
import '../widgets/connection_status_widget.dart';
import '../widgets/device_info_widget.dart';
import '../../application/services/connection_service.dart';
import '../../application/models/connection_status.dart';
import '../../application/models/device_info_model.dart';
import 'text_transfer_screen.dart';
import '../screens/file_transfer_screen.dart';

/// 主页面
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  /// 选项卡控制器
  final _tabController = PageController();

  /// 当前选项卡索引
  int _currentTabIndex = 0;

  /// 选项卡列表
  final _tabs = const [
    {'text': '文件传输', 'icon': Icons.file_copy},
    {'text': '文本传输', 'icon': Icons.text_fields},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // 延迟执行，确保界面已经构建完成
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _listenForConnectionRequests();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  /// 构建头部
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // 应用标题
              Row(
                children: [
                  Text(
                    'Bifrost',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '虹桥',
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // 设备信息
              const DeviceInfoWidget(),
              const SizedBox(width: 16),
              // 连接状态
              const ConnectionStatusWidget(),
            ],
          ),
          const SizedBox(height: 16),
          // 连接表单
          const ConnectionFormWidget(),
        ],
      ),
    );
  }

  /// 构建主体
  Widget _buildBody() {
    return Column(
      children: [
        // 测试按钮（仅在开发环境中显示）
        if (kDebugMode)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _simulateIncomingConnectionRequest,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
              ),
              child: const Text('模拟接收连接请求（测试）'),
            ),
          ),

        // 选项卡
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: _buildTabs(),
        ),

        // 选项卡内容
        Expanded(
          child: PageView(
            controller: _tabController,
            onPageChanged: (index) {
              setState(() {
                _currentTabIndex = index;
              });
            },
            children: [
              _buildFileTransferTab(),
              _buildTextTransferTab(),
            ],
          ),
        ),
      ],
    );
  }

  /// 构建选项卡
  Widget _buildTabs() {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: List.generate(_tabs.length, (index) {
          return _buildTabItem(index);
        }),
      ),
    );
  }

  /// 构建选项卡项
  Widget _buildTabItem(int index) {
    final isSelected = _currentTabIndex == index;
    final tab = _tabs[index];

    return InkWell(
      onTap: () => _onTabTapped(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              tab['icon'] as IconData,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              tab['text'] as String,
              style: TextStyle(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建文件传输选项卡
  Widget _buildFileTransferTab() {
    return const FileTransferScreen();
  }

  /// 构建文本传输选项卡
  Widget _buildTextTransferTab() {
    return const TextTransferScreen();
  }

  /// 选项卡点击事件
  void _onTabTapped(int index) {
    setState(() {
      _currentTabIndex = index;
    });

    _tabController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  /// 监听连接请求
  void _listenForConnectionRequests() {
    final connectionStateNotifier =
        Provider.of<ConnectionStateNotifier>(context, listen: false);

    print('开始监听连接请求');

    // 监听连接请求
    connectionStateNotifier.addListener(() {
      print('ConnectionStateNotifier状态变化');
      // 如果有待处理的连接请求，显示对话框
      if (connectionStateNotifier.pendingConnectionRequest != null) {
        print(
            '检测到待处理连接请求: ${connectionStateNotifier.pendingConnectionRequest}');
        // 确保对话框只显示一次
        if (!_isConnectionRequestDialogShowing) {
          print('显示连接请求对话框');
          _showConnectionRequestDialog(connectionStateNotifier);
        } else {
          print('连接请求对话框已经在显示中');
        }
      } else {
        print('没有待处理的连接请求');
      }
    });

    // 初始检查是否有待处理的连接请求
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('初始检查待处理连接请求');
      if (connectionStateNotifier.pendingConnectionRequest != null) {
        print('初始检查发现待处理连接请求');
        _showConnectionRequestDialog(connectionStateNotifier);
      } else {
        print('初始检查未发现待处理连接请求');
      }
    });
  }

  /// 是否正在显示连接请求对话框
  bool _isConnectionRequestDialogShowing = false;

  /// 显示连接请求对话框
  void _showConnectionRequestDialog(
      ConnectionStateNotifier connectionStateNotifier) {
    if (_isConnectionRequestDialogShowing) return;

    final request = connectionStateNotifier.pendingConnectionRequest!;
    _isConnectionRequestDialogShowing = true;

    showDialog(
      context: context,
      barrierDismissible: false, // 禁止点击背景关闭对话框
      builder: (context) => ConnectionRequestDialog(
        initiatorIp: request['deviceIp'],
        initiatorName: request['deviceName'],
        pairingCode: request['pairingCode'],
        onAccept: () {
          // 关闭对话框
          Navigator.of(context).pop();
          _isConnectionRequestDialogShowing = false;
          connectionStateNotifier.acceptConnectionRequest();
        },
        onReject: () {
          // 关闭对话框
          Navigator.of(context).pop();
          _isConnectionRequestDialogShowing = false;
          connectionStateNotifier.rejectConnectionRequest();
        },
      ),
    ).then((_) {
      // 对话框关闭后重置标志
      _isConnectionRequestDialogShowing = false;
    });
  }

  /// 模拟接收连接请求
  void _simulateIncomingConnectionRequest() {
    final connectionService =
        Provider.of<ConnectionService>(context, listen: false);

    final remoteDevice = DeviceInfoModel(
      deviceName: '测试设备',
      ipAddress: '192.168.1.101',
    );

    connectionService.simulateIncomingConnectionRequest(remoteDevice);
  }
}
