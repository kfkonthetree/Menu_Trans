import Foundation



struct SiliconFlowAPIService {
    static var apiKey: String? {
        return Config.siliconFlowAPIKey
    }
    
    static var apiURL: URL? {
        guard let urlString = Config.siliconFlowAPIURL else {
            print("❌ API URL未配置")
            return nil
        }
        return URL(string: urlString)
    }
    
    // 测试网络连接
    static func testNetworkConnection() async -> Bool {
        Logger.shared.debug("🌐 测试网络连接...")
        
        guard let testURL = URL(string: "https://www.apple.com") else {
            Logger.shared.error("❌ 无法创建测试URL")
            return false
        }
        
        do {
            let (_, response) = try await URLSession.shared.data(from: testURL)
            if let httpResponse = response as? HTTPURLResponse {
                Logger.shared.info("✅ 网络连接正常，状态码: \(httpResponse.statusCode)")
                return httpResponse.statusCode == 200
            }
        } catch {
            Logger.shared.error("❌ 网络连接失败: \(error)", error: error)
        }
        
        return false
    }
    
    static func getExplanation(for dishName: String, userProfile: UserProfile) async throws -> DishInfo {
        Logger.shared.debug("🔍 开始获取菜品解释: \(dishName)")
        
        guard let apiURL = apiURL, let apiKey = apiKey else {
            Logger.shared.error("❌ API配置未找到")
            throw NSError(domain: "SiliconFlowAPIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "API配置未找到"]) 
        }
        
        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // 构建用户偏好信息
        let restrictionsText = userProfile.restrictions.isEmpty ? "None" : userProfile.restrictions.joined(separator: ", ")
        let flavorPreferencesText = userProfile.flavorPreferences.isEmpty ? "None" : userProfile.flavorPreferences.joined(separator: ", ")
        let dietaryHabits = [
            userProfile.isVegetarian ? "Vegetarian" : nil,
            userProfile.isVegan ? "Vegan" : nil
        ].compactMap { $0 }.joined(separator: ", ")
        
        let systemPrompt = """
        You are an expert Chinese food critic and translator with dietary analysis expertise. Your task is to analyze a Chinese dish name and return a structured JSON object that includes dietary safety and preference matching analysis.
        
        The JSON object MUST NOT contain any markdown formatting like ```json. It must be a raw JSON string.
        
        The user's language is English. All descriptive fields MUST be in English, including `flavorTags`.
        
        User Profile Information:
        - Dietary Restrictions: \(restrictionsText)
        - Dietary Habits: \(dietaryHabits.isEmpty ? "None" : dietaryHabits)
        - Flavor Preferences: \(flavorPreferencesText)
        - Preferred Spice Level: \(userProfile.spiceLevel.rawValue)
        
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
        """
        let messages: [[String: String]] = [
            ["role": "system", "content": systemPrompt],
            ["role": "user", "content": dishName]
        ]
        let body: [String: Any] = [
            "model": "Pro/Qwen/Qwen2.5-VL-7B-Instruct",
            "messages": messages
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        Logger.shared.debug("📡 发送API请求到: \(apiURL)")
        let (data, response) = try await performRequestWithRetry(request: request, maxRetries: 2)
        
        // --- 调试代码：打印原始API响应 ---
        if let responseString = String(data: data, encoding: .utf8) {
            print("""

            ✅✅✅ RECEIVED RAW API RESPONSE FROM EXPLANATION ✅✅✅
            -------------------------------------------
            \(responseString)
            -------------------------------------------

            """)
        }
        // --- 调试代码结束 ---
        
        if let httpResponse = response as? HTTPURLResponse {
            Logger.shared.debug("📊 HTTP状态码: \(httpResponse.statusCode)")
            if httpResponse.statusCode != 200 {
                Logger.shared.error("❌ API请求失败，状态码: \(httpResponse.statusCode)")
                let errorString = String(data: data, encoding: .utf8) ?? "未知错误"
                Logger.shared.error("❌ 错误详情: \(errorString)")
                throw NSError(domain: "SiliconFlowAPIService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "API请求失败: \(errorString)"])
            }
        }
        
        struct APIResponse: Decodable {
            struct Choice: Decodable {
                struct Message: Decodable {
                    let content: String
                }
                let message: Message
            }
            let choices: [Choice]
        }
        let apiResponse = try JSONDecoder().decode(APIResponse.self, from: data)
        guard let firstChoice = apiResponse.choices.first else {
            Logger.shared.error("❌ API响应中没有选择项")
            throw NSError(domain: "SiliconFlowAPIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No choices in response"])
        }
        // 1. 获取从 AI 返回的原始 content 字符串
        let rawContentString = firstChoice.message.content
        
        // 2. 使用更健壮的方法，直接提取`{`和`}`之间的内容（JSON对象）
        var jsonString: String?
        if let rangeStart = rawContentString.range(of: "{"), let rangeEnd = rawContentString.range(of: "}", options: .backwards) {
            // 确保起始位置在结束位置之前
            if rangeStart.lowerBound <= rangeEnd.lowerBound {
                jsonString = String(rawContentString[rangeStart.lowerBound...rangeEnd.lowerBound])
            }
        }
        
        // 3. 确保我们成功提取了 JSON 字符串，然后进行解码
        guard let finalJSONString = jsonString, let dishInfoData = finalJSONString.data(using: .utf8) else {
            Logger.shared.critical("Could not extract a valid JSON object from the raw response.")
            Logger.shared.debug("Raw response was: \(rawContentString)")
            throw URLError(.cannotParseResponse) // 抛出一个错误
        }
        
        Logger.shared.debug("🧹 提取的JSON字符串 (DishInfo): \(finalJSONString)")
        
        // 4. 对提取出的纯净 JSON 字符串进行解码
        do {
            let dishInfo = try JSONDecoder().decode(DishInfo.self, from: dishInfoData)
            Logger.shared.info("✅ 成功解码DishInfo: \(dishInfo.chineseName)")
            return dishInfo // 成功解码，返回结果
        } catch {
            // 如果提取后解码依然失败，打印详细错误并抛出
            Logger.shared.critical("JSON decoding failed AFTER extraction (DishInfo). Error: \(error)", error: error)
            Logger.shared.debug("Extracted faulty JSON string was: \(finalJSONString)")
            throw error // 抛出解码错误
        }
    }
    
    static func identifyDishesInImage(imageData: Data) async throws -> [String] {
        Logger.shared.debug("🖼️ 开始识别图片中的菜品")
        
        guard let apiURL = apiURL, let apiKey = apiKey else {
            Logger.shared.error("❌ API配置未找到")
            throw NSError(domain: "SiliconFlowAPIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "API配置未找到"]) 
        }
        
        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // 将图片数据转换为 base64
        let base64Image = imageData.base64EncodedString()
        Logger.shared.debug("📸 图片大小: \(imageData.count) bytes, Base64长度: \(base64Image.count)")
        
        let systemPrompt = "You are an expert OCR engine specializing in Chinese restaurant menus. Analyze this image and extract every distinct dish name you can find. Return them as a single JSON array of strings. Pay close attention to multi-line dish names and ignore prices or descriptions. Focus only on the dish names themselves."
        
        let messages: [[String: Any]] = [
            ["role": "system", "content": systemPrompt],
            ["role": "user", "content": [
                ["type": "text", "text": "请识别这张菜单中的所有菜品名称"],
                ["type": "image_url", "image_url": ["url": "data:image/jpeg;base64,\(base64Image)"]]
            ]]
        ]
        
        let body: [String: Any] = [
            "model": "Pro/Qwen/Qwen2.5-VL-7B-Instruct",
            "messages": messages
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        Logger.shared.debug("📡 发送图片识别API请求到: \(apiURL)")
        let (data, response) = try await performRequestWithRetry(request: request, maxRetries: 2)
        
        // --- 调试代码：打印原始API响应 ---
        if let responseString = String(data: data, encoding: .utf8) {
            print("""

            ✅✅✅ RECEIVED RAW API RESPONSE FROM OCR ✅✅✅
            -------------------------------------------
            \(responseString)
            -------------------------------------------

            """)
        }
        // --- 调试代码结束 ---
        
        if let httpResponse = response as? HTTPURLResponse {
            print("📊 HTTP状态码: \(httpResponse.statusCode)")
            if httpResponse.statusCode != 200 {
                print("❌ 图片识别API请求失败，状态码: \(httpResponse.statusCode)")
                let errorString = String(data: data, encoding: .utf8) ?? "未知错误"
                print("❌ 错误详情: \(errorString)")
                throw NSError(domain: "SiliconFlowAPIService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "图片识别API请求失败: \(errorString)"])
            }
        }
        
        struct APIResponse: Decodable {
            struct Choice: Decodable {
                struct Message: Decodable {
                    let content: String
                }
                let message: Message
            }
            let choices: [Choice]
        }
        let apiResponse = try JSONDecoder().decode(APIResponse.self, from: data)
        guard let firstChoice = apiResponse.choices.first else {
            Logger.shared.error("❌ API响应中没有选择项")
            throw NSError(domain: "SiliconFlowAPIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No choices in response"])
        }
        // 1. 获取从 AI 返回的原始 content 字符串
        let rawContentString = firstChoice.message.content
        
        // 2. 使用更健壮的方法，直接提取`[`和`]`之间的内容
        var jsonString: String?
        if let rangeStart = rawContentString.range(of: "["), let rangeEnd = rawContentString.range(of: "]", options: .backwards) {
            // 确保起始位置在结束位置之前
            if rangeStart.lowerBound <= rangeEnd.lowerBound {
                jsonString = String(rawContentString[rangeStart.lowerBound...rangeEnd.lowerBound])
            }
        }
        
        // 3. 确保我们成功提取了 JSON 字符串，然后进行解码
        guard let finalJSONString = jsonString, let dishNamesData = finalJSONString.data(using: .utf8) else {
            Logger.shared.critical("Could not extract a valid JSON array from the raw response.")
            Logger.shared.debug("Raw response was: \(rawContentString)")
            throw URLError(.cannotParseResponse) // 抛出一个错误
        }
        
        Logger.shared.debug("🧹 提取的JSON字符串: \(finalJSONString)")
        
        // 4. 对提取出的纯净 JSON 字符串进行解码
        do {
            let dishNames = try JSONDecoder().decode([String].self, from: dishNamesData)
            Logger.shared.info("✅ 成功解码菜品名称: \(dishNames)")
            return dishNames // 成功解码，返回结果
        } catch {
            // 如果提取后解码依然失败，打印详细错误并抛出
            Logger.shared.critical("JSON decoding failed AFTER extraction. Error: \(error)", error: error)
            Logger.shared.debug("Extracted faulty JSON string was: \(finalJSONString)")
            throw error // 抛出解码错误
        }
    }
    
    // 网络请求重试机制
    private static func performRequestWithRetry(request: URLRequest, maxRetries: Int) async throws -> (Data, URLResponse) {
        var lastError: Error?
        
        for attempt in 0...maxRetries {
            do {
                Logger.shared.debug("🔄 网络请求尝试 \(attempt + 1)/\(maxRetries + 1)")
                let result = try await URLSession.shared.data(for: request)
                return result
            } catch {
                lastError = error
                Logger.shared.error("❌ 网络请求失败 (尝试 \(attempt + 1)): \(error)", error: error)
                
                if attempt < maxRetries {
                    Logger.shared.debug("⏳ 等待 1.5 秒后重试...")
                    try await Task.sleep(nanoseconds: 1_500_000_000) // 1.5秒
                }
            }
        }
        
        throw lastError ?? NSError(domain: "SiliconFlowAPIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "所有重试都失败了"])
    }
} 
