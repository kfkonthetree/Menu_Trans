import Foundation



struct ImageService {
    private static var accessKey: String? {
        return Config.unsplashAccessKey
    }
    private static let baseURL = "https://api.unsplash.com/search/photos"
    
    static func fetchImageURL(for searchTerm: String) async -> URL? {
        Logger.shared.debug("🖼️ 开始获取图片URL: \(searchTerm)")
        
        var components = URLComponents(string: baseURL)
        components?.queryItems = [
            URLQueryItem(name: "query", value: "\(searchTerm) food"),
            URLQueryItem(name: "per_page", value: "1")
        ]
        
        guard let url = components?.url else { 
            Logger.shared.error("❌ 无法构建URL")
            return nil 
        }
        
        guard let accessKey = accessKey else {
            Logger.shared.error("❌ Unsplash API密钥未配置")
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Client-ID \(accessKey)", forHTTPHeaderField: "Authorization")
        
        Logger.shared.debug("📡 发送Unsplash API请求到: \(url)")
        
        do {
            let (data, response) = try await performRequestWithRetry(request: request, maxRetries: 2)
            
            if let httpResponse = response as? HTTPURLResponse {
                Logger.shared.debug("📊 HTTP状态码: \(httpResponse.statusCode)")
                if httpResponse.statusCode != 200 {
                    Logger.shared.error("❌ Unsplash API请求失败，状态码: \(httpResponse.statusCode)")
                    let errorString = String(data: data, encoding: .utf8) ?? "未知错误"
                    Logger.shared.error("❌ 错误详情: \(errorString)")
                    return nil
                }
            }
            
            // 解析JSON响应
            let unsplashResponse = try JSONDecoder().decode(UnsplashResponse.self, from: data)
            
            if let firstImage = unsplashResponse.results.first {
                    Logger.shared.info("✅ 成功获取图片URL: \(firstImage.urls.regular)")
                    return firstImage.urls.regular
                } else {
                    Logger.shared.warning("⚠️ 未找到相关图片")
                    return nil
                }
        } catch {
            // 增强错误日志，特别针对 SSL 错误
            if let urlError = error as? URLError {
                switch urlError.code {
                case .secureConnectionFailed:
                    Logger.shared.error("🔒 SSL连接失败: \(urlError.localizedDescription)")
                    Logger.shared.error("🔒 这通常是由于网络SSL证书问题或防火墙设置导致的")
                case .notConnectedToInternet:
                    Logger.shared.error("🌐 网络连接失败: \(urlError.localizedDescription)")
                case .timedOut:
                    Logger.shared.error("⏰ 请求超时: \(urlError.localizedDescription)")
                case .cannotFindHost:
                    Logger.shared.error("🔍 无法找到主机: \(urlError.localizedDescription)")
                default:
                    Logger.shared.error("❌ 网络错误 (Code: \(urlError.code.rawValue)): \(urlError.localizedDescription)")
                }
            } else {
                Logger.shared.error("❌ 获取图片URL失败: \(error)", error: error)
            }
            return nil
        }
    }
    
    // 网络请求重试机制
    private static func performRequestWithRetry(request: URLRequest, maxRetries: Int) async throws -> (Data, URLResponse) {
        var lastError: Error?
        
        for attempt in 0...maxRetries {
            do {
                Logger.shared.debug("🔄 图片服务网络请求尝试 \(attempt + 1)/\(maxRetries + 1)")
                let result = try await URLSession.shared.data(for: request)
                return result
            } catch {
                lastError = error
                
                // 增强重试机制中的错误日志
                if let urlError = error as? URLError {
                    switch urlError.code {
                    case .secureConnectionFailed:
                        Logger.shared.error("🔒 SSL连接失败 (尝试 \(attempt + 1)): \(urlError.localizedDescription)")
                    case .notConnectedToInternet:
                        Logger.shared.error("🌐 网络连接失败 (尝试 \(attempt + 1)): \(urlError.localizedDescription)")
                    case .timedOut:
                        Logger.shared.error("⏰ 请求超时 (尝试 \(attempt + 1)): \(urlError.localizedDescription)")
                    default:
                        Logger.shared.error("❌ 网络错误 (尝试 \(attempt + 1), Code: \(urlError.code.rawValue)): \(urlError.localizedDescription)")
                    }
                } else {
                    Logger.shared.error("❌ 图片服务网络请求失败 (尝试 \(attempt + 1)): \(error)", error: error)
                }
                
                if attempt < maxRetries {
                    Logger.shared.debug("⏳ 等待 1.5 秒后重试...")
                    try await Task.sleep(nanoseconds: 1_500_000_000) // 1.5秒
                }
            }
        }
        
        throw lastError ?? NSError(domain: "ImageService", code: -1, userInfo: [NSLocalizedDescriptionKey: "所有重试都失败了"])
    }
}

// Unsplash API响应结构
struct UnsplashResponse: Codable {
    let results: [UnsplashPhoto]
}

struct UnsplashPhoto: Codable {
    let urls: UnsplashURLs
}

struct UnsplashURLs: Codable {
    let small: URL
    let regular: URL
}
