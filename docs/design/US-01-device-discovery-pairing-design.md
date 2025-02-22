# US-01: 设备发现与配对 - 技术设计文档

## 1. 目的与范围

### 1.1 设计目标
- 实现安全可靠的设备发现机制
- 提供用户友好的设备配对流程
- 确保配对过程的安全性
- 支持多平台兼容性

### 1.2 目标读者
- 开发团队成员
- 测试团队成员
- 项目技术负责人

## 2. 系统架构

### 2.1 整体架构
系统采用分层架构设计，各层职责如下：

  ```mermaid
  graph TD
    A[UI层] --> B[业务逻辑层]
    B --> C[网络通信层]
    B --> D[数据持久化层]
    C --> E[平台适配层]
  ```

### 2.2 核心组件
1. **设备发现服务 (DiscoveryService)**
   - 处理手动IP输入
   - 管理设备在线状态

2. **配对管理器 (PairingManager)**
   - 生成配对码
   - 验证配对请求
   - 管理配对状态

3. **连接管理器 (ConnectionManager)**
   - 建立设备连接
   - 维护连接状态
   - 处理连接异常

4. **设备存储服务 (DeviceStorageService)**
   - 保存已配对设备信息
   - 管理设备配置

## 3. 详细设计

### 3.1 数据模型

1. **设备信息模型**
  ```dart
  class Device {
    final String id;          // 设备唯一标识
    final String name;        // 设备名称
    final String ipAddress;   // IP地址
    final DeviceType type;    // 设备类型
    final DeviceStatus status;// 连接状态
    final bool isPaired;      // 是否已配对
  }
  ```

2. **配对状态模型**
  ```dart
  class PairingStatus {
    final String deviceId;    // 设备ID
    final String pairingCode; // 配对码
    final PairingState state; // 配对状态
    final DateTime timestamp; // 时间戳
  }
  ```

### 3.2 接口设计

1. **设备发现接口**
  ```dart
  abstract class IDeviceConnectionService {
    Future<Device?> findDeviceByIp(String ipAddress);
  }
  ```

2. **配对管理接口**
  ```dart
  abstract class IPairingManager {
    Future<String> generatePairingCode();
    Future<bool> verifyPairingCode(String code, String deviceId);
    Future<void> completePairing(String deviceId);
  }
  ```

### 3.3 实现细节
1. **设备连接实现**
  ```dart
  class DeviceConnectionService implements IDeviceConnectionService {
    // 通过手动输入IP地址连接设备
    // 验证IP地址格式(IPv4/IPv6)
    // 尝试建立TCP连接
    // 返回连接结果
  }
  ```

2. **配对流程实现**
  ```dart
  class PairingManager implements IPairingManager {
    final _secureRandom = Random.secure();
    
    @override
    Future<String> generatePairingCode() {
      // 生成6位随机数字配对码
      // 使用加密算法确保安全性
    }
  }
  ```

### 3.4 状态管理

使用 Provider 管理设备状态：

  ```dart
  class DeviceState extends ChangeNotifier {
    List<Device> _devices = [];
    Device? _selectedDevice;
    PairingStatus? _pairingStatus;
    
    // 状态更新方法
    void updateDevices(List<Device> devices) {
      _devices = devices;
      notifyListeners();
    }
  }
  ```

## 4. 安全设计

### 4.1 配对安全
- 使用加密算法生成配对码
- 配对码有效期限制
- 防止暴力破解机制

### 4.2 连接安全
- TLS/SSL加密通信
- 设备身份验证
- 会话管理

## 5. 错误处理

### 5.1 异常类型
  ```dart
  class DiscoveryException implements Exception {
    final String message;
    final ErrorCode code;
  }

  class PairingException implements Exception {
    final String message;
    final ErrorCode code;
  }
  ```

### 5.2 错误恢复策略
- 自动重试机制
- 优雅降级处理
- 用户友好的错误提示

## 6. 测试策略

### 6.1 单元测试
  ```dart
  void main() {
    group('PairingManager Tests', () {
      test('should generate valid pairing code', () {
        // 测试配对码生成
      });
      
      test('should verify correct pairing code', () {
        // 测试配对码验证
      });
    });
  }
  ```

### 6.2 集成测试
- 设备发现流程测试
- 配对流程端到端测试
- 网络异常场景测试

## 7. 性能考虑

### 7.1 优化措施
- 设备发现使用异步操作
- 减少网络请求频率
- 优化设备状态更新逻辑

### 7.2 资源使用
- 控制内存使用
- 优化电池消耗
- 管理网络带宽

## 8. 依赖说明

### 8.1 核心依赖
- `provider`: 状态管理
- `shared_preferences`: 配对设备持久化
- `dart:io`: 网络通信

### 8.2 测试依赖
- `flutter_test`: 单元测试框架
- `mockito`: 模拟测试
