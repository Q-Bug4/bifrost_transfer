### 1. 目的

*   **目标读者**：开发人员、测试人员
*   **范围**：设备配对手动输入IP连接功能的设计与实现
*   **重要性**：作为文件传输功能的基础，确保设备连接的便捷性与安全性，是项目成功的关键步骤。

### 2. 文档结构
*   **概述**：
    *   **项目背景**：用户需要在局域网内便捷且安全地连接到其他设备进行文件传输。US-01 旨在解决设备手动IP连接与安全配对的问题，为后续的文件传输功能打下基础。
    *   **项目目标**：实现设备的手动IP地址连接、配对码生成与验证、配对状态反馈、已配对设备存储等功能，确保连接过程既方便又安全。
    *   **技术选型**：
        *   Flutter 3.x
        *   状态管理：Provider
        *   网络通信：`dart:io` (Socket)
        *   数据持久化：`shared_preferences` (存储已配对设备)

*   **详细设计**：
    *   **网络通信设计**：
        *   **端口分配**：
            - 控制端口：30080（用于设备发现和配对）
            - 数据传输端口：30081（用于后续的文件传输）
        *   **服务器角色**：
            - 每个设备都同时作为服务器和客户端
            - 启动时在控制端口（30080）启动监听服务
            - 作为接收方时在数据端口（30081）启动监听服务
        *   **消息格式**：
            ```json
            {
              "type": "string",      // 消息类型
              "deviceId": "string",  // 发送设备ID
              "data": "object"      // 消息数据
            }
            ```
        *   **消息类型**：
            1. **设备发现**：
                ```json
                {
                  "type": "discovery",
                  "deviceId": "device_id",
                  "data": {
                    "deviceName": "string",
                    "deviceType": "string",
                    "ipAddress": "string"
                  }
                }
                ```
            2. **配对请求**：
                ```json
                {
                  "type": "pairing_request",
                  "deviceId": "device_id",
                  "data": {
                    "pairingCode": "string"
                  }
                }
                ```
            3. **配对响应**：
                ```json
                {
                  "type": "pairing_response",
                  "deviceId": "device_id",
                  "data": {
                    "accepted": "boolean",
                    "message": "string"
                  }
                }
                ```
            4. **配对确认**：
                ```json
                {
                  "type": "pairing_confirmation",
                  "deviceId": "device_id",
                  "data": {
                    "confirmed": "boolean"
                  }
                }
                ```
        *   **通信流程**：
            1. **设备发现**：
                - 设备A向设备B的控制端口（30080）发送TCP连接请求
                - 连接成功后，设备A发送discovery消息
                - 设备B接收并验证discovery消息
                - 设备B返回discovery响应消息
            2. **配对过程**：
                - 设备A生成6位数字配对码
                - 设备A发送pairing_request消息（包含配对码）
                - 设备B显示配对码给用户确认
                - 用户确认后，设备B发送pairing_response消息
                - 设备A收到响应后，发送pairing_confirmation消息
                - 双方更新配对状态
            3. **连接保持**：
                - 每30秒发送心跳包
                - 超过90秒未收到心跳包则断开连接
                - 连接断开后自动重试3次

    *   **功能模块**：
        *   **模块划分**：
            1.  **设备配对模块**：
                *   **功能**：生成配对码，验证配对码，处理配对请求和确认。
                *   **职责**：处理设备间的配对逻辑，确保安全连接。
            2.  **连接管理模块**：
                *   **功能**：管理设备连接状态，处理连接建立、断开、失败等情况。
                *   **职责**：维护设备连接状态，提供连接状态反馈。
            3.  **网络服务模块**：
                *   **功能**：处理网络监听、消息收发、心跳维护等。
                *   **职责**：确保网络通信的可靠性。
        *   **模块交互**：
            *   用户手动输入IP地址。
            *   连接管理模块尝试连接目标设备。
            *   网络服务模块建立Socket连接。
            *   设备配对模块处理配对流程。
            *   网络服务模块维护连接状态。
        *   **流程图**：

            ```mermaid
            graph LR
                A[用户 A 打开设备列表页面] --> B[用户 A 输入用户 B 的 IP 地址];
                B --> C[用户 A 发起连接请求];
                C --> D{用户 B 是否可达};
                D -- 是 --> E[设备配对模块在设备 A 上生成配对码];
                D -- 否 --> F[提示用户 B 不可达];
                E --> G[设备 A 将配对码发送给设备 B];
                G --> H[设备 A 和 B 显示配对码];
                H --> I{用户 B 是否确认连接};
                I -- 是 --> J[用户 B 发送同意配对请求给用户 A];
                I -- 否 --> K[取消配对，返回设备列表];
                J --> L[设备配对模块验证配对请求];
                L --> M{配对是否成功};
                M -- 是 --> N[连接管理模块建立连接];
                M -- 否 --> O[配对失败，提示用户];
                N --> P[连接建立成功，显示连接状态];
                O --> A;
                K --> A;
                F --> A;
            ```
    *   **异常处理**：
       *   **异常处理流程**：
           1.  **IP地址输入错误**：
               *   **描述**：用户手动输入 IP 地址时，可能会输入错误的 IP 地址格式或无效的 IP 地址。
               *   **处理方案**：
                   *   **UI 校验**：前端 UI 需对 IP 地址格式进行实时校验，确保输入符合 IPv4/IPv6 格式。
                   *   **后端验证**：后端在尝试连接前，使用 `dart:io` 库中的 `InternetAddress.lookup` 或 `Socket.connect` 方法验证 IP 地址的可达性。
                   *   **错误提示**：如果 IP 地址格式错误，UI 立即给出格式错误提示。如果 IP 地址无效或不可达，连接尝试失败后，UI 给出明确的错误提示（例如"IP 地址无效或设备未响应"），引导用户重新输入或检查网络连接。
           2.  **连接超时**：
               *   **描述**：在设备配对或连接建立过程中，可能由于网络问题导致连接超时。
               *   **处理方案**：
                   *   **超时设置**：在进行网络操作（如 Socket 连接、配对码验证）时，设置合理的超时时间（例如 30 秒）。
                   *   **超时处理**：使用 `dart:async` 库的 `timeout` 功能来控制网络请求的超时。连接超时后，捕获 `TimeoutException` 异常。
                   *   **错误提示**：连接超时后，UI 应提示用户"连接超时，请检查网络连接或重试"，并提供重试操作的选项。
           3.  **配对请求取消**：
               *   **描述**：设备 A 发起配对请求后，用户可能在设备 B 上取消配对请求。
               *   **处理方案**：
                   *   **取消操作**：设备 B 提供"取消配对"按钮，允许用户取消配对请求。
                   *   **消息通知**：设备 B 取消配对后，向设备 A 发送取消配对的消息。
                   *   **UI 更新**：设备 A 收到配对取消消息后，应停止配对流程，并更新 UI 状态，例如返回设备列表页面，并提示"配对已取消"。
           4.  **已配对设备重复配对**：
               *   **描述**：用户尝试与已配对的设备再次进行配对。
               *   **处理方案**：
                   *   **状态检查**：在发起配对前，检查目标设备是否已在已配对设备列表中。
                   *   **UI 提示**：在 UI 上，已配对的设备应有明显的标识（例如"已配对"图标）。当用户选择已配对设备时，可以弹窗提示"该设备已配对，是否重新配对？"，提供"重新配对"和"取消"选项。
       *   **异常处理流程图**：

           ```mermaid
           graph LR
               A[开始配对流程] --> B{IP地址是否有效};
               B -- 是 --> C{配对码是否正确};
               B -- 否 --> BA[提示IP地址错误];
               C -- 是 --> D{连接是否超时};
               C -- 否 --> CA[提示配对码错误];
               D -- 是 --> E[配对成功];
               D -- 否 --> DA[提示连接超时];
               E --> F[完成配对];
               DA --> A[重新开始配对];
               CA --> A[重新开始配对];
               BA --> A[重新开始配对];
           ```
    *   **数据设计**：
        *   **数据模型**：
            *   **设备信息类 (DeviceInfo)**：
                *   `deviceName` (String)：设备名称
                *   `ipAddress` (String)：设备 IP 地址
                *   `deviceType` (Enum)：设备类型 (Windows, Android, Linux)
                *   `connectionStatus` (Enum)：连接状态 (Connected, Disconnected, Connecting)
                *   `isPaired` (bool)：是否已配对
            *   **配对信息类 (PairingInfo)**：
                *   `pairingCode` (String)：配对码
                *   `deviceAId` (String)：设备 A ID
                *   `deviceBId` (String)：设备 B ID
                *   `expiryTime` (DateTime)：过期时间
        *   **数据库设计**：
            *   使用 `shared_preferences` 存储已配对设备列表，键为设备 ID，值为 `DeviceInfo` 对象的 JSON 字符串。
        *   **数据流**：
            1.  用户手动输入IP地址，创建 `DeviceInfo` 对象。
            2.  UI 从状态管理器获取 `DeviceInfo` 列表并展示。
            3.  用户选择设备进行配对，触发配对流程。
            4.  配对成功后，`DeviceInfo` 对象的 `isPaired` 属性更新，并存储到 `shared_preferences`。
            5.  连接管理模块根据 `DeviceInfo` 建立网络连接，更新 `connectionStatus`。
    *   **类设计**：
        *   **类结构**：
            ```
            - DevicePairingService
                - generatePairingCode(): String // **设备 A 生成配对码**
                - verifyPairingCode(String code): Future<bool> // 验证配对码
                - pairDevices(DeviceInfo device): Future<bool> // 配对设备
                - getPairedDevices(): Future<List<DeviceInfo>> // 获取已配对设备
            - ConnectionManager
                - connectToDevice(DeviceInfo device): Future<bool> // 连接设备
                - disconnectDevice(DeviceInfo device): Future<void> // 断开连接
                - getConnectionStatus(DeviceInfo device): ConnectionStatus // 获取连接状态
            - DeviceListViewModel (Provider)
                - deviceList: List<DeviceInfo>
                - pairedDeviceList: List<DeviceInfo>
                - pairDevice(DeviceInfo device)
                - ...
            - DeviceListPage (UI)
                - DeviceListView (Widget)
                    - DeviceCard (Widget)
            ```
        *   **实现方式**：
            *   **面向接口编程**：定义 `DevicePairing`, `Connection` 等接口，方便未来替换具体实现。
            *   **依赖注入**：使用 `get_it` 或 `provider` 进行依赖注入，解耦模块依赖关系。
            *   **组合优于继承**：优先使用组合方式，提高代码的灵活性和可维护性。

*   **其他**：
    *   **安全性设计**：
        *   配对码应具有一定的复杂度，防止暴力破解。
        *   配对码应设置过期时间，增加安全性。
    *   **性能优化**：
        *   网络连接应使用高效的 Socket 通信，减少延迟。
    *   **单元测试**：
        *   针对设备配对、连接等核心模块编写单元测试。
        *   使用 Mock 对象模拟网络请求和数据存储，保证单元测试的独立性。
        *   测试用例覆盖正常流程、异常情况和边界条件。
    *   **风险评估**：
        *   **风险**：配对过程可能因用户操作失误导致失败。
        *   **应对措施**：
            *   提供清晰的配对操作指引和状态反馈，引导用户正确操作。
            *   加强错误处理，针对不同错误情况提供友好的提示信息。
            *   考虑增加配对重试机制，提高配对成功率。