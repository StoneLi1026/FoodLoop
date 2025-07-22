import SwiftUI

struct ChatView: View {
    var body: some View {
        NavigationStack {
            VStack {
                // 聊天列表
                List {
                    NavigationLink(destination: ChatDetailView()) {
                        HStack {
                            Circle().fill(Color(.systemGreen)).frame(width: 40, height: 40)
                                .overlay(Text("M").foregroundColor(.white))
                            VStack(alignment: .leading) {
                                Text("Maria Santos")
                                    .fontWeight(.bold)
                                Text("關於新鮮蔬菜")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Text("2 分鐘前")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    NavigationLink(destination: ChatDetailView()) {
                        HStack {
                            Circle().fill(Color(.systemBlue)).frame(width: 40, height: 40)
                                .overlay(Text("J").foregroundColor(.white))
                            VStack(alignment: .leading) {
                                Text("John Kim")
                                    .fontWeight(.bold)
                                Text("關於自製麵包")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Text("1 小時前")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("訊息")
        }
    }
}

struct ChatDetailView: View {
    var body: some View {
        VStack {
            ScrollView {
                VStack(spacing: 12) {
                    ChatBubbleView(text: "嗨！我對蔬菜有興趣，還有嗎？", isMe: false)
                    ChatBubbleView(text: "有的！還很新鮮，什麼時候方便取？", isMe: true)
                    ChatBubbleView(text: "今天下午三點可以嗎？", isMe: false)
                    ChatBubbleView(text: "沒問題！我會在社區中心等你。", isMe: true)
                }
                .padding()
            }
            HStack {
                Button(action: {}) {
                    Label("確認取貨", systemImage: "checkmark")
                        .padding()
                        .background(Color(.systemGreen))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                Button(action: {}) {
                    Label("取消請求", systemImage: "xmark")
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                }
            }
            .padding()
        }
        .navigationTitle("聊天")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ChatBubbleView: View {
    let text: String
    let isMe: Bool
    var body: some View {
        HStack {
            if isMe { Spacer() }
            Text(text)
                .padding()
                .background(isMe ? Color(.systemGreen).opacity(0.8) : Color(.systemGray5))
                .foregroundColor(isMe ? .white : .black)
                .cornerRadius(16)
            if !isMe { Spacer() }
        }
    }
}
