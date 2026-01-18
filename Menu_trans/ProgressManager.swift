import SwiftUI

class ProgressManager: ObservableObject {
    @Published var totalItems: Int = 0
    @Published var completedItems: Int = 0

    var progress: Double {
        // 避免 totalItems 为 0 时除法出错
        guard totalItems > 0 else { return 0.0 }
        return Double(completedItems) / Double(totalItems)
    }

    // 用于开始新任务时重置
    func reset() {
        totalItems = 0
        completedItems = 0
    }
} 