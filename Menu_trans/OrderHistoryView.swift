import SwiftUI

struct OrderHistoryView: View {
    @ObservedObject var orderManager: OrderManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                if orderManager.orders.isEmpty {
                    // 空状态
                    VStack(spacing: 20) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 80))
                            .foregroundColor(.gray.opacity(0.5))
                        
                        Text("暂无订单历史")
                            .font(.title2)
                            .foregroundColor(.gray)
                        
                        Text("您的订单记录将显示在这里")
                            .font(.body)
                            .foregroundColor(.gray.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // 订单列表
                    List {
                        ForEach(orderManager.orders) { order in
                            NavigationLink(destination: OrderHistoryDetailView(orderList: order.items)) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(formatDate(order.date))
                                            .font(.headline)
                                            .fontWeight(.semibold)
                                        
                                        Text("共 \(order.items.count) 道菜")
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
            .navigationTitle("订单历史")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("关闭") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !orderManager.orders.isEmpty {
                        Button("清空") {
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
        // 这里可以添加删除逻辑，暂时先清空所有订单
        orderManager.clearOrders()
    }
}
