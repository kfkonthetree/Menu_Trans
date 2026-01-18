import SwiftUI

struct CollectionsView: View {
    @ObservedObject var collectionsManager: CollectionsManager
    @State private var showCreateCollection = false
    @State private var showRenameAlert = false
    @State private var showDeleteAlert = false
    @State private var selectedCollection: Collection?
    @State private var newCollectionName = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                if collectionsManager.collections.isEmpty {
                    // 空状态
                    VStack(spacing: 20) {
                        Image(systemName: "star.circle")
                            .font(.system(size: 80))
                            .foregroundColor(.gray.opacity(0.5))
                        
                        Text(NSLocalizedString("no_collections", comment: "No collections"))
                            .font(.title2)
                            .foregroundColor(.gray)
                        
                        Text(NSLocalizedString("collections_description", comment: "Collections description"))
                            .font(.body)
                            .foregroundColor(.gray.opacity(0.7))
                            .multilineTextAlignment(.center)
                        
                        Button(NSLocalizedString("create_collection", comment: "Create collection button")) {
                            showCreateCollection = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                } else {
                    // 收藏夹网格
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        ForEach(collectionsManager.collections) { collection in
                            NavigationLink(destination: CollectionDetailView(collection: collection)) {
                                CollectionCardView(collection: collection)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .contextMenu {
                                Button(NSLocalizedString("rename", comment: "Rename collection")) {
                                    selectedCollection = collection
                                    newCollectionName = collection.name
                                    showRenameAlert = true
                                }
                                
                                Button(NSLocalizedString("delete", comment: "Delete collection"), role: .destructive) {
                                    selectedCollection = collection
                                    showDeleteAlert = true
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle(NSLocalizedString("collections", comment: "Collections title"))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showCreateCollection = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.title2)
                    }
                }
            }
        }
        .sheet(isPresented: $showCreateCollection) {
            CreateCollectionView { newCollection in
                collectionsManager.addCollection(newCollection)
            }
        }
        .alert(NSLocalizedString("rename", comment: "Rename collection"), isPresented: $showRenameAlert) {
            TextField(NSLocalizedString("collection_name", comment: "Collection name"), text: $newCollectionName)
            Button(NSLocalizedString("cancel", comment: "Cancel")) {
                showRenameAlert = false
            }
            Button(NSLocalizedString("ok", comment: "OK")) {
                if let collection = selectedCollection {
                    collectionsManager.renameCollection(collection.id, newName: newCollectionName)
                }
                showRenameAlert = false
            }
        } message: {
            Text(NSLocalizedString("enter_new_name", comment: "Enter new name"))
        }
        .alert(NSLocalizedString("confirm_delete", comment: "Confirm delete"), isPresented: $showDeleteAlert) {
            Button(NSLocalizedString("cancel", comment: "Cancel"), role: .cancel) {
                showDeleteAlert = false
            }
            Button(NSLocalizedString("delete", comment: "Delete"), role: .destructive) {
                if let collection = selectedCollection {
                    collectionsManager.deleteCollection(collection.id)
                }
                showDeleteAlert = false
            }
        } message: {
            Text(NSLocalizedString("delete_collection_message", comment: "Delete collection message"))
        }
    }
}

struct Collection: Identifiable, Codable {
    var id = UUID()
    var name: String
    var description: String
    var dishes: [DishInfo]
    var createdAt: Date
    
    init(name: String, description: String) {
        self.name = name
        self.description = description
        self.dishes = []
        self.createdAt = Date()
    }
}

struct CollectionCardView: View {
    let collection: Collection
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 封面图片
            ZStack {
                Rectangle()
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
                    .frame(height: 120)
                    .cornerRadius(12)
                
                if collection.dishes.isEmpty {
                    Image(systemName: "star.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                } else {
                    // 这里可以显示菜品图片的拼接
                    Text(String(format: NSLocalizedString("dishes_count", comment: "Dishes count"), collection.dishes.count))
                        .font(.headline)
                        .foregroundColor(.white)
                        .fontWeight(.semibold)
                }
            }
            
            // 收藏夹信息
            VStack(alignment: .leading, spacing: 4) {
                Text(collection.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                
                Text(collection.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                Text(String(format: NSLocalizedString("created_on", comment: "Created on date"), formatDate(collection.createdAt)))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: date)
    }
}

struct CreateCollectionView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var description = ""
    let onSave: (Collection) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section(NSLocalizedString("collection_info", comment: "Collection info section")) {
                    TextField(NSLocalizedString("collection_name", comment: "Collection name placeholder"), text: $name)
                    TextField(NSLocalizedString("description_optional", comment: "Description optional placeholder"), text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle(NSLocalizedString("create_new_collection", comment: "Create new collection title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(NSLocalizedString("cancel", comment: "Cancel button")) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(NSLocalizedString("create", comment: "Create button")) {
                        let newCollection = Collection(name: name, description: description)
                        onSave(newCollection)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
} 