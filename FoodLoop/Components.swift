import SwiftUI
import FirebaseFirestore
import CoreLocation
import GeoFireUtils

// 食物資料模型
struct FoodItem: Identifiable {
    let id: UUID
    let name: String
    let category: String
    let quantity: String
    let expires: Date
    let shareType: String
    let location: String
    let suggestion: String
    let uploader: UploaderInfo
    let aiSuggestion: String
    let aiRecipes: [RecipeCard]
    let tags: [String]
    let price: String?
    let distance: String
}

struct UploaderInfo {
    let nickname: String
    let rating: Double
    let shares: Int
}

struct RecipeCard {
    let emoji: String
    let title: String
    let desc: String
}

// 食物卡片
struct FoodCardView: View {
    let item: FoodItem
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGreen).opacity(0.12))
                .frame(width: 56, height: 56)
            VStack(alignment: .leading, spacing: 8) {
                Text(item.name)
                    .font(.title3)
                    .fontWeight(.bold)
                Text("\(item.distance)・\(item.expires.toRelativeExpireString())")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                HStack(spacing: 8) {
                    ForEach(item.tags, id: \.self) { tag in
                        Text(tag)
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Color(.systemGreen).opacity(0.10))
                            .foregroundColor(Color(.systemGreen))
                            .cornerRadius(12)
                    }
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 40) {
                Image(systemName: "heart")
                    .foregroundColor(.gray)
                Text(item.price ?? "免費")
                    .font(.subheadline)
                    .foregroundColor(.black)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color(.black).opacity(0.04), radius: 6, x: 0, y: 2)
    }
}

// 篩選 chip
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title)
                .fontWeight(.medium)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(isSelected ? Color(.systemGreen) : Color(.systemGreen).opacity(0.08))
                .foregroundColor(isSelected ? .white : Color(.systemGreen))
                .cornerRadius(22)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct StatCardView: View {
    let title: String
    let value: String
    var body: some View {
        VStack {
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            Text(title)
                .font(.subheadline)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGreen).opacity(0.1))
        .cornerRadius(12)
    }
}

struct ProgressBarView: View {
    let progress: CGFloat
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.gray.opacity(0.2))
                Capsule()
                    .fill(Color(hex:"#FFFFFF").opacity(0.6))
                    .frame(width: geo.size.width * progress)
            }
        }
    }
}

struct ChallengeCardView: View {
    let title: String
    let description: String
    let progress: CGFloat
    let completed: Int
    let total: Int
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            Text(description)
                .font(.subheadline)
            ProgressBarView(progress: progress)              .frame(height: 8)
            Text("\(completed)/\(total) 已完成")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(12)
    }
}

struct BadgeView: View {
    let icon: String
    let label: String
    var gray: Bool = false

    var body: some View {
        VStack {
            Image(systemName: icon)
                .resizable()
                .frame(width: 32, height: 32)
                .foregroundColor(.yellow)
                .opacity(gray ? 0.3 : 1.0)
            Text(label)
                .font(.caption)
                .foregroundColor(.primary)
                .opacity(gray ? 0.3 : 1.0)
        }
        .frame(width: 56)
    }
}


// 集中管理食物資料的 Repository
@MainActor
class FoodRepository: ObservableObject {
    @Published var foodItems: [FoodItem] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let firebaseManager = FirebaseManager.shared
    private var listener: ListenerRegistration?
    
    init() {
        setupRealtimeListener()
    }
    
    deinit {
        listener?.remove()
    }
    
    // Set up real-time listener for food items
    private func setupRealtimeListener() {
        listener = firebaseManager.listenToFoodItems { [weak self] firebaseItems in
            Task { @MainActor in
                self?.foodItems = firebaseItems.map { $0.toFoodItem() }
                self?.isLoading = false
            }
        }
    }
    
