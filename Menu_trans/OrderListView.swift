import SwiftUI

struct OrderListView: View {
    @Binding var orderList: [DishInfo]
    @Binding var skippedDishes: [DishInfo]

    @EnvironmentObject var orderManager: OrderManager
    @Environment(\.dismiss) private var dismiss
    @State private var showReviewSkipped = false
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部标题
            VStack(spacing: 16) {
                Text("你好，我们想点以下菜品：")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 20)
                
                Text(String(format: NSLocalizedString("total_dishes_selected", comment: "Total dishes selected"), orderList.count))
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
            
            // 菜品列表
            List {
                ForEach(Array(orderList.enumerated()), id: \.offset) { index, dish in
                    NavigationLink(destination: DishDetailView(dish: dish)) {
                        HStack {
                            // 菜品名称
                            VStack(alignment: .leading, spacing: 4) {
                                Text(dish.chineseName.isEmpty ? dish.englishName : dish.chineseName)
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .lineLimit(2)
                                
                                // 英文名（如果中文名不为空）
                                if !dish.chineseName.isEmpty && dish.chineseName != dish.englishName {
                                    Text(dish.englishName)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                                
                                // 食材预览
                                if !dish.ingredients.isEmpty {
                                    Text("食材: \(dish.ingredients.prefix(3).joined(separator: ", "))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                            }
                            
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    }
                }
                .onDelete(perform: deleteOrderItem)
            }
            .listStyle(PlainListStyle())
            
            // 底部操作区域
            VStack(spacing: 12) {
                Divider()
                
                Button(NSLocalizedString("complete_order_button", comment: "Complete order button")) {
                    // 直接使用 orderList 作为 DishInfo 数组
                    let newOrder = Order(items: orderList)
                    orderManager.addOrder(newOrder)
                    // 直接关闭模态视图，返回主界面
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)
            }
            .padding()
        }
        .navigationTitle(NSLocalizedString("order_list", comment: "Order list title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(NSLocalizedString("back_to_select", comment: "Back to select")) {
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(NSLocalizedString("review_skipped", comment: "Review skipped")) {
                    showReviewSkipped = true
                }
            }
        }
        .sheet(isPresented: $showReviewSkipped) {
            ReviewSkippedView(skippedDishes: $skippedDishes, orderList: $orderList)
        }

    }
    
    private func deleteOrderItem(at offsets: IndexSet) {
        for index in offsets {
            if index < orderList.count {
                // 将删除的菜品回收到跳过列表
                let removedDish = orderList.remove(at: index)
                skippedDishes.append(removedDish)
            }
        }
    }
} 