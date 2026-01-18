import Foundation
import SwiftUI

struct DietaryAnalysis: Codable, Hashable {
    var isSafe: Bool
    var conflictReason: String?
    var preferenceMatch: Bool
    var matchReason: String?
    var matchScore: Int
}

struct DishInfo: Codable, Identifiable, Hashable {
    var id = UUID()
    var chineseName: String
    var englishName: String
    var pinyinName: String?     // 存储拼音
    var ingredients: [String]   // 存储英文食材
    var cookingMethod: String   // 存储英文烹饪方法
    var flavorTags: [String]    // 存储英文口味标签
    var imageURL: Foundation.URL?
    var dietaryAnalysis: DietaryAnalysis?

    // Codable 需要的 key 映射，确保 id 和 imageURL 不参与 AI 的 JSON 解析
    enum CodingKeys: String, CodingKey {
        case chineseName, englishName, pinyinName, ingredients, cookingMethod, flavorTags, dietaryAnalysis
    }
    
    init(chineseName: String, englishName: String, pinyinName: String? = nil, ingredients: [String], cookingMethod: String, flavorTags: [String], imageURL: Foundation.URL? = nil, dietaryAnalysis: DietaryAnalysis? = nil) {
        self.chineseName = chineseName
        self.englishName = englishName
        self.pinyinName = pinyinName
        self.ingredients = ingredients
        self.cookingMethod = cookingMethod
        self.flavorTags = flavorTags
        self.imageURL = imageURL
        self.dietaryAnalysis = dietaryAnalysis
    }
} 