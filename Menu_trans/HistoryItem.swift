import Foundation

struct HistoryItem: Identifiable, Codable {
    var id = UUID()
    let dishName: String
    let englishName: String
    let chineseName: String?
    let pinyinName: String?
    let ingredients: [String]
    let cookingMethod: String
    let flavorTags: [String]
    let timestamp: Date
    let searchType: SearchType
    
    enum SearchType: String, Codable, CaseIterable {
        case image = "image_scan"
        case manual = "manual_input"
    }
    
    init(dishInfo: DishInfo, searchType: SearchType, originalName: String? = nil) {
        self.dishName = originalName ?? dishInfo.englishName
        self.englishName = dishInfo.englishName
        self.chineseName = dishInfo.chineseName
        self.pinyinName = dishInfo.pinyinName
        self.ingredients = dishInfo.ingredients
        self.cookingMethod = dishInfo.cookingMethod
        self.flavorTags = dishInfo.flavorTags
        self.timestamp = Date()
        self.searchType = searchType
    }
}

class HistoryManager: ObservableObject {
    @Published var historyItems: [HistoryItem] = []
    private let userDefaults = UserDefaults.standard
    private let historyKey = "SearchHistory"
    
    init() {
        loadHistory()
    }
    
    func addToHistory(_ dishInfo: DishInfo, searchType: HistoryItem.SearchType, originalName: String? = nil) {
        let historyItem = HistoryItem(dishInfo: dishInfo, searchType: searchType, originalName: originalName)
        historyItems.insert(historyItem, at: 0) // 添加到开头
        
        // 限制历史记录数量为50条
        if historyItems.count > 50 {
            historyItems = Array(historyItems.prefix(50))
        }
        
        saveHistory()
    }
    
    func clearHistory() {
        historyItems.removeAll()
        saveHistory()
    }
    
    func removeHistoryItem(_ item: HistoryItem) {
        historyItems.removeAll { $0.id == item.id }
        saveHistory()
    }
    
    private func saveHistory() {
        if let encoded = try? JSONEncoder().encode(historyItems) {
            userDefaults.set(encoded, forKey: historyKey)
        }
    }
    
    private func loadHistory() {
        if let data = userDefaults.data(forKey: historyKey),
           let decoded = try? JSONDecoder().decode([HistoryItem].self, from: data) {
            historyItems = decoded
        }
    }
} 