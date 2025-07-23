import SwiftUI

struct FoodDetailView: View {
    let foodItem: FoodItem
    @State private var showChat = false
    @State private var selectedImageIndex = 0
    @State private var showImageViewer = false
    
    // 根據 foodItem 給出 AI 建議
    var aiSuggestion: (storage: String, recipes: String) {
        if foodItem.tags.contains(where: { $0.contains("蔬菜") }) || foodItem.name.contains("蔬菜") {
            return ("冷藏，24小時內食用", "快炒、蔬菜湯、沙拉")
        } else if foodItem.tags.contains(where: { $0.contains("麵包") }) || foodItem.name.contains("麵包") {
            return ("常溫保存，2天內食用", "三明治、烤麵包、布丁")
        } else if foodItem.tags.contains(where: { $0.contains("水果") }) || foodItem.name.contains("水果") {
            return ("冷藏，3天內食用", "水果沙拉、果醬、果汁")
        } else {
            return ("依食材類型保存", "請參考食譜建議")
        }
    }
    // 推薦食譜（可根據食材自訂，這裡用 mock）
    var recommendedRecipes: [(emoji: String, title: String, desc: String)] {
        if foodItem.tags.contains(where: { $0.contains("蔬菜") }) || foodItem.name.contains("蔬菜") {
            return [
                ("🥗", "蔬菜沙拉", "簡單拌一拌，健康又美味！"),
                ("🍲", "蔬菜湯", "將蔬菜煮成湯，營養滿分。")
            ]
        } else if foodItem.tags.contains(where: { $0.contains("麵包") }) || foodItem.name.contains("麵包") {
            return [
                ("🥪", "三明治", "夾入蔬菜與蛋，快速早餐。"),
                ("🍮", "麵包布丁", "剩麵包也能變甜點。")
            ]
        } else {
            return [
                ("🍽️", "創意料理", "發揮創意，變化多端！"),
                ("🍳", "簡易快炒", "快速翻炒，美味上桌。")
            ]
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 食物照片 - 支援多張圖片滑動
                if !foodItem.imageURLs.isEmpty {
                    TabView(selection: $selectedImageIndex) {
                        ForEach(Array(foodItem.imageURLs.enumerated()), id: \.offset) { index, imageURL in
                            AsyncImage(url: URL(string: imageURL)) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 180)
                                    .clipped()
                                    .cornerRadius(20)
                                    .onTapGesture {
                                        selectedImageIndex = index
                                        showImageViewer = true
                                    }
                            } placeholder: {
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color(.systemGray5))
                                    .frame(height: 180)
                                    .overlay(
                                        ProgressView()
                                    )
                            }
                            .tag(index)
                        }
                    }
                    .frame(height: 180)
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
                    .padding(.horizontal)
                } else {
                    // 預設圖片當沒有上傳照片時
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(.systemGreen).opacity(0.12))
                        VStack {
                            Image(systemName: "leaf")
                                .font(.system(size: 40))
                                .foregroundColor(.green)
                            Text(foodItem.name + " 照片")
                                .foregroundColor(Color(.systemGreen))
                                .font(.title3)
                        }
                        .frame(maxWidth: .infinity, minHeight: 120, maxHeight: 180)
                    }
                    .frame(height: 180)
                    .padding(.horizontal)
                }
                
                // 食物資訊
                VStack(alignment: .leading, spacing: 8) {
                    Text(foodItem.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("來自社群分享的美味食材")
                        .foregroundColor(.secondary)
                    // 數量/到期/地點卡片
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("價格：")
                                        .fontWeight(.bold)
                                    Text(foodItem.price ?? "免費")
                                }
                                HStack {
                                    Text("地點：")
                                        .fontWeight(.bold)
                                    Text(foodItem.location)
                                }
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 12) {
                                HStack {
                                    Text("數量：")
                                        .fontWeight(.bold)
                                    Text(foodItem.quantity)
                                }
                                HStack {
                                    Text("到期：")
                                        .fontWeight(.bold)
                                    Text(foodItem.expires.toRelativeExpireString())
                                }
                            }
                        }
                        // 地圖區塊
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.systemGreen).opacity(0.10))
                            HStack {
                                Image(systemName: "mappin.and.ellipse")
                                Text("地圖檢視")
                                    .foregroundColor(Color(.systemGreen))
                            }
                        }
                        .frame(height: 60)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                }
                .padding(.horizontal)
                
                // 食物標籤
                if !foodItem.tags.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("標籤")
                            .font(.headline)
                            .fontWeight(.bold)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(foodItem.tags, id: \.self) { tag in
                                    Text(tag)
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color(.systemGreen).opacity(0.15))
                                        .foregroundColor(Color(.systemGreen))
                                        .cornerRadius(12)
                                }
                            }
                            .padding(.horizontal, 1)
                        }
                    }
                    .padding(.horizontal)
                }
                
                // 分享者資訊
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Circle()
                            .fill(Color(.systemGreen))
                            .frame(width: 40, height: 40)
                            .overlay(Text(String(foodItem.uploader.nickname.prefix(1))).foregroundColor(.white).font(.title2))
                        VStack(alignment: .leading) {
                            Text(foodItem.uploader.nickname)
                                .fontWeight(.bold)
                            HStack {
                                Image(systemName: "star.fill").foregroundColor(.yellow)
                                Text(String(format: "%.1f", foodItem.uploader.rating))
                                Text("・\(foodItem.uploader.shares)次分享")
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    HStack(spacing: 12) {
                        Button(action: {}) {
                            Text("請求")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color(.systemGreen))
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        Button(action: { showChat = true }) {
                            HStack {
                                Image(systemName: "bubble.left.and.bubble.right")
                                Text("聊天")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 4)
                
                // 橫向可滑動建議卡片
                TabView {
                    SuggestionCardView(
                        title: "🧑‍🍳 作者留言",
                        content: foodItem.suggestion
                    )
                    SuggestionCardView(
                        title: "🤖 AI 建議",
                        content: "儲存方式：" + aiSuggestion.storage + "\n建議用途：" + aiSuggestion.recipes
                    )
                    SuggestionCardView(
                        title: recommendedRecipes[0].emoji + " " + recommendedRecipes[0].title,
                        content: recommendedRecipes[0].desc
                    )
                    SuggestionCardView(
                        title: recommendedRecipes[1].emoji + " " + recommendedRecipes[1].title,
                        content: recommendedRecipes[1].desc
                    )
                }
                .frame(height: 140)
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            .padding(.top)
            .padding(.bottom, 24)
        }
        .navigationTitle("食物詳情")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showChat) {
            ChatView()
        }
        .fullScreenCover(isPresented: $showImageViewer) {
            ImageViewerView(
                imageURLs: foodItem.imageURLs,
                selectedIndex: $selectedImageIndex,
                isPresented: $showImageViewer
            )
        }
    }
}

