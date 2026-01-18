import Foundation

struct UserProfile: Codable, Equatable {
    var restrictions: Set<String> = []      // 存储忌口的英文关键词
    var isVegetarian: Bool = false
    var isVegan: Bool = false
    var flavorPreferences: Set<String> = [] // 存储口味偏好的英文关键词

    // 定义辣度枚举
    enum SpiceLevel: String, Codable, CaseIterable, Identifiable {
        var id: String { self.rawValue }
        case none = "Not Spicy"
        case mild = "Mild"
        case medium = "Medium"
        case hot = "Hot"
    }
    var spiceLevel: SpiceLevel = .none
} 