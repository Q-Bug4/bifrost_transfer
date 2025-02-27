import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../application/models/connection_model.dart';
import '../../application/services/connection_service_impl.dart';
import '../../application/states/connection_state_notifier.dart';
import '../widgets/connection_form_widget.dart';
import '../widgets/connection_request_dialog.dart';
import '../widgets/connection_status_widget.dart';
import '../widgets/device_info_widget.dart';

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
          const SizedBox(height: 16),
          // 选项卡
          _buildTabs(),
        ],
      ),
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

  /// 构建主体
  Widget _buildBody() {
    return PageView(
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
    );
  }

  /// 构建文件传输选项卡
  Widget _buildFileTransferTab() {
    return Consumer<ConnectionStateNotifier>(
      builder: (context, connectionStateNotifier, child) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.file_copy,
                size: 64,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              const Text(
                '文件传输功能将在后续版本中实现',
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 32),
              // 测试按钮，用于模拟接收连接请求
              if (connectionStateNotifier.connectionState.status == ConnectionStatus.disconnected)
                ElevatedButton(
                  onPressed: _simulateIncomingConnectionRequest,
                  child: const Text('模拟接收连接请求'),
                ),
            ],
          ),
        );
      },
    );
  }

  /// 构建文本传输选项卡
  Widget _buildTextTransferTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.text_fields,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            '文本传输功能将在后续版本中实现',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
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
    final connectionStateNotifier = Provider.of<ConnectionStateNotifier>(context, listen: false);
    
    // 监听连接请求
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (connectionStateNotifier.pendingConnectionRequest != null) {
        _showConnectionRequestDialog(connectionStateNotifier);
      }
    });
  }

  /// 显示连接请求对话框
  void _showConnectionRequestDialog(ConnectionStateNotifier connectionStateNotifier) {
    final request = connectionStateNotifier.pendingConnectionRequest!;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ConnectionRequestDialog(
        initiatorIp: request['initiatorIp'],
        initiatorName: request['initiatorName'],
        pairingCode: request['pairingCode'],
        onAccept: () {
          connectionStateNotifier.acceptConnectionRequest();
        },
        onReject: () {
          connectionStateNotifier.rejectConnectionRequest();
        },
      ),
    );
  }

  /// 模拟接收连接请求
  void _simulateIncomingConnectionRequest() {
    final connectionService = Provider.of<ConnectionServiceImpl>(context, listen: false);
    
    connectionService.simulateIncomingConnectionRequest(
      '192.168.1.101',
      '测试设备',
      '123456',
    );
  }
} 