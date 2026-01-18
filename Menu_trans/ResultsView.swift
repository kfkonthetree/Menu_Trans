import SwiftUI

struct ResultsView: View {
    let dishes: [DishInfo]
    @Binding var orderList: [DishInfo]
    @Binding var skippedDishes: [DishInfo]
    let collectionsManager: CollectionsManager
    @Environment(\.dismiss) private var dismiss
    @State private var currentIndex = 0
    @State private var dragOffset = CGSize.zero
    @State private var showOrderList = false
    @State private var showCollectionPicker = false
    @State private var isSelectionFinished = false
    @State private var showFilterOptions = false
    @State private var filterMode: FilterMode = .all
    
    enum FilterMode: String, CaseIterable {
        case all = "Show All"
        case safeOnly = "Safe Dishes Only"
        case preferences = "My Preferences"
    }
    
    var filteredDishes: [DishInfo] {
        switch filterMode {
        case .all:
            return dishes
        case .safeOnly:
            return dishes.filter { $0.dietaryAnalysis?.isSafe ?? true }
        case .preferences:
            return dishes.filter { $0.dietaryAnalysis?.preferenceMatch ?? false }
        }
    }
    
    var body: some View {
        ZStack {
            // 背景
            Color(.systemBackground)
            
            VStack {
                // 顶部留白
                Spacer()
                    .frame(height: 60)
                
                if currentIndex < filteredDishes.count {
                    // 当前卡片
                    DishCardView(
                        dish: filteredDishes[currentIndex],
                        dragOffset: $dragOffset,
                        onSwipeRight: {
                            addToOrderList()
                        },
                        onSwipeLeft: {
                            skipDish()
                        },
                        collectionsManager: collectionsManager
                    )
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                dragOffset = value.translation
                            }
                            .onEnded { value in
                                handleSwipe(value)
                            }
                    )
                } else {
                    // 所有卡片都已处理完毕 - 显示空状态
                    VStack(spacing: 20) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.green)
                        
                        Text(NSLocalizedString("all_dishes_reviewed", comment: "All dishes reviewed"))
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text(NSLocalizedString("tap_list_to_see_order", comment: "Tap list to see order"))
                            .font(.title3)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                
                // 进度显示
                if filteredDishes.count > 0 {
                    Text("\(currentIndex + 1) / \(filteredDishes.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 10)
                }
                
                Spacer()
                
                // 五键底部操作栏
                HStack {
                    // 按钮 1: 返回
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "arrow.uturn.left.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    // 按钮 2: 收藏
                    Button {
                        if currentIndex < filteredDishes.count {
                            showCollectionPicker = true
                        }
                    } label: {
                        Image(systemName: "star.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.yellow)
                    }
                    .disabled(currentIndex >= filteredDishes.count)
                    
                    Spacer()
                    
                    // 按钮 3: 不喜欢
                    Button {
                        skipDish()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.red)
                    }
                    .disabled(currentIndex >= filteredDishes.count)
                    
                    Spacer()
                    
                    // 按钮 4: 喜欢
                    Button {
                        addToOrderList()
                    } label: {
                        Image(systemName: "heart.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.green)
                    }
                    .disabled(currentIndex >= filteredDishes.count)
                    
                    Spacer()
                    
                    // 按钮 5: 查看订单
                    Button {
                        showOrderList = true
                    } label: {
                        Image(systemName: "menucard.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.blue)
                    }
                    .disabled(orderList.isEmpty)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
            .padding(.horizontal)
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showFilterOptions = true
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .font(.title2)
                }
            }
        }
        .sheet(isPresented: $showOrderList) {
            NavigationView {
                OrderListView(orderList: $orderList, skippedDishes: $skippedDishes)
            }
        }
        .sheet(isPresented: $showCollectionPicker) {
            if currentIndex < filteredDishes.count {
                CollectionPickerView(dishInfo: filteredDishes[currentIndex])
                    .environmentObject(collectionsManager)
            }
        }
        .onChange(of: currentIndex) { _, newIndex in
            // 当所有卡片都被处理完毕时，自动弹出订单列表
            if newIndex >= filteredDishes.count {
                isSelectionFinished = true
            }
        }
        .fullScreenCover(isPresented: $isSelectionFinished) {
            NavigationView {
                OrderListView(orderList: $orderList, skippedDishes: $skippedDishes)
            }
        }
        .confirmationDialog("Filter Options", isPresented: $showFilterOptions) {
            ForEach(FilterMode.allCases, id: \.self) { mode in
                Button(mode.rawValue) {
                    filterMode = mode
                    currentIndex = 0 // 重置到第一个，但只在有卡片时
                }
            }
            Button("Cancel", role: .cancel) { }
        }
    }
    
    private func handleSwipe(_ value: DragGesture.Value) {
        let threshold: CGFloat = 100
        let velocity = value.predictedEndTranslation.width - value.translation.width
        
        if value.translation.width > threshold || velocity > 500 {
            // 向右滑动 - 添加到订单
            withAnimation(.easeOut(duration: 0.3)) {
                dragOffset = CGSize(width: 500, height: 0)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                addToOrderList()
            }
        } else if value.translation.width < -threshold || velocity < -500 {
            // 向左滑动 - 跳过
            withAnimation(.easeOut(duration: 0.3)) {
                dragOffset = CGSize(width: -500, height: 0)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                skipDish()
            }
        } else {
            // 回到原位
            withAnimation(.spring()) {
                dragOffset = .zero
            }
        }
    }
    
    private func addToOrderList() {
        if currentIndex < filteredDishes.count {
            let currentDish = filteredDishes[currentIndex]
            
            // 检查是否已存在该菜品，防止重复添加
            if !orderList.contains(where: { $0.id == currentDish.id }) {
                orderList.append(currentDish)
            }
        }
        nextCard()
    }
    
    private func skipDish() {
        if currentIndex < filteredDishes.count {
            // 将跳过的菜品添加到 skippedDishes 数组
            skippedDishes.append(filteredDishes[currentIndex])
        }
        nextCard()
    }
    
    private func nextCard() {
        currentIndex += 1
        dragOffset = .zero
        
        // 移除重置逻辑，让流程自然结束
        // 当 currentIndex >= filteredDishes.count 时，会显示空状态
    }
}

struct DishCardView: View {
    let dish: DishInfo
    @Binding var dragOffset: CGSize
    let onSwipeRight: () -> Void
    let onSwipeLeft: () -> Void
    let collectionsManager: CollectionsManager
    
