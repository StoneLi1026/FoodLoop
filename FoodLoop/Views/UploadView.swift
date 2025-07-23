import SwiftUI
import PhotosUI
import CoreLocation
import FirebaseAuth

struct UploadView: View {
    @EnvironmentObject var foodRepo: FoodRepository
    @EnvironmentObject var userProfile: UserProfileModel
    @StateObject private var challengeManager = ChallengeManager.shared
    @State private var foodName = ""
    @State private var foodPrice = ""
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
    @State private var locationManager = LocationManager()
    @State private var isUploading = false
    @State private var uploadSuccess = false
    
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
                    
                    // 食物名稱
                    VStack(alignment: .leading, spacing: 4) {
                        Text("食物名稱")
                            .font(.headline)
                        TextField("輸入食物名稱", text: $foodName)
                            .textFieldStyle(.roundedBorder)
                            .onSubmit {
                                hideKeyboard()
                            }
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
                    
                    // 數量、價格與到期日
                    HStack {
                        VStack(alignment: .leading) {
                            Text("數量")
                                .font(.headline)
                            TextField("例如 2公斤", text: $quantity)
                                .textFieldStyle(.roundedBorder)
                                .onSubmit {
                                    hideKeyboard()
                                }
                        }
                        VStack(alignment: .leading) {
                            Text("價格")
                                .font(.headline)
                            TextField("價格 (可選)", text: $foodPrice)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.decimalPad)
                                .onSubmit {
                                    hideKeyboard()
                                }
                        }
                    }
                    
                    // 到期日
                    VStack(alignment: .leading) {
                        Text("到期日")
                            .font(.headline)
                        DatePicker("", selection: $expires, in: Date()..., displayedComponents: .date)
                            .labelsHidden()
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
                            .onSubmit {
                                hideKeyboard()
                            }
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
                        uploadFoodItem()
                    }) {
                        HStack {
                            if isUploading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                                Text("發佈中...")
                            } else {
                                Text("發佈食物項目")
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isUploading ? Color.gray : Color(.systemGreen))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(isUploading)
                    
                    if let errorMessage = foodRepo.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                .padding()
            }
            .navigationTitle("分享食物")
            .navigationBarTitleDisplayMode(.inline)
            .onTapGesture {
                hideKeyboard()
            }
            .onAppear {
                locationManager.requestPermission()
            }
            .alert("上傳成功", isPresented: $uploadSuccess) {
                Button("確定") {
                    clearForm()
                }
            } message: {
                Text("您的食物已成功分享！")
            }
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    private func uploadFoodItem() {
        guard let currentUser = Auth.auth().currentUser else {
            foodRepo.errorMessage = "請先登入"
            return
        }
        
        guard !foodName.isEmpty else {
            foodRepo.errorMessage = "請輸入食物名稱"
            return
        }
        
        guard !category.isEmpty else {
            foodRepo.errorMessage = "請選擇食物分類"
            return
        }
        
        isUploading = true
        
        Task {
            // Get current location
            var latitude: Double = 25.0330 // Default to Taipei if no location
            var longitude: Double = 121.5654
            
            if let currentLocation = locationManager.currentLocation {
                latitude = currentLocation.coordinate.latitude
                longitude = currentLocation.coordinate.longitude
            }
            
            // Create food item
            let priceString = foodPrice.isEmpty ? nil : "$\(foodPrice)"
            let actualPrice = shareTypes[shareType] == "免費" ? nil : priceString
            
            let newItem = FoodItem(
                id: UUID(),
                name: foodName,
                category: category,
                quantity: quantity.isEmpty ? "1份" : quantity,
                expires: expires,
                shareType: shareTypes[shareType],
                location: location.isEmpty ? "用戶位置" : location,
                suggestion: suggestion.isEmpty ? "歡迎索取！" : suggestion,
                uploader: UploaderInfo(
                    nickname: userProfile.name,
                    rating: 5.0, // Default rating for new users
                    shares: userProfile.shareCount
                ),
                aiSuggestion: generateAISuggestion(category: category, expires: expires),
                aiRecipes: generateAIRecipes(category: category),
                tags: selectedTags.isEmpty ? [category] : selectedTags,
                price: actualPrice,
                imageURLs: [], // Will be updated after photo upload
                distance: "計算中"
            )
            
            // Upload to Firebase
            await foodRepo.addFoodItem(
                newItem,
                latitude: latitude,
                longitude: longitude,
                uploaderID: currentUser.uid
            )
            
            await MainActor.run {
                isUploading = false
                if foodRepo.errorMessage == nil {
                    uploadSuccess = true
                    
                    // Trigger challenge progress
                    Task {
                        let useEcoContainer = selectedTags.contains("環保") || selectedTags.contains("自製")
                        await challengeManager.onFoodUpload(
                            userID: currentUser.uid, 
                            useEcoContainer: useEcoContainer
                        )
                    }
                }
            }
        }
    }
    
    private func clearForm() {
        foodName = ""
        foodPrice = ""
        category = "蔬菜"
        quantity = ""
        expires = Date()
        shareType = 0
        location = ""
        suggestion = ""
        selectedTags = []
        selectedImages = []
        selectedPhotos = []
    }
    
    private func generateAISuggestion(category: String, expires: Date) -> String {
        let daysUntilExpiry = Calendar.current.dateComponents([.day], from: Date(), to: expires).day ?? 0
        
        switch daysUntilExpiry {
        case 0:
            return "今日到期，請盡快食用"
        case 1:
            return "明日到期，建議冷藏保存"
        case 2...3:
            return "冷藏保存，3天內食用完畢"
        default:
            return category.contains("蔬菜") ? "冷藏保存，保持新鮮" : "依照包裝指示保存"
        }
    }
    
    private func generateAIRecipes(category: String) -> [RecipeCard] {
        let recipesByCategory: [String: [RecipeCard]] = [
            "蔬菜": [
                RecipeCard(emoji: "🥗", title: "蔬菜沙拉", desc: "簡單拌一拌，健康又美味！"),
                RecipeCard(emoji: "🍲", title: "蔬菜湯", desc: "將蔬菜煮成湯，營養滿分。")
            ],
            "水果": [
                RecipeCard(emoji: "🥤", title: "新鮮果汁", desc: "打成果汁，維生素滿滿。"),
                RecipeCard(emoji: "🍮", title: "水果優格", desc: "搭配優格，健康點心。")
            ],
            "烘焙": [
                RecipeCard(emoji: "🥪", title: "三明治", desc: "夾入蔬菜與蛋，快速早餐。"),
                RecipeCard(emoji: "🍮", title: "麵包布丁", desc: "剩麵包也能變甜點。")
            ]
        ]
        
        return recipesByCategory[category] ?? [
            RecipeCard(emoji: "🍳", title: "簡易快炒", desc: "快速翻炒，美味上桌。")
        ]
    }
}
