//
//  ContentView.swift
//  Menu_trans
//
//  Created by 谢甲腾 on 2025/7/19.
//

import SwiftUI
import PhotosUI
import Vision

struct ContentView: View {
    @State private var recognizedText: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var results: [DishInfo] = []
    @State private var showTextInput = false
    @State private var showResults = false
    @State private var orderList: [DishInfo] = []
    @State private var skippedDishes: [DishInfo] = []
    @State private var scannedImage: UIImage?
    @State private var showScanner = false
    @State private var showScanOptions = false
    @State private var showPhotosPicker = false
    @StateObject private var historyManager = HistoryManager()
    @StateObject private var progressManager = ProgressManager()
    @EnvironmentObject var collectionsManager: CollectionsManager
    @EnvironmentObject var orderManager: OrderManager
    @EnvironmentObject var userSettings: UserSettings

    var body: some View {
        ZStack {
            // 渐变背景
            RadialGradient(
                gradient: Gradient(colors: [
                    Color.blue.opacity(0.2),
                    Color(UIColor.systemBackground)
                ]),
                center: .center,
                startRadius: 0,
                endRadius: 400
            )
            .ignoresSafeArea()
            
            // 主布局
            VStack {
                // 顶部标题栏
                HStack {
                    Label(NSLocalizedString("app_title", comment: "App title"), systemImage: "fork.knife.circle.fill")
                        .font(.title)
                        .bold()
                    
                    Spacer()
                }
                .padding()
                
                Spacer()
                
                // 视觉核心区
                VStack(spacing: 20) {
                    Text(NSLocalizedString("scan_menu_title", comment: "Scan menu title"))
                        .font(.largeTitle)
                        .bold()
                    
                    Text(NSLocalizedString("scan_menu_subtitle", comment: "Scan menu subtitle"))
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .padding()
                
                // 核心扫描按钮 - 巨大的圆形按钮
                Button {
                    showScanOptions = true
                } label: {
                    VStack(spacing: 12) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                        
                        Text(NSLocalizedString("start_scanning", comment: "Start scanning button"))
                            .font(.title2)
                            .bold()
                            .foregroundColor(.white)
                    }
                    .frame(width: 180, height: 180)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(Circle())
                    .shadow(color: .blue.opacity(0.4), radius: 15, y: 5)
                }
                .scaleEffect(showScanOptions ? 0.95 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: showScanOptions)
                
                Spacer()
                
                // 次要操作入口
                Button {
                    showTextInput = true
                } label: {
                    Text(NSLocalizedString("manual_search_prompt", comment: "Manual search prompt"))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom)
            }
            

            
            // 文本输入界面
            if showTextInput {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        showTextInput = false
                    }
                
                VStack(spacing: 20) {
                    Text(NSLocalizedString("manual_input_title", comment: "Manual input title"))
                        .font(.title2)
                        .bold()
                    
                    TextField(NSLocalizedString("enter_dish_name", comment: "Enter dish name placeholder"), text: $recognizedText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                    
                    HStack(spacing: 15) {
                        Button(NSLocalizedString("cancel", comment: "Cancel button")) {
                            showTextInput = false
                            recognizedText = ""
                        }
                        .buttonStyle(.bordered)
                        
                        Button(NSLocalizedString("search", comment: "Search button")) {
                            showTextInput = false
                            Task {
                                await processTextInput()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(recognizedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(15)
                .shadow(radius: 10)
                .padding(.horizontal, 40)
            }
        }
        .alert(NSLocalizedString("error", comment: "Error alert title"), isPresented: .constant(errorMessage != nil)) {
            Button(NSLocalizedString("ok", comment: "OK button")) {
                errorMessage = nil
            }
        } message: {
            if let errorMessage = errorMessage {
                Text(errorMessage)
            }
        }
        .fullScreenCover(isPresented: $showResults) {
            ResultsView(dishes: results, orderList: $orderList, skippedDishes: $skippedDishes, collectionsManager: collectionsManager)
                .environmentObject(orderManager)
        }
        .fullScreenCover(isPresented: $isLoading) {
            LoadingView(progressManager: progressManager)
        }
        .confirmationDialog("Scan a Menu", isPresented: $showScanOptions) {
            Button("Take Photo") {
                showScanner = true
            }
            
            Button("Choose from Library") {
                showPhotosPicker = true
            }
            
            Button("Cancel", role: .cancel) { }
        }
        .photosPicker(isPresented: $showPhotosPicker, selection: $selectedPhotoItem, matching: .images)
        .onChange(of: selectedPhotoItem) { _, newItem in
            if newItem != nil {
                Task {
                    await processSelectedImage()
                    selectedPhotoItem = nil
                }
            }
        }
        .sheet(isPresented: $showScanner) {
            DocumentScannerView(scannedImage: $scannedImage)
        }
        .onChange(of: scannedImage) { _, newImage in
            if let image = newImage {
                Task {
                    await processScannedImage(image)
                    scannedImage = nil
                }
            }
        }
    }

    private func processSelectedImage() async {
        // 重置所有相关状态，确保每次扫描都是一次全新的会话
        orderList = []
        skippedDishes = []
        results = []
        errorMessage = nil
        
        // 重置进度管理器
        await MainActor.run {
            progressManager.reset()
        }
        
        isLoading = true
        defer { isLoading = false }
        
        // 先测试网络连接
        let networkAvailable = await SiliconFlowAPIService.testNetworkConnection()
        if !networkAvailable {
            errorMessage = "网络连接失败，请检查网络设置。"
            return
        }
        
        guard let item = selectedPhotoItem else { 
            print("⚠️ selectedPhotoItem 为空")
            return 
        }
        do {
            guard let data = try await item.loadTransferable(type: Data.self) else {
                errorMessage = "Failed to load image data."
                return
            }
            let dishNames = try await SiliconFlowAPIService.identifyDishesInImage(imageData: data)
            if dishNames.isEmpty {
                errorMessage = "No dishes found in the image."
                return
            }
            
            // 设置总进度
            await MainActor.run {
                progressManager.totalItems = dishNames.count
            }
            var dishInfos: [DishInfo] = []
            try await withThrowingTaskGroup(of: DishInfo?.self) { group in
                for name in dishNames {
                    group.addTask {
                        do {
                            return try await SiliconFlowAPIService.getExplanation(for: name, userProfile: userSettings.profile)
                        } catch {
                            print("❌ 获取菜品解释失败: \(name), 错误: \(error)")
                            return nil
                        }
                    }
                }
                for try await info in group {
                    if let info = info {
                        dishInfos.append(info)
                        // 更新进度
                        await MainActor.run {
                            progressManager.completedItems += 1
                        }
                    }
                }
            }
            // 为每个菜品获取图片URL - 实现两步搜索策略
            for i in 0..<dishInfos.count {
                // 第一步：使用中文名进行图片搜索
                let primaryImageURL = await ImageService.fetchImageURL(for: dishInfos[i].chineseName)
                
                var finalImageURL: URL? = primaryImageURL
                
                // 第二步：如果中文搜索失败，使用英文名作为备选
                if primaryImageURL == nil {
                    print("🔄 中文搜索失败，尝试英文搜索: \(dishInfos[i].englishName)")
                    finalImageURL = await ImageService.fetchImageURL(for: dishInfos[i].englishName)
                }
                
                // 更新 DishInfo 对象
                dishInfos[i] = DishInfo(
                    chineseName: dishInfos[i].chineseName,
                    englishName: dishInfos[i].englishName,
                    pinyinName: dishInfos[i].pinyinName,
                    ingredients: dishInfos[i].ingredients,
                    cookingMethod: dishInfos[i].cookingMethod,
                    flavorTags: dishInfos[i].flavorTags,
                    imageURL: finalImageURL,
                    dietaryAnalysis: dishInfos[i].dietaryAnalysis
                )
            }
            
            // 智能排序：1. 安全的菜品优先 2. 按匹配分数排序
            dishInfos.sort { dish1, dish2 in
                let safe1 = dish1.dietaryAnalysis?.isSafe ?? true
                let safe2 = dish2.dietaryAnalysis?.isSafe ?? true
                
                if safe1 != safe2 {
                    return safe1 && !safe2
                }
                
                let score1 = dish1.dietaryAnalysis?.matchScore ?? 0
                let score2 = dish2.dietaryAnalysis?.matchScore ?? 0
                return score1 > score2
            }
            
            results = dishInfos
            // 添加到历史记录
            for dishInfo in dishInfos {
                historyManager.addToHistory(dishInfo, searchType: .image)
            }
            // 显示结果选择界面
            showResults = true
        } catch {
            errorMessage = "Image analysis failed. Please try again."
        }
    }

    private func processScannedImage(_ image: UIImage) async {
        // 重置所有相关状态，确保每次扫描都是一次全新的会话
        orderList = []
        skippedDishes = []
        results = []
        errorMessage = nil
        
        // 重置进度管理器
        await MainActor.run {
            progressManager.reset()
        }
        
        isLoading = true
        defer { isLoading = false }
        
        // 先测试网络连接
        let networkAvailable = await SiliconFlowAPIService.testNetworkConnection()
        if !networkAvailable {
            errorMessage = "网络连接失败，请检查网络设置。"
            return
        }
        
        do {
            // 将 UIImage 转换为 Data
            guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                print("❌ 无法将图片转换为 JPEG 数据")
                errorMessage = "Failed to process image data."
                return
            }
            
            let dishNames = try await SiliconFlowAPIService.identifyDishesInImage(imageData: imageData)
            if dishNames.isEmpty {
                errorMessage = "No dishes found in the image."
                return
            }
            
            // 设置总进度
            await MainActor.run {
                progressManager.totalItems = dishNames.count
            }
            var dishInfos: [DishInfo] = []
            try await withThrowingTaskGroup(of: DishInfo?.self) { group in
                for name in dishNames {
                    group.addTask {
                        do {
                            return try await SiliconFlowAPIService.getExplanation(for: name, userProfile: userSettings.profile)
                        } catch {
                            print("❌ 获取菜品解释失败: \(name), 错误: \(error)")
                            return nil
                        }
                    }
                }
                for try await info in group {
                    if let info = info {
                        dishInfos.append(info)
                        // 更新进度
                        await MainActor.run {
                            progressManager.completedItems += 1
                        }
                    }
                }
            }
            // 为每个菜品获取图片URL - 实现两步搜索策略
            for i in 0..<dishInfos.count {
                // 第一步：使用中文名进行图片搜索
                let primaryImageURL = await ImageService.fetchImageURL(for: dishInfos[i].chineseName)
                
                var finalImageURL: URL? = primaryImageURL
                
                // 第二步：如果中文搜索失败，使用英文名作为备选
                if primaryImageURL == nil {
                    print("🔄 中文搜索失败，尝试英文搜索: \(dishInfos[i].englishName)")
                    finalImageURL = await ImageService.fetchImageURL(for: dishInfos[i].englishName)
                }
                
                // 更新 DishInfo 对象
                dishInfos[i] = DishInfo(
                    chineseName: dishInfos[i].chineseName,
                    englishName: dishInfos[i].englishName,
                    pinyinName: dishInfos[i].pinyinName,
                    ingredients: dishInfos[i].ingredients,
                    cookingMethod: dishInfos[i].cookingMethod,
                    flavorTags: dishInfos[i].flavorTags,
                    imageURL: finalImageURL,
                    dietaryAnalysis: dishInfos[i].dietaryAnalysis
                )
            }
            
            // 智能排序：1. 安全的菜品优先 2. 按匹配分数排序
            dishInfos.sort { dish1, dish2 in
                let safe1 = dish1.dietaryAnalysis?.isSafe ?? true
                let safe2 = dish2.dietaryAnalysis?.isSafe ?? true
                
                if safe1 != safe2 {
                    return safe1 && !safe2
                }
                
                let score1 = dish1.dietaryAnalysis?.matchScore ?? 0
                let score2 = dish2.dietaryAnalysis?.matchScore ?? 0
                return score1 > score2
            }
            
            results = dishInfos
            // 添加到历史记录
            for dishInfo in dishInfos {
                historyManager.addToHistory(dishInfo, searchType: .image)
            }
            // 显示结果选择界面
            showResults = true
        } catch {
            errorMessage = "Image analysis failed. Please try again."
        }
    }

    private func processTextInput() async {
        // 重置所有相关状态，确保每次扫描都是一次全新的会话
        orderList = []
        skippedDishes = []
        results = []
        errorMessage = nil
        
        // 重置进度管理器
        await MainActor.run {
            progressManager.reset()
        }
        
        isLoading = true
        defer { isLoading = false }
        
        // 先测试网络连接
        let networkAvailable = await SiliconFlowAPIService.testNetworkConnection()
        if !networkAvailable {
            errorMessage = "网络连接失败，请检查网络设置。"
            return
        }
        
        let trimmed = recognizedText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        // 设置总进度为1（单个菜品）
        await MainActor.run {
            progressManager.totalItems = 1
        }
        
        do {
            let dishInfo = try await SiliconFlowAPIService.getExplanation(for: trimmed, userProfile: userSettings.profile)
            
            // 获取图片URL - 实现两步搜索策略
            // 第一步：使用中文名进行图片搜索
            let primaryImageURL = await ImageService.fetchImageURL(for: dishInfo.chineseName)
            
            var finalImageURL: URL? = primaryImageURL
            
            // 第二步：如果中文搜索失败，使用英文名作为备选
            if primaryImageURL == nil {
                print("🔄 中文搜索失败，尝试英文搜索: \(dishInfo.englishName)")
                finalImageURL = await ImageService.fetchImageURL(for: dishInfo.englishName)
            }
            
            let updatedDishInfo = DishInfo(
                chineseName: dishInfo.chineseName,
                englishName: dishInfo.englishName,
                pinyinName: dishInfo.pinyinName,
                ingredients: dishInfo.ingredients,
                cookingMethod: dishInfo.cookingMethod,
                flavorTags: dishInfo.flavorTags,
                imageURL: finalImageURL,
                dietaryAnalysis: dishInfo.dietaryAnalysis
            )
            
            // 更新进度
            await MainActor.run {
                progressManager.completedItems = 1
            }
            
            results = [updatedDishInfo]
            // 添加到历史记录
            historyManager.addToHistory(updatedDishInfo, searchType: .manual, originalName: trimmed)
            // 显示结果选择界面
            showResults = true
        } catch {
            errorMessage = "Text analysis failed. Please try again."
        }
    }
}

func recognizeText(from image: UIImage, completion: @escaping ([String]) -> Void) {
    guard let cgImage = image.cgImage else { completion([]); return }
    let request = VNRecognizeTextRequest { (request, error) in
        let texts = request.results?.compactMap { $0 as? VNRecognizedTextObservation }
            .compactMap { $0.topCandidates(1).first?.string }
        completion(texts ?? [])
    }
    request.recognitionLevel = .accurate
    let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
    try? handler.perform([request])
} 