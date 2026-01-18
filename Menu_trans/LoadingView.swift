import SwiftUI

struct LoadingView: View {
    @ObservedObject var progressManager: ProgressManager
    
    var body: some View {
        ZStack {
            // 半透明黑色蒙版
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            
            // 加载内容
            VStack(spacing: 20) {
                // 持续缩放的 App 图标
                Image(systemName: "fork.knife.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                    .scaleEffect(1.2)
                    .animation(
                        Animation.easeInOut(duration: 1.0)
                            .repeatForever(autoreverses: true),
                        value: true
                    )
                
                // 进度条
                VStack(spacing: 8) {
                    ProgressView(value: progressManager.progress)
                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                        .frame(width: 200)
                    
                    Text("\(progressManager.completedItems) / \(progressManager.totalItems)")
                        .font(.caption)
                        .foregroundColor(.white)
                }
                
                // 加载文案
                Text(NSLocalizedString("loading_text_1", comment: "Loading text 1"))
                    .font(.title3)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .opacity(1.0)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: true)
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
                    .shadow(radius: 20)
            )
        }
    }
}

#Preview {
    LoadingView(progressManager: ProgressManager())
} 