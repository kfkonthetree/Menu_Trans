import SwiftUI

struct CollectionPickerView: View {
    let dishInfo: DishInfo
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var collectionsManager: CollectionsManager
    @State private var showCreateCollection = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // 菜品信息预览
                VStack(spacing: 12) {
                    Text(NSLocalizedString("add_to_collection", comment: "Add to collection"))
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text(dishInfo.englishName)
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                
                if collectionsManager.collections.isEmpty {
                    // 空状态
                    VStack(spacing: 16) {
                        Image(systemName: "star.circle")
                            .font(.system(size: 60))
                            .foregroundColor(.gray.opacity(0.5))
                        
                        Text(NSLocalizedString("no_collections", comment: "No collections"))
                            .font(.title3)
                            .foregroundColor(.gray)
                        
                        Text(NSLocalizedString("please_create_collection", comment: "Please create collection first"))
                            .font(.body)
                            .foregroundColor(.gray.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // 收藏夹列表
                    List {
                        ForEach(collectionsManager.collections) { collection in
                            Button {
                                addToCollection(collection)
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(collection.name)
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        
                                        Text(collection.description)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                    }
                                    
                                    Spacer()
                                    
                                    Text(String(format: NSLocalizedString("dishes_count", comment: "Dishes count"), collection.dishes.count))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                }
                
                Spacer()
                
                // 创建新收藏夹按钮
                Button(NSLocalizedString("create_new_collection", comment: "Create new collection")) {
                    showCreateCollection = true
                }
                .buttonStyle(.borderedProminent)
                .padding()
            }
            .navigationTitle(NSLocalizedString("select_collection", comment: "Select collection"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(NSLocalizedString("cancel", comment: "Cancel button")) {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showCreateCollection) {
            CreateCollectionView { newCollection in
                collectionsManager.addCollection(newCollection)
            }
        }
    }
    
    private func addToCollection(_ collection: Collection) {
        collectionsManager.addDishToCollection(dishInfo, collectionId: collection.id)
        dismiss()
    }
} 