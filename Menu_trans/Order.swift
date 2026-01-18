import Foundation

struct Order: Identifiable, Codable {
    let id: UUID
    let date: Date
    let items: [DishInfo]
    
    init(items: [DishInfo]) {
        self.id = UUID()
        self.date = Date()
        self.items = items
    }
}

class OrderManager: ObservableObject {
    @Published var orders: [Order] = []
    private let userDefaults = UserDefaults.standard
    private let ordersKey = "SavedOrders"
    
    init() {
        loadOrders()
    }
    
    func addOrder(_ order: Order) {
        orders.insert(order, at: 0) // 添加到开头
        saveOrders()
    }
    
    func clearOrders() {
        orders.removeAll()
        saveOrders()
    }
    
    private func saveOrders() {
        if let encoded = try? JSONEncoder().encode(orders) {
            userDefaults.set(encoded, forKey: ordersKey)
        }
    }
    
    private func loadOrders() {
        if let data = userDefaults.data(forKey: ordersKey),
           let decoded = try? JSONDecoder().decode([Order].self, from: data) {
            orders = decoded
        }
    }
}
