# AI 菜单翻译器 - 技术分析文档

## 1. 高级项目概览

本项目是一个基于 iOS 的原生移动应用，旨在帮助外国人在中餐厅点餐。应用的核心功能是：用户拍摄中文菜单照片后，应用通过视觉语言模型（Qwen2.5-VL）进行 OCR 识别和菜品信息提取，然后将每个菜品转换为结构化的英文信息（包括翻译名称、食材、烹饪方法、口味标签等），并基于用户的饮食偏好进行智能排序和匹配度分析。用户通过滑动卡片的方式选择想要点餐的菜品，最终生成中英文对照的订单列表。应用采用 **纯客户端架构**，使用 SwiftUI 框架构建界面，通过 RESTful API 调用外部 LLM 服务，所有数据存储在本地设备上（UserDefaults + SwiftData）。

---

## 2. 详细技术栈

### **前端**
- **框架**: SwiftUI（Apple 官方声明式 UI 框架）
- **编程语言**: Swift 5.x
- **iOS 版本要求**: iOS 16.0+（基于 SwiftUI 和 SwiftData 的使用）
- **UI 组件库**: 
  - SwiftUI 原生组件（NavigationView, TabView, List, etc.）
  - VisionKit（VNDocumentCameraViewController）用于文档扫描

### **后端**
- **架构**: 无独立后端服务器
- **API 服务**: 完全通过客户端调用外部 API

### **数据库**
- **本地存储**:
  - **UserDefaults**: 用于存储用户偏好设置、搜索历史、收藏夹、订单历史等轻量级数据
  - **SwiftData**: 用于持久化 Item 模型（项目中使用较简单）
  - 所有数据均存储在设备本地，无云同步

### **APIs & 服务**

#### **LLM API**
- **服务提供商**: SiliconFlow（中国境内的 LLM API 服务）
- **API 端点**: `https://api.siliconflow.cn/v1/chat/completions`
- **使用的模型**: `Pro/Qwen/Qwen2.5-VL-7B-Instruct`（多模态视觉语言模型）
- **认证方式**: Bearer Token（API Key 存储在 `Config.swift` 中）
- **主要功能**:
  1. **OCR 识别**: 从菜单图片中提取所有菜品名称（返回 JSON 数组）
  2. **菜品解析**: 基于菜品名称返回结构化信息（翻译、食材、烹饪方法、口味标签、饮食分析）

#### **OCR 服务**
- **技术方案**: 集成在 LLM API 调用中，使用 Qwen2.5-VL 的多模态能力进行图像文本识别
- **处理流程**: 图片 → Base64 编码 → 发送到 LLM API → 返回菜品名称数组

#### **其他第三方服务**
- **Unsplash API**: 
  - 用途：为每个菜品获取展示图片
  - 端点：`https://api.unsplash.com/search/photos`
  - 认证：Client-ID（存储在 `ImageService.swift` 中）
  - 搜索策略：先使用中文名搜索，失败则使用英文名作为备选

---

## 3. 核心功能到代码映射

### **图片上传与预处理**
- **主要文件**: `ContentView.swift`, `DocumentScannerView.swift`
- **关键函数/组件**:
  - `DocumentScannerView`: 封装 `VNDocumentCameraViewController`，提供文档扫描界面
  - `PhotosPicker`: SwiftUI 原生组件，用于从相册选择图片
  - `processSelectedImage()` (line 205-318): 处理从相册选择的图片
  - `processScannedImage(_:)` (line 320-432): 处理扫描的图片
- **处理流程**: 
  1. 用户通过相机或相册选择图片
  2. 将 `UIImage` 转换为 JPEG Data（压缩质量 0.8）
  3. 发送到 API 进行识别

### **API 调用到 LLM/OCR 服务**
- **主要文件**: `SiliconFlowAPIService.swift`
- **关键函数**:
  - `identifyDishesInImage(imageData:)` (line 165-264): 识别图片中的菜品名称
    - 将图片数据转换为 Base64
    - 构建包含图片的 messages 数组
    - 发送 POST 请求到 API
    - 解析返回的 JSON 数组
  - `getExplanation(for:userProfile:)` (line 29-163): 获取单个菜品的详细信息
    - 构建包含用户偏好信息的 system prompt
    - 发送菜品名称到 API
    - 解析返回的 `DishInfo` JSON 对象
  - `performRequestWithRetry(request:maxRetries:)` (line 267-287): 网络请求重试机制（最多重试 2 次，间隔 1.5 秒）