struct SuggestionCardView: View {
    let title: String
    let content: String
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
            Text(content)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .cornerRadius(16)
        .shadow(color: Color(.black).opacity(0.03), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Image Viewer with Zoom
struct ImageViewerView: View {
    let imageURLs: [String]
    @Binding var selectedIndex: Int
    @Binding var isPresented: Bool
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var previousOffset: CGSize = .zero
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if !imageURLs.isEmpty {
                    TabView(selection: $selectedIndex) {
                        ForEach(Array(imageURLs.enumerated()), id: \.offset) { index, imageURL in
                            AsyncImage(url: URL(string: imageURL)) { image in
                                image
                                    .resizable()
                                    .scaledToFit()
                                    .scaleEffect(scale)
                                    .offset(offset)
                                    .gesture(
                                        SimultaneousGesture(
                                            MagnificationGesture()
                                                .onChanged { value in
                                                    scale = value
                                                }
                                                .onEnded { value in
                                                    if scale < 1.0 {
                                                        scale = 1.0
                                                        offset = .zero
                                                    } else if scale > 4.0 {
                                                        scale = 4.0
                                                    }
                                                },
                                            DragGesture()
                                                .onChanged { value in
                                                    if scale > 1.0 {
                                                        offset = CGSize(
                                                            width: previousOffset.width + value.translation.width,
                                                            height: previousOffset.height + value.translation.height
                                                        )
                                                    }
                                                }
                                                .onEnded { value in
                                                    previousOffset = offset
                                                }
                                        )
                                    )
                                    .onTapGesture(count: 2) {
                                        withAnimation(.spring()) {
                                            if scale == 1.0 {
                                                scale = 2.0
                                            } else {
                                                scale = 1.0
                                                offset = .zero
                                                previousOffset = .zero
                                            }
                                        }
                                    }
                            } placeholder: {
                                ProgressView()
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                            }
                            .tag(index)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle())
                    .onChange(of: selectedIndex) { oldValue, newValue in
                        // Reset zoom when switching images
                        scale = 1.0
                        offset = .zero
                        previousOffset = .zero
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("關閉") {
                        isPresented = false
                    }
                    .foregroundColor(.white)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Text("\(selectedIndex + 1) / \(imageURLs.count)")
                        .foregroundColor(.white)
                }
            }
        }
    }
}
