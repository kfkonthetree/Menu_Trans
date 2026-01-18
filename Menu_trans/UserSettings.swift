import SwiftUI

class UserSettings: ObservableObject {
    @AppStorage("userProfile") private var profileData: Data?

    @Published var profile: UserProfile {
        didSet {
            save()
        }
    }

    init() {
        self.profile = UserSettings.load()
    }

    // 从 UserDefaults 加载数据
    private static func load() -> UserProfile {
        if let data = UserDefaults.standard.data(forKey: "userProfile") {
            if let decodedProfile = try? JSONDecoder().decode(UserProfile.self, from: data) {
                return decodedProfile
            }
        }
        return UserProfile() // 如果没有保存过，返回一个默认的
    }

    // 保存数据到 UserDefaults
    private func save() {
        if let encodedData = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(encodedData, forKey: "userProfile")
        }
    }
} 