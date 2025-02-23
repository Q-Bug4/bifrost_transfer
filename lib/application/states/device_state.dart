import 'package:flutter/foundation.dart';
import '../models/device_info.dart';
import '../services/device_pairing_service.dart';
import '../models/network_message.dart';
import 'package:logging/logging.dart';
import 'package:flutter/material.dart';
import '../../ui/widgets/add_device_dialog.dart';

class DeviceState extends ChangeNotifier {
  final DevicePairingService _pairingService;
  final Logger _logger = Logger('DeviceState');
  List<DeviceInfo> _devices = [];
  DeviceInfo? _currentDevice;
  String? _pairingCode;
  String? _error;
  bool _isLoading = false;
  bool _isInitiator = false;

  DeviceState(this._pairingService);

  List<DeviceInfo> get devices => _devices;
  DeviceInfo? get currentDevice => _currentDevice;
  String? get pairingCode => _pairingCode;
  String? get error => _error;
  bool get isLoading => _isLoading;
  bool get isInitiator => _isInitiator;

  // Getters
  List<DeviceInfo> get pairedDevices => _devices;

  // 初始化
  Future<void> initialize() async {
    _setLoading(true);
    try {
      await _pairingService.initialize();
      _setupMessageHandling();
      await loadPairedDevices();
      _logger.info('DeviceState initialized');
    } catch (e) {
      _setError('初始化失败：$e');
      _logger.severe('Failed to initialize DeviceState: $e');
    } finally {
      _setLoading(false);
    }
  }

  // 设置消息处理
  void _setupMessageHandling() {
    _logger.info('Setting up message handling');
    _pairingService.messageStream.listen(
      (message) {
        _logger.fine('Received message in DeviceState: ${message.type}');
        switch (message.type) {
          case 'show_pairing_request':
            _logger.info('Handling pairing request');
            _handlePairingRequest(message);
            break;
          case 'pairing_rejected':
            _logger.info('Handling pairing rejection');
            _handlePairingRejected(message);
            break;
          case 'pairing_completed':
            _logger.info('Handling pairing completion');
            _handlePairingCompleted(message);
            break;
          default:
            _logger.warning('Unknown message type: ${message.type}');
        }
      },
      onError: (error) {
        _logger.severe('Error in message stream: $error');
        _setError('消息处理错误：$error');
      },
    );
  }

  // 处理配对请求
  void _handlePairingRequest(NetworkMessage message) {
    _logger.info('Processing pairing request: ${message.data}');
    final deviceInfo = DeviceInfo.fromJson(message.data['deviceInfo']);
    final pairingCode = message.data['pairingCode'] as String;
    _currentDevice = deviceInfo;
    _pairingCode = pairingCode;
    _isInitiator = false;
    _logger.info('Updated state with device and pairing code');
    notifyListeners();

    // 通知UI层显示配对对话框
    _showPairingDialog();
  }

