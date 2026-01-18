//
//  Menu_transApp.swift
//  Menu_trans
//
//  Created by 谢甲腾 on 2025/7/19.
//

import SwiftUI
import SwiftData

@main
struct Menu_transApp: App {
    init() {
        // 初始化Keychain配置
        Config.initializeKeychain()
    }
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(UserSettings())
        }
        .modelContainer(sharedModelContainer)
    }
}
