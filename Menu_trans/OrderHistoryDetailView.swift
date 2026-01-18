import SwiftUI

struct OrderHistoryDetailView: View {
    let orderList: [DishInfo]
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部标题
            VStack(spacing: 16) {
                Text(NSLocalizedString("order_detail_title", comment: "Order detail title"))
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 20)
                
                Text(String(format: NSLocalizedString("total_dishes_summary", comment: "Total dishes summary"), orderList.count))
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
                            
                            // 数量显示（固定为1）
                            Text("1")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .frame(minWidth: 30)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .listStyle(PlainListStyle())
            
            Spacer()
        }
        .navigationTitle(NSLocalizedString("order_detail_title", comment: "Order detail title"))
        .navigationBarTitleDisplayMode(.inline)
    }
}
