import SwiftUI

struct ReviewSkippedView: View {
    @Binding var skippedDishes: [DishInfo]
    @Binding var orderList: [DishInfo]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                if skippedDishes.isEmpty {
                    // 空状态
                    VStack(spacing: 20) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.green)
                        
                        Text(NSLocalizedString("no_skipped_dishes", comment: "No skipped dishes"))
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text(NSLocalizedString("all_dishes_processed", comment: "All dishes processed"))
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // 已跳过菜品列表
                    List {
                        ForEach(Array(skippedDishes.enumerated()), id: \.offset) { index, dish in
                            HStack(spacing: 12) {
                                // 菜品图片
                                AsyncImage(url: dish.imageURL) { phase in
                                    switch phase {
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                    case .failure(_):
                                        // 优雅的失败占位符
                                        ZStack {
                                            LinearGradient(
                                                gradient: Gradient(colors: [Color.orange.opacity(0.3), Color.pink.opacity(0.5)]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                            
                                            Image(systemName: "fork.knife.circle.fill")
                                                .font(.title3)
                                                .foregroundColor(.white.opacity(0.7))
                                        }
                                    case .empty:
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.gray.opacity(0.3))
                                    @unknown default:
                                        // 默认占位符
                                        ZStack {
                                            LinearGradient(
                                                gradient: Gradient(colors: [Color.orange.opacity(0.3), Color.pink.opacity(0.5)]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                            
                                            Image(systemName: "fork.knife.circle.fill")
                                                .font(.title3)
                                                .foregroundColor(.white.opacity(0.7))
                                        }
                                    }
                                }
                                .frame(width: 60, height: 60)
                                .clipped()
                                .cornerRadius(8)
                                
                                // 菜品信息
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(dish.englishName)
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                    
                                    if !dish.chineseName.isEmpty && dish.chineseName != dish.englishName {
                                        Text(dish.chineseName)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    if !dish.ingredients.isEmpty {
                                        Text("Ingredients: \(dish.ingredients.prefix(3).joined(separator: ", "))")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                    }
                                }
                                
                                Spacer()
                                
                                // 添加到订单按钮
                                Button(NSLocalizedString("add_to_order", comment: "Add to order button")) {
                                    addToOrder(dish: dish, at: index)
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.small)
                            }
                            .padding(.vertical, 4)
                            .background(
                                NavigationLink(destination: DishDetailView(dish: dish)) {
                                    EmptyView()
                                }
                                .opacity(0)
                            )
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle(NSLocalizedString("review_skipped_dishes", comment: "Review skipped dishes"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func addToOrder(dish: DishInfo, at index: Int) {
        // 检查是否已存在该菜品，防止重复添加
        if !orderList.contains(where: { $0.id == dish.id }) {
            orderList.append(dish)
        }
        
        // 从跳过列表中移除
        skippedDishes.remove(at: index)
    }
}

#Preview {
    ReviewSkippedView(
        skippedDishes: .constant([]),
        orderList: .constant([])
    )
} 