### **解析 LLM 的 JSON 响应**
- **主要文件**: `SiliconFlowAPIService.swift`, `DishInfo.swift`
- **关键逻辑**:
  - **JSON 提取策略** (line 135-148): 
    - 从 LLM 返回的原始字符串中提取第一个 `{` 和最后一个 `}` 之间的内容（去除可能的 markdown 包装）
    - 同样策略用于提取数组：第一个 `[` 和最后一个 `]` 之间
  - **解码流程**:
    - 使用 `JSONDecoder` 解码为 `APIResponse` 结构体
    - 提取 `content` 字段中的 JSON 字符串
    - 再次解码为 `DishInfo` 或 `[String]`（菜品名称数组）
  - **错误处理**: 如果提取或解码失败，打印详细错误信息并抛出异常

### **"可滑动卡片" UI 组件**
- **主要文件**: `ResultsView.swift`
- **关键组件**:
  - `ResultsView`: 主视图，管理卡片显示和用户交互
  - `DishCardView` (line 262-522): 单个菜品卡片组件
- **滑动实现**:
  - **手势识别**: 使用 `DragGesture()` 监听拖动手势 (line 57-65)
  - **滑动处理**: `handleSwipe(_:)` (line 205-231)
    - 阈值：100 像素
    - 速度检测：预测结束位置与当前位置的差值
    - 向右滑动 → 添加到订单（带动画）
    - 向左滑动 → 跳过菜品（带动画）
  - **视觉效果**:
    - `offset()`: 跟随拖动手势移动 (line 492)
    - `rotationEffect()`: 根据拖动距离旋转（最大约 18 度）(line 493)
    - `scaleEffect()`: 根据拖动距离缩放 (line 494)
    - 显示 "Like" 或 "Nope" 文字提示 (line 496-519)

### **状态管理（用户选择：喜欢/不喜欢的菜品）**
- **主要文件**: `ResultsView.swift`, `OrderListView.swift`
- **状态变量**:
  - `@State var orderList: [DishInfo]`: 已选择的菜品（添加到订单）
  - `@State var skippedDishes: [DishInfo]`: 跳过的菜品
  - `@State var currentIndex: Int`: 当前显示的卡片索引
- **关键函数**:
  - `addToOrderList()` (line 233-243): 将当前菜品添加到订单（检查重复）
  - `skipDish()` (line 245-251): 将当前菜品添加到跳过列表
  - `nextCard()` (line 253-259): 切换到下一张卡片

### **生成最终订单列表**
- **主要文件**: `OrderListView.swift`, `Order.swift`
- **关键组件**:
  - `OrderListView`: 订单列表视图
  - `Order` 结构体：订单数据模型（包含 ID、日期、菜品数组）
  - `OrderManager` 类：订单管理器（使用 UserDefaults 持久化）
- **功能实现**:
  - **列表展示** (line 28-62): 使用 `List` 显示所有已选菜品（中英文对照）
  - **订单完成** (line 69-75): 点击完成按钮后，创建 `Order` 对象并保存到 `OrderManager`
  - **中英文对照**: 显示中文名（如果存在）和英文名

### **用户偏好与排序逻辑**
- **主要文件**: `UserSettings.swift`, `UserProfile.swift`, `ContentView.swift`
- **用户偏好存储**:
  - `UserProfile`: 用户偏好数据模型（饮食限制、素食/纯素、口味偏好、辣度级别）
  - `UserSettings`: 使用 `@AppStorage` 和 UserDefaults 持久化用户偏好
- **排序逻辑** (ContentView.swift line 294-306, 408-420):
  - **第一步**: 安全性优先（`isSafe == true` 的菜品排在前面）
  - **第二步**: 按匹配分数降序排序（`matchScore` 高的优先）
- **匹配分析**: LLM 在返回 `DishInfo` 时会包含 `DietaryAnalysis`，包括：
  - `isSafe`: 是否安全（不违反饮食限制）
  - `preferenceMatch`: 是否匹配用户偏好
  - `matchScore`: 匹配分数（0-100）
  - `matchReason`: 匹配原因说明

### **"收藏夹"功能（保存和检索）**
- **主要文件**: `CollectionsManager.swift`, `CollectionsView.swift`, `CollectionPickerView.swift`
- **数据模型**:
  - `Collection`: 收藏夹数据模型（ID、名称、描述、菜品数组、创建时间）
