import Foundation

struct Config {
    // 从Keychain获取API密钥和URL
    static var siliconFlowAPIKey: String? {
        return KeychainService.load(forKey: .siliconFlowAPIKey)
    }
    
    static var siliconFlowAPIURL: String? {
        return KeychainService.load(forKey: .siliconFlowAPIURL)
    }
    
    // 从Keychain获取Unsplash API密钥
    static var unsplashAccessKey: String? {
        return KeychainService.load(forKey: .unsplashAccessKey)
    }
    
    // 初始化Keychain存储（仅在开发环境使用，生产环境应通过安全渠道配置）
    static func initializeKeychain() {
        // 注意：在生产环境中，这些值不应硬编码，而应通过安全方式配置
        #if DEBUG
        KeychainService.save("sk-nwbvmqxaznxkcndffguubiaksenvccodnxmtkbcxaerknrbu", forKey: .siliconFlowAPIKey)
        KeychainService.save("https://api.siliconflow.cn/v1/chat/completions", forKey: .siliconFlowAPIURL)
        KeychainService.save("BiEmm_WSxSKpPiKKSn1RQ5QzqKzgjOyhX9HLuaFtmy0", forKey: .unsplashAccessKey)
        #endif
    }
}