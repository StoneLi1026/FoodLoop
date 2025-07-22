import Foundation
import SwiftUI
import FirebaseFirestore
import GeoFireUtils

// MARK: - Firebase Data Models

// Firebase-compatible FoodItem model
struct FirebaseFoodItem: Codable, Identifiable {
    @DocumentID var id: String?
    let name: String
    let category: String
    let quantity: String
    let expiryDate: Date
    let shareType: ShareType
    let location: String
    let suggestion: String
    let uploaderID: String
    let uploaderNickname: String
    let uploaderRating: Double
    let uploaderShares: Int
    let aiSuggestion: String
    let aiRecipes: [FirebaseRecipeCard]
    let tags: [String]
    let price: String?
    let latitude: Double
    let longitude: Double
    let geohash: String
    let createdAt: Date
    let updatedAt: Date
    let isActive: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case category
        case quantity
        case expiryDate = "expiry_date"
        case shareType = "share_type"
        case location
        case suggestion
        case uploaderID = "uploader_id"
        case uploaderNickname = "uploader_nickname"
        case uploaderRating = "uploader_rating"
        case uploaderShares = "uploader_shares"
        case aiSuggestion = "ai_suggestion"
        case aiRecipes = "ai_recipes"
        case tags
        case price
        case latitude
        case longitude
        case geohash
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case isActive = "is_active"
    }
    
    // Convert to local FoodItem for UI
    func toFoodItem() -> FoodItem {
        let distance = "計算中" // Will be calculated based on user location
        let uploader = UploaderInfo(
            nickname: uploaderNickname,
            rating: uploaderRating,
            shares: uploaderShares
        )
        
        return FoodItem(
            id: UUID(uuidString: id ?? "") ?? UUID(),
            name: name,
            category: category,
            quantity: quantity,
            expires: expiryDate,
            shareType: shareType.rawValue,
            location: location,
            suggestion: suggestion,
            uploader: uploader,
            aiSuggestion: aiSuggestion,
            aiRecipes: aiRecipes.map { $0.toRecipeCard() },
            tags: tags,
            price: price,
            distance: distance
        )
    }
}

// Firebase-compatible User model
struct FirebaseUser: Codable, Identifiable {
    @DocumentID var id: String?
    let uid: String
    let name: String
    let initials: String
    let email: String
    let photoURL: String?
    let memberSince: Date
    let shareCount: Int
    let receiveCount: Int
    let isPremium: Bool
    let points: Int
    let badges: [FirebaseBadge]
    let uploads: [String]
    let favorites: [String]
    let challenges: [FirebaseChallenge]
    let fcmToken: String?
    let createdAt: Date
    let updatedAt: Date
    let isActive: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case uid
        case name
        case initials
        case email
        case photoURL = "photo_url"
        case memberSince = "member_since"
        case shareCount = "share_count"
        case receiveCount = "receive_count"
        case isPremium = "is_premium"
        case points
        case badges
        case uploads
        case favorites
        case challenges
        case fcmToken = "fcm_token"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case isActive = "is_active"
    }
    
    // Convert to local UserProfileModel for UI
    func toUserProfileModel() -> UserProfileModel {
        let model = UserProfileModel()
        model.name = name
        model.initials = initials
        model.email = email
        model.photoURL = photoURL != nil ? URL(string: photoURL!) : nil
        model.memberSince = DateFormatter.memberSince.string(from: memberSince)
        model.shareCount = shareCount
        model.receiveCount = receiveCount
        model.isPremium = isPremium
        model.points = points
        model.badges = badges.map { $0.toBadge() }
        model.uploads = uploads
        model.favorites = favorites
        model.challenges = challenges.map { $0.toChallenge() }
        return model
    }
}

// Supporting Firebase models
struct FirebaseRecipeCard: Codable {
    let emoji: String
    let title: String
    let desc: String
    
    func toRecipeCard() -> RecipeCard {
        return RecipeCard(emoji: emoji, title: title, desc: desc)
    }
}

struct FirebaseBadge: Codable, Identifiable {
    let id: String
    let name: String
    let icon: String
    let active: Bool
    let earnedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case icon
        case active
        case earnedAt = "earned_at"
    }
    
    func toBadge() -> Badge {
        return Badge(name: name, icon: icon, active: active)
    }
}

struct FirebaseChallenge: Codable, Identifiable {
    let id: String
    let title: String
    let titleZh: String
    let subtitle: String
    let subtitleZh: String
    let progress: Int
    let goal: Int
    let colorHex: String
    let startDate: Date
    let endDate: Date
    let isActive: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case titleZh = "title_zh"
        case subtitle
        case subtitleZh = "subtitle_zh"
        case progress
        case goal
        case colorHex = "color_hex"
        case startDate = "start_date"
        case endDate = "end_date"
        case isActive = "is_active"
    }
    
    func toChallenge() -> Challenge {
        return Challenge(
            title: title,
            titleZh: titleZh,
            subtitle: subtitle,
            subtitleZh: subtitleZh,
            progress: progress,
            goal: goal,
            color: Color(hex: colorHex) ?? .gray.opacity(0.5)
        )
    }
}

// Enum for share types
enum ShareType: String, Codable, CaseIterable {
    case free = "免費"
    case discounted = "優惠" 
    case donation = "捐贈"
    
    var displayName: String {
        return self.rawValue
    }
}

// MARK: - Extensions

extension DateFormatter {
    static let memberSince: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月"
        return formatter
    }()
    
    static let firebaseDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        return formatter
    }()
}

extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}