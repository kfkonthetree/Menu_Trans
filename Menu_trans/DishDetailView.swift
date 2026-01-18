import SwiftUI

struct DishDetailView: View {
    let dish: DishInfo
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
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
                                .font(.system(size: 60))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    case .empty:
                        // 加载中的占位符
                        ZStack {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.orange.opacity(0.3),
                                            Color.pink.opacity(0.3)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            
                            VStack(spacing: 12) {
                                ProgressView()
                                    .scaleEffect(1.5)
                                    .foregroundColor(.white)
                                
                                Text("Loading image...")
                                    .font(.caption)
                                    .foregroundColor(.white)
                            }
                        }
                    @unknown default:
                        // 默认占位符
                        ZStack {
                            LinearGradient(
                                gradient: Gradient(colors: [Color.orange.opacity(0.3), Color.pink.opacity(0.5)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            
                            Image(systemName: "fork.knife.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                }
                .frame(height: 250)
                .clipped()
                .cornerRadius(20)
                
                // 菜品信息
                VStack(spacing: 16) {
                    // 主标题：英文名
                    Text(dish.englishName)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    // 拼音显示
                    if let pinyin = dish.pinyinName, !pinyin.isEmpty {
                        Text(pinyin)
                            .font(.title3)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    // 副标题：中文名
                    if !dish.chineseName.isEmpty && dish.chineseName != dish.englishName {
                        Text(dish.chineseName)
                            .font(.title2)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    // 食材信息
                    if !dish.ingredients.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Ingredients:")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            Text(dish.ingredients.joined(separator: ", "))
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.leading)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                    }
                    
                    // 烹饪方式
                    if !dish.cookingMethod.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Cooking Style:")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            Text(dish.cookingMethod)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.leading)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                    }
                    
                    // 口味标签
                    if !dish.flavorTags.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Flavor Profile:")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            HStack(spacing: 8) {
                                ForEach(dish.flavorTags, id: \.self) { tag in
                                    Text(tag)
                                        .font(.body)
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(
                                            Capsule()
                                                .fill(Color.blue)
                                        )
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("菜品详情")
        .navigationBarTitleDisplayMode(.inline)
    }
} 