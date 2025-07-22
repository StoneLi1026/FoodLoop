import SwiftUI

struct AdminPanelView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // 舉報卡片
                VStack(alignment: .leading, spacing: 8) {
                    Text("過期乳製品")
                        .font(.headline)
                    Text("1 位用戶舉報")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("中等優先")
                        .font(.caption2)
                        .foregroundColor(.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                    HStack {
                        Button("移除") {}
                            .buttonStyle(.borderedProminent)
                            .tint(.red)
                        Button("調查") {}
                            .buttonStyle(.bordered)
                        Button("忽略") {}
                            .buttonStyle(.bordered)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(16)
                .padding(.horizontal)
                
                // 驗證佇列
                VStack(alignment: .leading, spacing: 8) {
                    Text("✅ 驗證佇列")
                        .font(.headline)
                    HStack {
                        Circle().fill(Color(.systemGreen)).frame(width: 40, height: 40)
                            .overlay(Text("R").foregroundColor(.white))
                        VStack(alignment: .leading) {
                            Text("餐廳夥伴")
                                .fontWeight(.bold)
                            Text("申請「已驗證捐贈者」徽章")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Button("通過") {}
                            .buttonStyle(.borderedProminent)
                        Button("拒絕") {}
                            .buttonStyle(.bordered)
                            .tint(.red)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(16)
                .padding(.horizontal)
                
                // 管理統計
                VStack(alignment: .leading, spacing: 8) {
                    Text("📊 管理統計")
                        .font(.headline)
                    HStack {
                        VStack {
                            Text("23")
                                .font(.title)
                                .fontWeight(.bold)
                            Text("待處理舉報")
                                .font(.caption)
                        }
                        Spacer()
                        VStack {
                            Text("8")
                                .font(.title)
                                .fontWeight(.bold)
                            Text("驗證佇列")
                                .font(.caption)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(16)
                .padding(.horizontal)
            }
            .padding(.top)
        }
        .navigationTitle("管理面板")
    }
}