  // 显示配对对话框
  void _showPairingDialog() {
    if (_currentDevice == null || _pairingCode == null) return;

    // 使用全局key获取context
    final context = _navigatorKey.currentContext;
    if (context == null) {
      _logger.warning('No context available to show pairing dialog');
      return;
    }

    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PairingCodeDialog(
        pairingCode: _pairingCode!,
        isInitiator: _isInitiator,
      ),
    ).then((confirmed) async {
      if (confirmed == true) {
        await confirmPairing(_currentDevice!);
      } else {
        await rejectPairing(_currentDevice!);
      }
    });
  }

  // 添加全局key用于获取context
  static final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  static GlobalKey<NavigatorState> get navigatorKey => _navigatorKey;

  // 显示提示消息
  void _showSnackBar(String message, {bool isError = false}) {
    final context = _navigatorKey.currentContext;
    if (context == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : const Color(0xFF6366F1),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  // 处理配对完成
  void _handlePairingCompleted(NetworkMessage message) async {
    try {
      if (_currentDevice != null) {
        // 添加到已配对设备列表
        await addPairedDevice(_currentDevice!);
        _showSnackBar('设备配对成功：${_currentDevice!.deviceName}');

        // 关闭所有对话框
        final context = _navigatorKey.currentContext;
        if (context != null) {
          // 关闭所有对话框直到回到设备列表页面
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      }
      _currentDevice = null;
      _pairingCode = null;
      notifyListeners();
    } catch (e) {
      _logger.severe('Error handling pairing completion: $e');
      _setError('处理配对完成失败: $e');
      _showSnackBar('配对失败：$e', isError: true);
    }
  }

  // 处理配对被拒绝
  void _handlePairingRejected(NetworkMessage message) {
    try {
      final reason = message.data['message'] as String? ?? '对方拒绝了配对请求';
      _setError(reason);
      _showSnackBar(reason, isError: true);

      // 关闭所有对话框
      final context = _navigatorKey.currentContext;
      if (context != null) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }

      _currentDevice = null;
      _pairingCode = null;
      notifyListeners();
    } catch (e) {
      _logger.severe('Error handling pairing rejection: $e');
      _setError('处理配对拒绝失败: $e');
    }
  }

  // 加载已配对设备
  Future<void> loadPairedDevices() async {
    _setLoading(true);
    try {
      _devices = await _pairingService.getPairedDevices();
      notifyListeners();
    } catch (e) {
      _setError('加载设备列表失败：$e');
    } finally {
      _setLoading(false);
    }
  }

  // 开始设备发现
  Future<void> startDiscovery() async {
    try {
      _error = null;
      _isInitiator = false;
      notifyListeners();
      // 这里添加设备发现的逻辑
    } catch (e) {
      _setError('设备发现失败: $e');
    }
  }

  // 选择设备
  Future<void> selectDevice(DeviceInfo device, {String? pairingCode}) async {
    try {
      _error = null;
      _currentDevice = device;
      _isInitiator = true;
      notifyListeners();
      await _pairingService.startPairing(device, pairingCode: pairingCode);
    } catch (e) {
      _setError('设备连接失败: $e');
    }
  }

  // 确认配对
  Future<void> confirmPairing(DeviceInfo device) async {
    try {
      _error = null;
      await _pairingService.confirmPairing(device, true);
      await addPairedDevice(device);
      _currentDevice = null;
      _pairingCode = null;
      notifyListeners();
      _showSnackBar('设备配对成功：${device.deviceName}');
    } catch (e) {
      _setError('配对确认失败: $e');
      _showSnackBar('配对确认失败：$e', isError: true);
    }
  }

  // 拒绝配对
  Future<void> rejectPairing(DeviceInfo device) async {
    try {
      _error = null;
      await _pairingService.confirmPairing(device, false);
      _currentDevice = null;
      _pairingCode = null;
      notifyListeners();
      _showSnackBar('已拒绝与 ${device.deviceName} 配对');
    } catch (e) {
      _setError('配对拒绝失败: $e');
      _showSnackBar('配对拒绝失败：$e', isError: true);
    }
  }

  // 生成配对码
  String generatePairingCode() {
    final code = _pairingService.generatePairingCode();
    _pairingCode = code;
    notifyListeners();
    return code;
  }

  // 验证配对码
  Future<bool> verifyPairingCode(String inputCode) async {
    if (_pairingCode == null) return false;
    return await _pairingService.verifyPairingCode(inputCode, _pairingCode!);
  }

  // 添加配对设备
  Future<void> addPairedDevice(DeviceInfo device) async {
    _setLoading(true);
    _clearError();
    try {
      await _pairingService.savePairedDevice(device);
      await loadPairedDevices();
    } catch (e) {
      _setError('添加设备失败：$e');
    } finally {
      _setLoading(false);
    }
  }

  // 移除配对设备
  Future<void> removePairedDevice(String deviceId) async {
    _setLoading(true);
    _clearError();
    try {
      await _pairingService.removePairedDevice(deviceId);
      await loadPairedDevices();
    } catch (e) {
      _setError('移除设备失败：$e');
    } finally {
      _setLoading(false);
    }
  }

  // 设置当前设备
  void setCurrentDevice(DeviceInfo? device) {
    _currentDevice = device;
    notifyListeners();
  }

  // 验证IP地址
  Future<bool> validateIpAddress(String ipAddress) async {
    try {
      return await _pairingService.isValidIpAddress(ipAddress);
    } catch (e) {
      _setError('IP地址验证失败：$e');
      return false;
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String message) {
    _error = message;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _pairingService.dispose();
    super.dispose();
  }
} 