import Foundation

class CollectionsManager: ObservableObject {
    @Published var collections: [Collection] = []
    
    init() {
        loadCollections()
    }
    
    func addCollection(_ collection: Collection) {
        collections.append(collection)
        saveCollections()
    }
    
    func addDishToCollection(_ dish: DishInfo, collectionId: UUID) {
        if let index = collections.firstIndex(where: { $0.id == collectionId }) {
            collections[index].dishes.append(dish)
            saveCollections()
        }
    }
    
    func renameCollection(_ collectionId: UUID, newName: String) {
        if let index = collections.firstIndex(where: { $0.id == collectionId }) {
            collections[index].name = newName
            saveCollections()
        }
    }
    
    func deleteCollection(_ collectionId: UUID) {
        collections.removeAll { $0.id == collectionId }
        saveCollections()
    }
    
    func removeDishFromCollection(_ collectionId: UUID, dishIndex: Int) {
        if let collectionIndex = collections.firstIndex(where: { $0.id == collectionId }) {
            if dishIndex < collections[collectionIndex].dishes.count {
                collections[collectionIndex].dishes.remove(at: dishIndex)
                saveCollections()
            }
        }
    }
    
    private func saveCollections() {
        if let encoded = try? JSONEncoder().encode(collections) {
            UserDefaults.standard.set(encoded, forKey: "savedCollections")
        }
    }
    
    private func loadCollections() {
        if let data = UserDefaults.standard.data(forKey: "savedCollections"),
           let decoded = try? JSONDecoder().decode([Collection].self, from: data) {
            collections = decoded
        }
    }
} 