- **核心管理器**: `CollectionsManager`
  - `collections: [Collection]`: 存储所有收藏夹
  - 使用 UserDefaults 持久化（key: "savedCollections"）
- **关键功能**:
  - `addCollection(_:)`: 创建新收藏夹
  - `addDishToCollection(_:collectionId:)`: 将菜品添加到指定收藏夹
  - `renameCollection(_:newName:)`: 重命名收藏夹
  - `deleteCollection(_:)`: 删除收藏夹
  - `removeDishFromCollection(_:dishIndex:)`: 从收藏夹中移除菜品

---

## 4. AI 与数据流分析

### **步骤 1: 图片到文本**
- **实现位置**: `SiliconFlowAPIService.swift` → `identifyDishesInImage(imageData:)`
- **技术方案**: 
  - **不使用传统 OCR 库**（如 Vision Framework 的 `VNRecognizeTextRequest`），而是直接使用 LLM 的多模态能力
  - 将图片数据转换为 Base64 编码字符串
  - 构建包含图片 URL 的 messages 数组：
    ```swift
    ["role": "user", "content": [
        ["type": "text", "text": "请识别这张菜单中的所有菜品名称"],
        ["type": "image_url", "image_url": ["url": "data:image/jpeg;base64,\(base64Image)"]]
    ]]
    ```
  - 发送到 SiliconFlow API（模型：Qwen2.5-VL-7B-Instruct）
  - **返回格式**: JSON 数组，例如 `["宫保鸡丁", "麻婆豆腐", "糖醋里脊"]`