    // Add new food item to Firebase
    func addFoodItem(_ item: FoodItem, latitude: Double, longitude: Double, uploaderID: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Create geohash for location-based queries
            let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            let geohash = GFUtils.geoHash(forLocation: coordinate)
            
            let firebaseItem = FirebaseFoodItem(
                id: nil,
                name: item.name,
                category: item.category,
                quantity: item.quantity,
                expiryDate: item.expires,
                shareType: ShareType(rawValue: item.shareType) ?? .free,
                location: item.location,
                suggestion: item.suggestion,
                uploaderID: uploaderID,
                uploaderNickname: item.uploader.nickname,
                uploaderRating: item.uploader.rating,
                uploaderShares: item.uploader.shares,
                aiSuggestion: item.aiSuggestion,
                aiRecipes: item.aiRecipes.map { FirebaseRecipeCard(emoji: $0.emoji, title: $0.title, desc: $0.desc) },
                tags: item.tags,
                price: item.price,
                latitude: latitude,
                longitude: longitude,
                geohash: geohash,
                createdAt: Date(),
                updatedAt: Date(),
                isActive: true
            )
            
            let _ = try await firebaseManager.createFoodItem(firebaseItem)
            
            // Update user stats
            try await firebaseManager.updateUserStats(uid: uploaderID, shareCount: 1)
            try await firebaseManager.updateUserPoints(uid: uploaderID, points: 10)
            
        } catch {
            errorMessage = "Failed to add food item: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    // Load food items near user location
    func loadFoodItemsNearLocation(latitude: Double, longitude: Double, radius: Double = 10.0) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let firebaseItems = try await firebaseManager.getFoodItemsNearLocation(
                latitude: latitude,
                longitude: longitude,
                radiusInKm: radius
            )
            
            foodItems = firebaseItems.map { firebaseItem in
                var foodItem = firebaseItem.toFoodItem()
                // Calculate actual distance
                let userLocation = CLLocation(latitude: latitude, longitude: longitude)
                let itemLocation = CLLocation(latitude: firebaseItem.latitude, longitude: firebaseItem.longitude)
                let distance = userLocation.distance(from: itemLocation) / 1000 // Convert to km
                foodItem = FoodItem(
                    id: foodItem.id,
                    name: foodItem.name,
                    category: foodItem.category,
                    quantity: foodItem.quantity,
                    expires: foodItem.expires,
                    shareType: foodItem.shareType,
                    location: foodItem.location,
                    suggestion: foodItem.suggestion,
                    uploader: foodItem.uploader,
                    aiSuggestion: foodItem.aiSuggestion,
                    aiRecipes: foodItem.aiRecipes,
                    tags: foodItem.tags,
                    price: foodItem.price,
                    distance: String(format: "%.1fkm", distance)
                )
                return foodItem
            }
            isLoading = false
        } catch {
            errorMessage = "Failed to load food items: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    // Filter by share type
    func loadFoodItemsByShareType(_ shareType: ShareType) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let firebaseItems = try await firebaseManager.getFoodItemsByShareType(shareType)
            
            foodItems = firebaseItems.map { $0.toFoodItem() }
            isLoading = false
        } catch {
            errorMessage = "Failed to filter food items: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    // Legacy method for backward compatibility - now uses Firebase
    func addFoodItem(_ item: FoodItem) {
        // This method now requires additional parameters, so we'll use mock data for now
        foodItems.insert(item, at: 0)
    }
    
    static func generateMockData(count: Int) -> [FoodItem] {
        let names = ["新鮮蔬菜", "自製麵包", "剩餘水果", "義大利麵醬", "熟食便當", "手工果醬", "過剩麵粉", "有機雞蛋"]
        let categories = ["蔬菜", "麵包", "水果", "醬料", "便當", "甜品", "原料", "蛋類"]
        let suggestions = ["記得要冷藏喔！", "請盡快食用", "適合做沙拉", "可分裝分享", "新鮮現做", "適合早餐", "健康美味"]
        let shareTypes = ["免費", "優惠", "捐贈"]
        let locations = ["社區中心", "市場口", "公園旁", "學校前", "社區冰箱"]
        let uploaders = [
            UploaderInfo(nickname: "小明", rating: 4.8, shares: 23),
            UploaderInfo(nickname: "阿美", rating: 4.6, shares: 12),
            UploaderInfo(nickname: "Sarah", rating: 4.9, shares: 31),
            UploaderInfo(nickname: "John", rating: 4.7, shares: 18)
        ]
        let tagsPool = ["免費", "有機", "自製", "捐贈", "大量", "優惠", "醬料", "即食", "甜品", "原料", "農場直送"]
        let recipePool = [
            RecipeCard(emoji: "🥗", title: "蔬菜沙拉", desc: "簡單拌一拌，健康又美味！"),
            RecipeCard(emoji: "🍲", title: "蔬菜湯", desc: "將蔬菜煮成湯，營養滿分。"),
            RecipeCard(emoji: "🥪", title: "三明治", desc: "夾入蔬菜與蛋，快速早餐。"),
            RecipeCard(emoji: "🍮", title: "麵包布丁", desc: "剩麵包也能變甜點。"),
            RecipeCard(emoji: "🍳", title: "簡易快炒", desc: "快速翻炒，美味上桌。")
        ]
        var result: [FoodItem] = []
        for _ in 0..<count {
            let name = names.randomElement()!
            let category = categories.randomElement()!
            let quantity = "\(Int.random(in: 1...5))份"
            let expires = Calendar.current.date(byAdding: .day, value: Int.random(in: 0...7), to: Date())!
            let shareType = shareTypes.randomElement()!
            let location = locations.randomElement()!
            let suggestion = suggestions.randomElement()!
            let uploader = uploaders.randomElement()!
            let aiSuggestion = ["冷藏，24小時內食用", "常溫保存，2天內食用", "冷藏，3天內食用", "依食材類型保存"].randomElement()!
            let aiRecipes = recipePool.shuffled().prefix(2).map { $0 }
            let tags = Array(tagsPool.shuffled().prefix(Int.random(in: 2...3)))
            let price: String? = shareType == "免費" ? nil : "$\(Int.random(in: 1...5))"
            let distance = String(format: "%.1fkm", Double.random(in: 0.3...3.0))
            result.append(FoodItem(
                id: UUID(),
                name: name,
                category: category,
                quantity: quantity,
                expires: expires,
                shareType: shareType,
                location: location,
                suggestion: suggestion,
                uploader: uploader,
                aiSuggestion: aiSuggestion,
                aiRecipes: aiRecipes,
                tags: tags,
                price: price,
                distance: distance
            ))
        }
        return result
    }
}

extension DateFormatter {
    static let shortDate: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .short
        df.timeStyle = .none
        return df
    }()
}

extension Date {
    func toRelativeExpireString() -> String {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let expireDay = calendar.startOfDay(for: self)
        let diff = calendar.dateComponents([.day], from: today, to: expireDay).day ?? 0
        switch diff {
        case 0: return "今日到期"
        case 1: return "明日到期"
        default:
            let df = DateFormatter.shortDate
            return df.string(from: self)
        }
    }
} 