    var body: some View {
        VStack(spacing: 0) {
            // 卡片内容
            VStack(spacing: 20) {
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
                                .font(.largeTitle)
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
                                .font(.largeTitle)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                }
                .frame(height: 200)
                .clipped()
                .cornerRadius(20)
                
                // 菜品信息
                VStack(spacing: 12) {
                    // 警告横幅（如果不安全）
                    if let analysis = dish.dietaryAnalysis, !analysis.isSafe {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text("⚠️ Safety Warning")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.red)
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                        
                        if let reason = analysis.conflictReason {
                            Text(reason)
                                .font(.caption)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.leading)
                                .padding(.horizontal, 12)
                        }
                    }
                    
                    // 主标题：英文名
                    HStack {
                        Text(dish.englishName)
                            .font(.title)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        
                        // 推荐图标（如果匹配偏好）
                        if let analysis = dish.dietaryAnalysis, analysis.preferenceMatch {
                            Image(systemName: "hand.thumbsup.fill")
                                .foregroundColor(.green)
                                .font(.title2)
                        }
                    }
                    
                    // 拼音显示
                    if let pinyin = dish.pinyinName, !pinyin.isEmpty {
                        Text(pinyin)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    // 副标题：中文名
                    if !dish.chineseName.isEmpty && dish.chineseName != dish.englishName {
                        Text(dish.chineseName)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    // 食材信息
                    if !dish.ingredients.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Ingredients:")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text(dish.ingredients.joined(separator: ", "))
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.leading)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    // 烹饪方式
                    if !dish.cookingMethod.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Cooking Style:")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text(dish.cookingMethod)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.leading)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    // 口味标签
                    if !dish.flavorTags.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Flavor Profile:")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            HStack(spacing: 8) {
                                ForEach(dish.flavorTags, id: \.self) { tag in
                                    Text(tag)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(
                                            Capsule()
                                                .fill(Color.blue)
                                        )
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    // 匹配分数显示
                    if let analysis = dish.dietaryAnalysis {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Match Score:")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Text("\(analysis.matchScore)/100")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(analysis.matchScore >= 70 ? .green : analysis.matchScore >= 40 ? .orange : .red)
                            }
                            
                            // 进度条
                            ProgressView(value: Double(analysis.matchScore), total: 100)
                                .progressViewStyle(LinearProgressViewStyle(tint: analysis.matchScore >= 70 ? .green : analysis.matchScore >= 40 ? .orange : .red))
                            
                            if let reason = analysis.matchReason {
                                Text(reason)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.leading)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
        .padding(.horizontal, 20)
        .offset(dragOffset)
        .rotationEffect(.degrees(Double(dragOffset.width / 20)))
        .scaleEffect(1.0 - abs(dragOffset.width) / 1000)
        .overlay(
            // 滑动提示
            Group {
                if dragOffset.width > 50 {
                    Text(NSLocalizedString("like", comment: "Like action"))
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                        .padding()
                        .background(Color.green.opacity(0.2))
                        .cornerRadius(10)
                        .rotationEffect(.degrees(-15))
                        .offset(x: 50, y: -100)
                } else if dragOffset.width < -50 {
                    Text(NSLocalizedString("nope", comment: "Nope action"))
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                        .padding()
                        .background(Color.red.opacity(0.2))
                        .cornerRadius(10)
                        .rotationEffect(.degrees(15))
                        .offset(x: -50, y: -100)
                }
            }
        )
    }
} 