### **步骤 2: 提示词工程（Prompt Engineering）**
- **实现位置**: `SiliconFlowAPIService.swift` → `getExplanation(for:userProfile:)` (line 45-81)
- **完整 System Prompt**:
  ```
  You are an expert Chinese food critic and translator with dietary analysis expertise. Your task is to analyze a Chinese dish name and return a structured JSON object that includes dietary safety and preference matching analysis.
  
  The JSON object MUST NOT contain any markdown formatting like ```json. It must be a raw JSON string.
  
  The user's language is English. All descriptive fields MUST be in English, including `flavorTags`.
  
  User Profile Information:
  - Dietary Restrictions: [用户限制]
  - Dietary Habits: [素食/纯素]
  - Flavor Preferences: [口味偏好]
  - Preferred Spice Level: [辣度级别]
  
  The JSON object must have the following exact structure:
  {
    "chineseName": "菜品的中文名",
    "englishName": "A professional and appealing English name for the dish",
    "pinyinName": "The standard Hanyu Pinyin for the Chinese name, including tone marks. For example: 'gōng bǎo jī dīng'",
    "ingredients": [ "An array of at least 3 main ingredients in ENGLISH." ],
    "cookingMethod": "A brief cooking method in ENGLISH.",
    "flavorTags": [ "An array of 2-3 short, descriptive flavor tags in ENGLISH. For example: 'Spicy', 'Savory', 'Sweet and Sour'." ],
    "dietaryAnalysis": {
      "isSafe": true/false,
      "conflictReason": "Reason if not safe, null if safe",
      "preferenceMatch": true/false,
      "matchReason": "Reason if matches preferences, null if no match",
      "matchScore": 0-100
    }
  }
  
  Dietary Analysis Guidelines:
  1. Check if the dish contains any of the user's dietary restrictions
  2. Consider vegetarian/vegan requirements
  3. Analyze flavor preferences and spice level compatibility
  4. Assign a match score (0-100) based on how well the dish matches user preferences
  5. Provide clear reasons for safety issues or preference matches
  ```
- **关键设计点**:
  - 明确要求返回纯 JSON（无 markdown 包装）
  - 所有描述性字段必须是英文
  - 动态注入用户偏好信息
  - 要求详细的饮食分析和匹配分数

### **步骤 3: 响应处理（JSON 解析与验证）**
- **实现位置**: `SiliconFlowAPIService.swift` (line 118-162)
- **处理流程**:
  1. **解析 API 响应结构**: 
     - 使用嵌套结构体 `APIResponse` → `Choice` → `Message` 解码
     - 提取 `content` 字段（LLM 的文本回复）
  2. **提取 JSON 字符串**:
     - 查找第一个 `{` 和最后一个 `}` 的位置
     - 提取之间的子字符串（去除可能的 markdown 代码块包装）
  3. **验证与解码**:
     - 检查提取的字符串是否可以转换为 UTF-8 Data
     - 使用 `JSONDecoder` 解码为 `DishInfo` 结构体
  4. **错误处理**:
     - 如果提取失败，打印原始响应并抛出 `URLError.cannotParseResponse`
     - 如果解码失败，打印提取的 JSON 字符串并重新抛出错误
- **数据模型**: `DishInfo.swift`
  - 符合 `Codable` 协议，自动映射 JSON 字段
  - 包含 `CodingKeys` 枚举，排除 `id` 和 `imageURL`（这些是客户端生成的）

### **步骤 4: 数据到 UI（渲染为可滑动卡片）**
- **实现位置**: `ContentView.swift` → `ResultsView.swift`
- **数据流**:
  1. **批量获取菜品信息** (ContentView.swift line 247-267):
     - 使用 `withThrowingTaskGroup` 并发调用 `getExplanation` 获取每个菜品的详细信息
     - 更新进度条（`progressManager.completedItems`）
  2. **获取图片 URL** (ContentView.swift line 269-292):
     - 遍历所有菜品，使用 `ImageService.fetchImageURL` 获取图片
     - 两步策略：先使用中文名搜索，失败则使用英文名
  3. **智能排序** (ContentView.swift line 294-306):
     - 安全性优先 → 匹配分数降序
  4. **传递到 ResultsView** (ContentView.swift line 166):
     - 使用 `fullScreenCover` 展示结果视图
  5. **卡片渲染** (ResultsView.swift):
     - `DishCardView` 显示单个菜品卡片
     - 使用 `AsyncImage` 异步加载图片（带占位符）
     - 显示所有菜品信息（名称、拼音、食材、烹饪方法、口味标签、匹配分数等）
     - 支持拖动手势切换卡片

---

## 5. 项目架构

### **架构模式**: 纯客户端架构（Standalone Mobile App）

- **无独立后端服务器**: 所有业务逻辑在客户端执行
- **API 集成**: 直接通过 HTTP 请求调用第三方 API（SiliconFlow, Unsplash）
- **数据持久化**: 
  - 本地存储（UserDefaults）用于：
    - 用户偏好设置
    - 搜索历史（最多 50 条）
    - 收藏夹集合
    - 订单历史
  - SwiftData 用于模型持久化（当前使用较简单）
- **状态管理**: 
  - SwiftUI 的 `@State`, `@StateObject`, `@Published` 进行响应式状态管理
  - `ObservableObject` 协议用于共享状态（如 `CollectionsManager`, `OrderManager`）
- **导航结构**: 
  - `MainTabView` 管理四个主要标签页：历史记录、扫描菜单、收藏夹、个人资料
  - 使用 `NavigationView` 和 `NavigationLink` 进行页面导航
  - `fullScreenCover` 和 `sheet` 用于模态展示

### **代码组织**:
- **MVC/MVVM 混合**: 
  - View（SwiftUI Views）: 所有 `.swift` 文件中的 View 结构体
  - Model（数据模型）: `DishInfo`, `UserProfile`, `Order`, `Collection` 等
  - ViewModel/Manager（业务逻辑）: `CollectionsManager`, `OrderManager`, `HistoryManager`, `SiliconFlowAPIService`, `ImageService`

---

## 6. 技术亮点与挑战

### **技术亮点**

#### **1. 并发处理与性能优化**
- **实现**: `ContentView.swift` line 247-267, 361-381
- **技术**: 使用 Swift 的 `withThrowingTaskGroup` 并发获取多个菜品信息
- **效果**: 当菜单包含 20+ 个菜品时，并发请求可以显著缩短总处理时间（相比串行请求）
- **代码示例**:
```swift
try await withThrowingTaskGroup(of: DishInfo?.self) { group in
    for name in dishNames {
        group.addTask {
            return try await SiliconFlowAPIService.getExplanation(for: name, userProfile: userSettings.profile)
        }
    }
    for try await info in group {
        if let info = info {
            dishInfos.append(info)
            await MainActor.run {
                progressManager.completedItems += 1
            }
        }
    }
}
```

#### **2. 智能图片搜索策略**
- **实现**: `ContentView.swift` line 269-292, `ImageService.swift`
- **策略**: 两步搜索法 - 先使用中文名搜索，失败则使用英文名作为备选
- **价值**: 提高图片获取成功率，改善用户体验
- **技术细节**: 使用 Unsplash API，带重试机制（最多 2 次，间隔 1.5 秒）

#### **3. 健壮的 JSON 解析机制**
- **实现**: `SiliconFlowAPIService.swift` line 135-148, 236-242
- **挑战**: LLM 有时会在 JSON 外包裹 markdown 代码块（如 ````json ... ```）
- **解决方案**: 提取第一个 `{` 和最后一个 `}` 之间的内容（或 `[` 和 `]` 用于数组）
- **优势**: 无论 LLM 返回格式如何变化，都能正确提取 JSON

