import SwiftUI

struct HistoryView: View {
    @ObservedObject var historyManager: HistoryManager
    @EnvironmentObject var collectionsManager: CollectionsManager
    @EnvironmentObject var orderManager: OrderManager
    @State private var selectedHistoryType = 1  // 默认显示点单记录
    
    var body: some View {
        NavigationView {
            VStack {
                // 分段选择器
                Picker("History Type", selection: $selectedHistoryType) {
                    Text(NSLocalizedString("scan_history", comment: "Scan history tab")).tag(0)
                    Text(NSLocalizedString("order_history", comment: "Order history tab")).tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                if selectedHistoryType == 0 {
                    // 识别记录
                    if historyManager.historyItems.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 60))
                                .foregroundColor(.gray.opacity(0.5))
                            
                            Text(NSLocalizedString("no_scan_history", comment: "No scan history"))
                                .font(.title2)
                                .foregroundColor(.gray)
                            
                            Text(NSLocalizedString("scan_history_description", comment: "Scan history description"))
                                .font(.body)
                                .foregroundColor(.gray.opacity(0.7))
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(historyManager.historyItems) { item in
                                    NavigationLink(destination: DishDetailView(dish: DishInfo(
                                        chineseName: item.chineseName ?? "",
                                        englishName: item.englishName,
                                        pinyinName: item.pinyinName,
                                        ingredients: item.ingredients,
                                        cookingMethod: item.cookingMethod,
                                        flavorTags: item.flavorTags,
                                        imageURL: nil
                                    ))) {
                                        HistoryCardView(
                                        dishInfo: DishInfo(
                                            chineseName: item.chineseName ?? "",
                                            englishName: item.englishName,
                                            pinyinName: item.pinyinName,
                                            ingredients: item.ingredients,
                                            cookingMethod: item.cookingMethod,
                                            flavorTags: item.flavorTags,
                                            imageURL: nil
                                        ),
                                        searchType: item.searchType,
                                        timestamp: item.timestamp
                                    )
                                    .environmentObject(collectionsManager)
                                    .swipeActions(edge: .trailing) {
                                        Button {
                                            // 收藏功能（暂时为空）
                                        } label: {
                                            Label(NSLocalizedString("favorite", comment: "Favorite action"), systemImage: "star.fill")
                                        }
                                        .tint(.yellow)
                                        
                                        Button(NSLocalizedString("delete", comment: "Delete action"), role: .destructive) {
                                            historyManager.removeHistoryItem(item)
                                        }
                                    }
                                }
                            }
                        }
                            .padding()
                        }
                    }
                } else {
                    // 点单记录
                    if orderManager.orders.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "list.bullet.clipboard")
                                .font(.system(size: 60))
                                .foregroundColor(.gray.opacity(0.5))
                            
                            Text(NSLocalizedString("no_order_history", comment: "No order history"))
                                .font(.title2)
                                .foregroundColor(.gray)
                            
                            Text(NSLocalizedString("order_history_description", comment: "Order history description"))
                                .font(.body)
                                .foregroundColor(.gray.opacity(0.7))
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        List {
                            ForEach(orderManager.orders) { order in
                                NavigationLink(destination: OrderHistoryDetailView(orderList: order.items)) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text(formatDate(order.date))
                                                .font(.headline)
                                                .fontWeight(.semibold)
                                            
                                            Text(String(format: NSLocalizedString("dishes_count_format", comment: "Dishes count format"), order.items.count))
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                            
                                            // 显示前几个菜品名称
                                            if !order.items.isEmpty {
                                                Text(order.items.prefix(3).map { $0.chineseName.isEmpty ? $0.englishName : $0.chineseName }.joined(separator: "、"))
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                                    .lineLimit(1)
                                            }
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                            .onDelete(perform: deleteOrders)
                        }
                        .listStyle(PlainListStyle())
                    }
                }
            }
            .navigationTitle(NSLocalizedString("history_title", comment: "History title"))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if selectedHistoryType == 0 && !historyManager.historyItems.isEmpty {
                        Button(NSLocalizedString("clear_all", comment: "Clear all button")) {
                            historyManager.clearHistory()
                        }
                        .foregroundColor(.red)
                    } else if selectedHistoryType == 1 && !orderManager.orders.isEmpty {
                        Button(NSLocalizedString("clear_all", comment: "Clear all button")) {
                            orderManager.clearOrders()
                        }
                        .foregroundColor(.red)
                    }
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
    
    private func deleteOrders(offsets: IndexSet) {
        orderManager.clearOrders()
    }
}

 
 