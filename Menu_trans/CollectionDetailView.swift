import SwiftUI

struct CollectionDetailView: View {
    let collection: Collection
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var collectionsManager: CollectionsManager
    @State private var isEditing = false
    
    var body: some View {
        VStack {
            if collection.dishes.isEmpty {
                // 空状态
                VStack(spacing: 20) {
                    Image(systemName: "star.circle")
                        .font(.system(size: 80))
                        .foregroundColor(.gray.opacity(0.5))
                    
                    Text(NSLocalizedString("no_dishes_in_collection", comment: "No dishes in collection"))
                        .font(.title2)
                        .foregroundColor(.gray)
                    
                    Text(NSLocalizedString("add_dishes_to_collection", comment: "Add dishes to collection"))
                        .font(.body)
                        .foregroundColor(.gray.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // 菜品列表
                List {
                    ForEach(Array(collection.dishes.enumerated()), id: \.offset) { index, dish in
                        NavigationLink(destination: DishDetailView(dish: dish)) {
                            VStack(alignment: .leading, spacing: 8) {
                            // 菜品名称
                            VStack(alignment: .leading, spacing: 4) {
                                Text(dish.englishName)
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .lineLimit(2)
                                
                                if let pinyin = dish.pinyinName, !pinyin.isEmpty {
                                    Text(pinyin)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                                
                                if !dish.chineseName.isEmpty {
                                    Text(dish.chineseName)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                            }
                            
                            // 食材预览
                            if !dish.ingredients.isEmpty {
                                Text(String(format: NSLocalizedString("ingredients", comment: "Ingredients label"), dish.ingredients.prefix(3).joined(separator: ", ")))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                            
                            // 烹饪方式
                            if !dish.cookingMethod.isEmpty {
                                Text("Cooking: \(dish.cookingMethod)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                            }
                            
                            // 口味标签
                            if !dish.flavorTags.isEmpty {
                                HStack(spacing: 4) {
                                    ForEach(dish.flavorTags.prefix(2), id: \.self) { tag in
                                        Text(tag)
                                            .font(.caption2)
                                            .fontWeight(.medium)
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(
                                                Capsule()
                                                    .fill(Color.blue)
                                            )
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                    .onDelete(perform: deleteItems)
                }
                .listStyle(PlainListStyle())
            }
        }
        .navigationTitle(collection.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            if !collection.dishes.isEmpty {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                        .environment(\.editMode, .constant(isEditing ? .active : .inactive))
                }
            }
        }
    }
    
    private func deleteItems(offsets: IndexSet) {
        for index in offsets {
            collectionsManager.removeDishFromCollection(collection.id, dishIndex: index)
        }
    }
} 