import SwiftUI

struct FridgeMapView: View {
    @State private var selectedFilter = 0
    let filters = ["全部冰箱", "可領取", "附近"]
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 地圖區塊
                Rectangle()
                    .fill(Color(.systemGreen).opacity(0.1))
                    .frame(height: 180)
                    .overlay(
                        VStack {
                            Text("🗺️ 互動地圖")
                                .font(.headline)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("📍 社區冰箱 #1")
                                Text("📍 社區冰箱 #2")
                                Text("📍 社區冰箱 #3")
                            }
                            .font(.subheadline)
                        }
                    )
                    .cornerRadius(16)
                    .padding()
                
                // 冰箱卡片
                ScrollView {
                    VStack(spacing: 16) {
                        FridgeCardView(
                            name: "社區冰箱",
                            address: "123 主街",
                            distance: "0.3km",
                            items: [("麵包", 3), ("水果", 5), ("乳製品", 2)]
                        )
                    }
                    .padding(.horizontal)
                }
                
                // 篩選 chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(filters.indices, id: \ .self) { idx in
                            FilterChip(title: filters[idx], isSelected: selectedFilter == idx) {
                                selectedFilter = idx
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding()
            }
            .navigationTitle("冰箱地圖")
        }
    }
}

struct FridgeCardView: View {
    let name: String
    let address: String
    let distance: String
    let items: [(String, Int)]
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("📍 \(name)")
                    .font(.headline)
                Spacer()
                Text("\(distance) 距離")
                    .font(.caption)
            }
            Text(address)
                .font(.subheadline)
                .foregroundColor(.secondary)
            HStack {
                ForEach(items, id: \.0) { item in
                    Text("\(item.0) (\(item.1))")
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(.systemGreen).opacity(0.1))
                        .cornerRadius(12)
                }
            }
            Button(action: {}) {
                Text("預約取貨時間")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGreen))
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}