#### **4. 用户偏好驱动的智能排序**
- **实现**: `ContentView.swift` line 294-306, `SiliconFlowAPIService.swift` prompt
- **功能**: 
  - LLM 基于用户饮食限制、口味偏好、辣度级别分析每个菜品
  - 返回匹配分数（0-100）和详细原因
  - 客户端按安全性 → 匹配分数双重排序
- **价值**: 提升用户体验，优先展示最适合的菜品

#### **5. 优雅的滑动交互设计**
- **实现**: `ResultsView.swift` `DishCardView`
- **特性**:
  - 流畅的拖动动画（旋转、缩放、位移）
  - 速度检测（即使拖动距离不足，快速滑动也会触发）
  - 视觉反馈（显示 "Like" / "Nope" 文字提示）
- **用户体验**: 类似 Tinder 的交互方式，直观且易用

### **主要挑战与解决方案**

#### **挑战 1: LLM 响应格式不一致**
- **问题**: LLM 有时返回纯 JSON，有时包含 markdown 代码块包装，有时还有额外说明文字
- **解决方案**: 
  - 使用字符串查找和范围提取（`range(of:)`）来提取 JSON 部分
  - 多层次的错误处理和日志记录
  - 在 prompt 中明确要求返回纯 JSON
- **代码位置**: `SiliconFlowAPIService.swift` line 135-148

#### **挑战 2: 网络请求的可靠性**
- **问题**: 移动网络环境不稳定，API 请求可能失败
- **解决方案**: 
  - 实现重试机制（最多 2 次重试，间隔 1.5 秒）
  - 网络连接检测（`testNetworkConnection()`）
  - 详细的错误日志（区分 SSL 错误、超时、无网络等）
- **代码位置**: `SiliconFlowAPIService.swift` line 267-287, `ImageService.swift` line 74-109

#### **挑战 3: 大量并发请求的性能与进度追踪**
- **问题**: 处理 20+ 个菜品时需要发起大量 API 请求，需要实时显示进度
- **解决方案**: 
  - 使用 `TaskGroup` 进行并发处理
  - `ProgressManager` 追踪总数量和已完成数量
  - `LoadingView` 显示实时进度条
  - 在主线程更新 UI（`MainActor.run`）
- **代码位置**: `ContentView.swift` line 247-267, `ProgressManager.swift`

#### **挑战 4: 用户体验优化（加载时间与反馈）**
- **问题**: API 调用耗时较长（每个菜品约 2-5 秒），用户等待体验差
- **解决方案**: 
  - 分阶段处理：先识别所有菜品名称，再并发获取详细信息
  - 实时进度反馈（进度条 + 数字显示）
  - 优雅的加载状态（`LoadingView`）
  - 图片异步加载（`AsyncImage`，带占位符）
- **代码位置**: `ContentView.swift` 整个处理流程, `LoadingView.swift`, `ProgressManager.swift`

---

## 附录：关键代码文件索引

- **应用入口**: `Menu_transApp.swift`
- **主界面**: `ContentView.swift`, `MainTabView.swift`
- **API 服务**: `SiliconFlowAPIService.swift`, `ImageService.swift`
- **数据模型**: `DishInfo.swift`, `UserProfile.swift`, `Order.swift`, `HistoryItem.swift`, `CollectionsView.swift` (Collection 结构体)
- **UI 组件**: `ResultsView.swift`, `OrderListView.swift`, `CollectionsView.swift`, `HistoryView.swift`
- **业务逻辑管理器**: `CollectionsManager.swift`, `OrderManager.swift`, `HistoryManager.swift`, `UserSettings.swift`, `ProgressManager.swift`
- **工具类**: `Config.swift`, `DocumentScannerView.swift`
