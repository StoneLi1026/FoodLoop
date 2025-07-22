import SwiftUI
import PhotosUI

struct UploadView: View {
    @EnvironmentObject var foodRepo: FoodRepository
    @State private var category = "蔬菜"
    @State private var quantity = ""
    @State private var expires = Date()
    @State private var shareType = 0
    @State private var location = ""
    @State private var donateToOrg = false
    @State private var showMap = false
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var selectedImages: [UIImage] = []
    @State private var showPhotoDeniedAlert = false
    @State private var suggestion = ""
    @State private var selectedTags: [String] = []
    
    let categories = ["蔬菜", "水果", "烘焙", "乳製品", "冷凍", "其他"]
    let shareTypes = ["免費", "優惠", "捐贈"]
    let tagsPool = ["免費", "有機", "自製", "捐贈", "大量", "優惠", "醬料", "即食", "甜品", "原料", "農場直送"]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 標題
                    Text("請上傳食物圖片及購買證明")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.top)
                    
                    // 多張照片上傳
                    VStack {
                        if selectedImages.isEmpty {
                            VStack {
                                Image(systemName: "camera")
                                    .font(.system(size: 32))
                                    .foregroundColor(.gray)
                                Text("新增照片")
                                    .foregroundColor(.gray)
                            }
                            .frame(maxWidth: .infinity, minHeight: 120, maxHeight: 180)
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(selectedImages, id: \.self) { image in
                                        Image(uiImage: image)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 120, height: 120)
                                            .clipped()
                                            .cornerRadius(12)
                                    }
                                }
                                .padding(.vertical, 8)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 180)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(style: StrokeStyle(lineWidth: 2, dash: [8]))
                            .foregroundColor(Color(.systemGray4))
                    )
                    .contentShape(Rectangle())
                    PhotosPicker(selection: $selectedPhotos, maxSelectionCount: 6, matching: .images, photoLibrary: .shared()) {
                        HStack {
                            Image(systemName: "plus")
                            Text("選擇照片（可多選）")
                        }
                        .font(.body)
                        .foregroundColor(.green)
                        .padding(.top, 4)
                    }
                    .onTapGesture {
                        PermissionsManager.checkPhotoPermission { status in
                            if status == .denied || status == .restricted {
                                showPhotoDeniedAlert = true
                            }
                        }
                    }
                    .onChange(of: selectedPhotos) { oldItems, newItems in
                        selectedImages = []
                        for item in newItems {
                            Task {
                                if let data = try? await item.loadTransferable(type: Data.self),
                                   let uiImage = UIImage(data: data) {
                                    await MainActor.run {
                                        selectedImages.append(uiImage)
                                    }
                                }
                            }
                        }
                    }
                    .alert("無法存取相簿", isPresented: $showPhotoDeniedAlert) {
                        Button("前往設定") {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }
                        Button("取消", role: .cancel) {}
                    } message: {
                        Text("請至設定開啟相簿權限，以便上傳食物圖片")
                    }
                    
                    // 分類
                    VStack(alignment: .leading, spacing: 4) {
                        Text("分類")
                            .font(.headline)
                        Picker("分類", selection: $category) {
                            ForEach(categories, id: \.self) { Text($0) }
                        }
                        .pickerStyle(.menu)
                    }
                    
                    // 數量與到期日
                    HStack {
                        VStack(alignment: .leading) {
                            Text("數量")
                                .font(.headline)
                            TextField("例如 2公斤", text: $quantity)
                                .textFieldStyle(.roundedBorder)
                        }
                        VStack(alignment: .leading) {
                            Text("到期日")
                                .font(.headline)
                            DatePicker("", selection: $expires, in: Date()..., displayedComponents: .date)
                                .labelsHidden()
                        }
                    }
                    
                    // 分享類型
                    VStack(alignment: .leading, spacing: 4) {
                        Text("分享類型")
                            .font(.headline)
                        HStack {
                            ForEach(0..<shareTypes.count, id: \.self) { idx in
                                Button(action: { shareType = idx }) {
                                    Text(shareTypes[idx])
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 10)
                                        .background(shareType == idx ? Color(.systemGreen) : Color(.systemGray6))
                                        .foregroundColor(shareType == idx ? .white : .green)
                                        .cornerRadius(20)
                                }
                            }
                        }
                    }
                    
                    // 地點
                    VStack(alignment: .leading, spacing: 4) {
                        Text("地點")
                            .font(.headline)
                        TextField("輸入地址或點擊地圖選取", text: $location)
                            .textFieldStyle(.roundedBorder)
                        Button(action: { showMap = true }) {
                            HStack {
                                Image(systemName: "mappin.and.ellipse")
                                Text("📍 選取地圖位置")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGreen).opacity(0.1))
                            .cornerRadius(12)
                        }
                        .sheet(isPresented: $showMap) {
                            VStack {
                                Text("這裡是地圖選取畫面（未來可串接 Google Maps）")
                                    .font(.title3)
                                    .padding()
                                Spacer()
                                Button("關閉") { showMap = false }
                                    .padding()
                            }
                        }
                    }
                    
                    // 捐贈開關
                    Toggle("捐贈給組織", isOn: $donateToOrg)
                        .padding(.vertical)
                    
                    // 上傳者留言
                    VStack(alignment: .leading, spacing: 4) {
                        Text("上傳者留言")
                            .font(.headline)
                        TextEditor(text: $suggestion)
                            .frame(height: 80)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(.systemGray4)))
                            .padding(.bottom, 4)
                    }
                    // 標籤多選
                    VStack(alignment: .leading, spacing: 4) {
                        Text("選擇標籤")
                            .font(.headline)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(tagsPool, id: \.self) { tag in
                                    FilterChip(title: tag, isSelected: selectedTags.contains(tag)) {
                                        if selectedTags.contains(tag) {
                                            selectedTags.removeAll { $0 == tag }
                                        } else {
                                            selectedTags.append(tag)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    // 發佈按鈕
                    Button(action: {
                        // 模擬上傳，實際應用可串接登入者資料
                        let newItem = FoodItem(
                            id: UUID(),
                            name: category + "分享", // 可改為自訂名稱
                            category: category,
                            quantity: quantity.isEmpty ? "1份" : quantity,
                            expires: expires,
                            shareType: shareTypes[shareType],
                            location: location.isEmpty ? "社區中心" : location,
                            suggestion: suggestion.isEmpty ? "歡迎索取！" : suggestion,
                            uploader: UploaderInfo(nickname: "你", rating: 5.0, shares: 1),
                            aiSuggestion: "冷藏，24小時內食用",
                            aiRecipes: [],
                            tags: selectedTags.isEmpty ? [category] : selectedTags,
                            price: shareTypes[shareType] == "免費" ? nil : "$1",
                            distance: "0.5km"
                        )
                        foodRepo.addFoodItem(newItem)
                        // 清空表單
                        category = "蔬菜"
                        quantity = ""
                        expires = Date()
                        shareType = 0
                        location = ""
                        suggestion = ""
                        selectedTags = []
                    }) {
                        Text("發佈食物項目")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGreen))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                }
                .padding()
            }
            .navigationTitle("分享食物")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
