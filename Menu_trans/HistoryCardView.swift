import SwiftUI

struct HistoryCardView: View {
    let dishInfo: DishInfo
    let searchType: HistoryItem.SearchType
    let timestamp: Date
    @State private var showCollectionPicker = false
    @EnvironmentObject var collectionsManager: CollectionsManager
    
    var body: some View {
        HStack(spacing: 16) {
            // 左侧图片
            AsyncImage(url: dishInfo.imageURL) { phase in
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
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.7))
                    }
                case .empty:
                    ProgressView()
                        .frame(width: 60, height: 60)
                @unknown default:
                    // 默认占位符
                    ZStack {
                        LinearGradient(
                            gradient: Gradient(colors: [Color.orange.opacity(0.3), Color.pink.opacity(0.5)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        
                        Image(systemName: "fork.knife.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
            .frame(width: 60, height: 60)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
            .clipped()
            
            // 右侧内容
            VStack(alignment: .leading, spacing: 8) {
                // 菜品名称
                VStack(alignment: .leading, spacing: 4) {
                    Text(dishInfo.englishName)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                    
                    // 搜索类型和时间
                    HStack {
                        Label(NSLocalizedString(searchType.rawValue, comment: "Search type"), systemImage: searchTypeIcon)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(formatDate(timestamp))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // 食材预览
                if !dishInfo.ingredients.isEmpty {
                    Text(String(format: NSLocalizedString("ingredients", comment: "Ingredients label"), dishInfo.ingredients.prefix(3).joined(separator: ", ")))
                        .font(.caption)
                        .foregroundColor(.blue)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // 收藏按钮
            Button {
                showCollectionPicker = true
            } label: {
                Image(systemName: "star")
                    .font(.title2)
                    .foregroundColor(.yellow)
                    .padding(8)
                    .background(Color.yellow.opacity(0.1))
                    .clipShape(Circle())
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
        .sheet(isPresented: $showCollectionPicker) {
            CollectionPickerView(dishInfo: dishInfo)
                .environmentObject(collectionsManager)
        }
    }
    
    private var searchTypeIcon: String {
        switch searchType {
        case .image:
            return "camera.fill"
        case .manual:
            return "keyboard"
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: date)
    }
} 