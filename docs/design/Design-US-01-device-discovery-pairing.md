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
    *   **功能模块**：
        *   **模块划分**：
            1.  **设备配对模块**：
                *   **功能**：生成配对码，验证配对码，处理配对请求和确认。
                *   **职责**：处理设备间的配对逻辑，确保安全连接。
            2.  **连接管理模块**：
                *   **功能**：管理设备连接状态，处理连接建立、断开、失败等情况。
                *   **职责**：维护设备连接状态，提供连接状态反馈。
        *   **模块交互**：
            *   用户手动输入IP地址。
            *   用户选择设备进行配对，设备配对模块生成配对码并通过 UI 展示。
            *   用户在另一设备上输入配对码，设备配对模块验证配对码。
            *   配对成功后，连接管理模块建立设备连接，并更新连接状态。
        *   **流程图**：

            ```mermaid
            graph LR
                A[用户打开设备列表页面] --> B[用户输入IP地址];
                B --> C{用户选择设备};
                C --> D{是否已配对};
                D -- 是 --> E[建立连接];
                D -- 否 --> F[设备配对模块生成配对码];
                F --> G[双方设备显示配对码];
                G --> H{用户确认配对};
                H -- 是 --> I[验证配对码];
                I --> J{配对成功};
                J --> E;
                H -- 否 --> K[取消配对];
                K --> A;
                E --> L[连接建立成功];
                E --> M[显示连接状态];
            ```
    *   **异常处理**：
       *   **异常处理流程**：
           1.  **IP地址输入错误**：
               *   **描述**：用户手动输入 IP 地址时，可能会输入错误的 IP 地址格式或无效的 IP 地址。
               *   **处理方案**：
                   *   **UI 校验**：前端 UI 需对 IP 地址格式进行实时校验，确保输入符合 IPv4/IPv6 格式。
                   *   **后端验证**：后端在尝试连接前，使用 `dart:io` 库中的 `InternetAddress.lookup` 或 `Socket.connect` 方法验证 IP 地址的可达性。
                   *   **错误提示**：如果 IP 地址格式错误，UI 立即给出格式错误提示。如果 IP 地址无效或不可达，连接尝试失败后，UI 给出明确的错误提示（例如“IP 地址无效或设备未响应”），引导用户重新输入或检查网络连接。
           2.  **连接超时**：
               *   **描述**：在设备配对或连接建立过程中，可能由于网络问题导致连接超时。
               *   **处理方案**：
                   *   **超时设置**：在进行网络操作（如 Socket 连接、配对码验证）时，设置合理的超时时间（例如 30 秒）。
                   *   **超时处理**：使用 `dart:async` 库的 `timeout` 功能来控制网络请求的超时。连接超时后，捕获 `TimeoutException` 异常。
                   *   **错误提示**：连接超时后，UI 应提示用户“连接超时，请检查网络连接或重试”，并提供重试操作的选项。
           3.  **配对请求取消**：
               *   **描述**：设备 A 发起配对请求后，用户可能在设备 B 上取消配对请求。
               *   **处理方案**：
                   *   **取消操作**：设备 B 提供“取消配对”按钮，允许用户取消配对请求。
                   *   **消息通知**：设备 B 取消配对后，向设备 A 发送取消配对的消息。
                   *   **UI 更新**：设备 A 收到配对取消消息后，应停止配对流程，并更新 UI 状态，例如返回设备列表页面，并提示“配对已取消”。
           4.  **已配对设备重复配对**：
               *   **描述**：用户尝试与已配对的设备再次进行配对。
               *   **处理方案**：
                   *   **状态检查**：在发起配对前，检查目标设备是否已在已配对设备列表中。
                   *   **UI 提示**：在 UI 上，已配对的设备应有明显的标识（例如“已配对”图标）。当用户选择已配对设备时，可以弹窗提示“该设备已配对，是否重新配对？”，提供“重新配对”和“取消”选项。
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
                - generatePairingCode(): String // 生成配对码
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