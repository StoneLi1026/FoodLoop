import Foundation
import FirebaseFirestore
import FirebaseAuth
import CoreLocation
import GeoFireUtils

class FirebaseManager: ObservableObject {
    static let shared = FirebaseManager()
    private let db = Firestore.firestore()
    
    // Collection references
    private let usersCollection = "users"
    private let foodItemsCollection = "food_items"
    
    private init() {
        // Configure Firestore settings
        let settings = FirestoreSettings()
        settings.cacheSettings = PersistentCacheSettings()
        db.settings = settings
    }
    
    // MARK: - User Management
    
    func createOrUpdateUser(from authUser: User) async throws -> FirebaseUser {
        let userRef = db.collection(usersCollection).document(authUser.uid)
        
        // Check if user already exists
        let snapshot = try await userRef.getDocument()
        
        if snapshot.exists {
            // Update existing user and ensure they have the new badge system
            let existingUser = try snapshot.data(as: FirebaseUser.self)
            
            var userData: [String: Any] = [
                "name": authUser.displayName ?? "Unknown User",
                "email": authUser.email ?? "",
                "photo_url": authUser.photoURL?.absoluteString,
                "updated_at": Timestamp(date: Date())
            ]
            
            // Check if user needs badge system update (less than 5 badges)
            if existingUser.badges.count < 5 {
                print("DEBUG: Updating user to new 5-badge system")
                userData["badges"] = createDefaultBadges().map { badge in
                    [
                        "id": badge.id,
                        "name": badge.name,
                        "icon": badge.icon,
                        "active": badge.active,
                        "earned_at": badge.earnedAt != nil ? Timestamp(date: badge.earnedAt!) : nil
                    ]
                }
            }
            
            try await userRef.updateData(userData)
        } else {
            // Create new user
            let newUser = FirebaseUser(
                id: authUser.uid,
                uid: authUser.uid,
                name: authUser.displayName ?? "Unknown User",
                initials: String(authUser.displayName?.prefix(1) ?? "U"),
                email: authUser.email ?? "",
                photoURL: authUser.photoURL?.absoluteString,
                memberSince: Date(),
                shareCount: 0,
                receiveCount: 0,
                isPremium: false,
                points: 0,
                badges: createDefaultBadges(),
                uploads: [],
                favorites: [],
                challenges: createDefaultChallenges(),
                fcmToken: nil,
                createdAt: Date(),
                updatedAt: Date(),
                isActive: true
            )
            
            do {
                try await userRef.setData(from: newUser)
            } catch {
                // Fallback to manual data setting
                let userData: [String: Any] = [
                    "uid": newUser.uid,
                    "name": newUser.name,
                    "email": newUser.email,
                    "photo_url": newUser.photoURL,
                    "member_since": Timestamp(date: newUser.memberSince),
                    "share_count": newUser.shareCount,
                    "receive_count": newUser.receiveCount,
                    "is_premium": newUser.isPremium,
                    "points": newUser.points,
                    "created_at": Timestamp(date: newUser.createdAt),
                    "updated_at": Timestamp(date: newUser.updatedAt),
                    "is_active": newUser.isActive
                ]
                try await userRef.setData(userData)
            }
        }
        
        // Return the user data
        let updatedSnapshot = try await userRef.getDocument()
        return try updatedSnapshot.data(as: FirebaseUser.self)
    }
    
    func getUser(uid: String) async throws -> FirebaseUser? {
        let snapshot = try await db.collection(usersCollection).document(uid).getDocument()
        return try snapshot.data(as: FirebaseUser.self)
    }
    
    func updateUserPoints(uid: String, points: Int) async throws {
        let userRef = db.collection(usersCollection).document(uid)
        try await userRef.updateData([
            "points": FieldValue.increment(Int64(points)),
            "updated_at": Timestamp(date: Date())
        ])
    }
    
    func updateUserStats(uid: String, shareCount: Int? = nil, receiveCount: Int? = nil) async throws {
        let userRef = db.collection(usersCollection).document(uid)
        var updateData: [String: Any] = [
            "updated_at": Timestamp(date: Date())
        ]
        
        if let shareCount = shareCount {
            updateData["share_count"] = FieldValue.increment(Int64(shareCount))
        }
        
        if let receiveCount = receiveCount {
            updateData["receive_count"] = FieldValue.increment(Int64(receiveCount))
        }
        
        try await userRef.updateData(updateData)
    }
    
    // MARK: - Food Item Management
    
    func createFoodItem(_ item: FirebaseFoodItem) async throws -> String {
        let docRef = try await db.collection(foodItemsCollection).addDocument(from: item)
        return docRef.documentID
    }
    
    func getFoodItems(limit: Int = 50) async throws -> [FirebaseFoodItem] {
        let snapshot = try await db.collection(foodItemsCollection)
            .whereField("is_active", isEqualTo: true)
            .order(by: "created_at", descending: true)
            .limit(to: limit)
            .getDocuments()
        
        return try snapshot.documents.compactMap { document in
            try document.data(as: FirebaseFoodItem.self)
        }
    }
    
    func getFoodItemsNearLocation(
        latitude: Double,
        longitude: Double,
        radiusInKm: Double = 10.0,
        limit: Int = 50
    ) async throws -> [FirebaseFoodItem] {
        let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let radiusInM = radiusInKm * 1000
        
        // Generate geohash queries for the radius
        let queryBounds = GFUtils.queryBounds(forLocation: center, withRadius: radiusInM)
        var queries: [Query] = []
        
        for bound in queryBounds {
            let query = db.collection(foodItemsCollection)
                .whereField("is_active", isEqualTo: true)
                .whereField("geohash", isGreaterThanOrEqualTo: bound.startValue)
                .whereField("geohash", isLessThan: bound.endValue)
                .order(by: "geohash")
                .limit(to: limit)
            queries.append(query)
        }
        
        var allItems: [FirebaseFoodItem] = []
        
        // Execute all queries
        for query in queries {
            let snapshot = try await query.getDocuments()
            let items = try snapshot.documents.compactMap { document in
                try document.data(as: FirebaseFoodItem.self)
            }
            allItems.append(contentsOf: items)
        }
        
        // Filter by actual distance and remove duplicates
        let userLocation = CLLocation(latitude: latitude, longitude: longitude)
        let filteredItems = allItems.filter { item in
            let itemLocation = CLLocation(latitude: item.latitude, longitude: item.longitude)
            let distance = userLocation.distance(from: itemLocation)
            return distance <= radiusInM
        }
        
        // Remove duplicates and sort by distance
        let uniqueItems = Array(Set(filteredItems.compactMap { $0.id }).compactMap { id in
            filteredItems.first { $0.id == id }
        })
        
        return uniqueItems.sorted { item1, item2 in
            let location1 = CLLocation(latitude: item1.latitude, longitude: item1.longitude)
            let location2 = CLLocation(latitude: item2.latitude, longitude: item2.longitude)
            let distance1 = userLocation.distance(from: location1)
            let distance2 = userLocation.distance(from: location2)
            return distance1 < distance2
        }
    }
    
    func getFoodItemsByShareType(_ shareType: ShareType, limit: Int = 50) async throws -> [FirebaseFoodItem] {
        // Temporary workaround: Query without ordering to avoid composite index requirement
        // TODO: Create composite index in Firebase Console for optimal performance
        let snapshot = try await db.collection(foodItemsCollection)
            .whereField("is_active", isEqualTo: true)
            .whereField("share_type", isEqualTo: shareType.rawValue)
            .limit(to: limit)
            .getDocuments()
        
        let items = try snapshot.documents.compactMap { document in
            try document.data(as: FirebaseFoodItem.self)
        }
        
        // Sort locally by created date (descending)
        return items.sorted { $0.createdAt > $1.createdAt }
    }
    
    func getFoodItemsByUser(uid: String, limit: Int = 50) async throws -> [FirebaseFoodItem] {
        // Temporary workaround: Query without ordering to avoid composite index requirement
        // TODO: Create composite index in Firebase Console for optimal performance
        let snapshot = try await db.collection(foodItemsCollection)
            .whereField("uploader_id", isEqualTo: uid)
            .whereField("is_active", isEqualTo: true)
            .limit(to: limit)
            .getDocuments()
        
        let items = try snapshot.documents.compactMap { document in
            try document.data(as: FirebaseFoodItem.self)
        }
        
        // Sort locally by created date (descending)
        return items.sorted { $0.createdAt > $1.createdAt }
    }
    
    func updateFoodItem(id: String, updates: [String: Any]) async throws {
        var updateData = updates
        updateData["updated_at"] = Timestamp(date: Date())
        
        try await db.collection(foodItemsCollection).document(id).updateData(updateData)
    }
    
    func deleteFoodItem(id: String) async throws {
        try await db.collection(foodItemsCollection).document(id).updateData([
            "is_active": false,
            "updated_at": Timestamp(date: Date())
        ])
    }
    
    // MARK: - Real-time Listeners
    
    func listenToFoodItems(completion: @escaping ([FirebaseFoodItem]) -> Void) -> ListenerRegistration {
        return db.collection(foodItemsCollection)
            .whereField("is_active", isEqualTo: true)
            .order(by: "created_at", descending: true)
            .limit(to: 50)
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Error fetching food items: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                let items = documents.compactMap { document -> FirebaseFoodItem? in
                    try? document.data(as: FirebaseFoodItem.self)
                }
                
                completion(items)
            }
    }
    
    func listenToUser(uid: String, completion: @escaping (FirebaseUser?) -> Void) -> ListenerRegistration {
        return db.collection(usersCollection).document(uid)
            .addSnapshotListener { snapshot, error in
                guard let snapshot = snapshot else {
                    print("Error fetching user: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                let user = try? snapshot.data(as: FirebaseUser.self)
                completion(user)
            }
    }
    
    // MARK: - Helper Methods
    
    private func createDefaultBadges() -> [FirebaseBadge] {
        return [
            FirebaseBadge(id: "newcomer", name: "新手上路", icon: "star.fill", active: true, earnedAt: Date()),
            FirebaseBadge(id: "sharing_challenge", name: "分享達人挑戰", icon: "gift.fill", active: false, earnedAt: nil),
            FirebaseBadge(id: "eco_challenge", name: "環保小尖兵", icon: "leaf.fill", active: false, earnedAt: nil),
            FirebaseBadge(id: "fridge_challenge", name: "冰箱清潔週", icon: "archivebox.fill", active: false, earnedAt: nil),
            FirebaseBadge(id: "zero_waste_challenge", name: "Zero Waste Week", icon: "arrow.3.trianglepath", active: false, earnedAt: nil)
        ]
    }
    
    private func createDefaultChallenges() -> [FirebaseChallenge] {
        let now = Date()
        let weekFromNow = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: now) ?? now
        
        return [
            FirebaseChallenge(
                id: "zero_waste_week",
                title: "Zero Waste Week",
                titleZh: "Zero Waste Week",
                subtitle: "Share 5 items this week",
                subtitleZh: "分享5項食材",
                progress: 0,
                goal: 5,
                colorHex: "FF6B6B",
                startDate: now,
                endDate: weekFromNow,
                isActive: true
            ),
            FirebaseChallenge(
                id: "sharing_master",
                title: "分享達人挑戰",
                titleZh: "分享達人挑戰",
                subtitle: "Share 10 items",
                subtitleZh: "分享10項食材",
                progress: 0,
                goal: 10,
                colorHex: "4ECDC4",
                startDate: now,
                endDate: Calendar.current.date(byAdding: .month, value: 1, to: now) ?? now,
                isActive: true
            )
        ]
    }
    
    // MARK: - Badge Migration System
    
    func ensureUserHasCorrectBadges(uid: String) async throws {
        let userRef = db.collection("users").document(uid)
        
        // Get current user data
        let snapshot = try await userRef.getDocument()
        guard let userData = try? snapshot.data(as: FirebaseUser.self) else {
            print("DEBUG: User \(uid) not found for badge migration")
            return
        }
        
        // Check if migration is needed
        let hasOldRecycleIcon = userData.badges.contains { $0.icon == "recycle" }
        let hasIncorrectBadgeCount = userData.badges.count != 5
        
        if hasOldRecycleIcon || hasIncorrectBadgeCount {
            print("DEBUG: Migrating badges for user \(uid) - Count: \(userData.badges.count), HasOldIcon: \(hasOldRecycleIcon)")
            
            // Create new badge system, preserving any active states
            let defaultBadges = createDefaultBadges()
            var migratedBadges = defaultBadges
            
            // Preserve active states from old badges
            for oldBadge in userData.badges {
                if oldBadge.active {
                    // Find corresponding new badge and activate it
                    for i in 0..<migratedBadges.count {
                        if shouldActivateBadge(oldBadgeName: oldBadge.name, newBadge: migratedBadges[i]) {
                            migratedBadges[i] = FirebaseBadge(
                                id: migratedBadges[i].id,
                                name: migratedBadges[i].name,
                                icon: migratedBadges[i].icon,
                                active: true,
                                earnedAt: oldBadge.earnedAt ?? Date()
                            )
                        }
                    }
                }
            }
            
            // Update user with new badge system
            try await userRef.updateData([
                "badges": migratedBadges.map { badge in
                    [
                        "id": badge.id,
                        "name": badge.name,
                        "icon": badge.icon,
                        "active": badge.active,
                        "earned_at": badge.earnedAt != nil ? Timestamp(date: badge.earnedAt!) : nil
                    ]
                },
                "updated_at": Timestamp(date: Date())
            ])
            
            print("DEBUG: Successfully migrated badges for user \(uid)")
        } else {
            print("DEBUG: User \(uid) badges are already up to date")
        }
    }
    
    private func shouldActivateBadge(oldBadgeName: String, newBadge: FirebaseBadge) -> Bool {
        // Map old badge names to new badge names/IDs
        switch oldBadgeName {
        case "新手上路":
            return newBadge.id == "newcomer"
        case "分享達人", "分享達人挑戰":
            return newBadge.id == "sharing_challenge"
        case "綠色小尖兵", "環保小尖兵":
            return newBadge.id == "eco_challenge"
        case "冰箱清潔週":
            return newBadge.id == "fridge_challenge"
        case "Zero Waste Week":
            return newBadge.id == "zero_waste_challenge"
        default:
            return false
        }
    }
    
    // MARK: - Favorites Management
    
    func addToFavorites(uid: String, foodItemId: String) async throws {
        let userRef = db.collection("users").document(uid)
        
        try await userRef.updateData([
            "favorites": FieldValue.arrayUnion([foodItemId]),
            "updated_at": Timestamp(date: Date())
        ])
        
        print("DEBUG: Added \(foodItemId) to favorites for user \(uid)")
    }
    
    func removeFromFavorites(uid: String, foodItemId: String) async throws {
        let userRef = db.collection("users").document(uid)
        
        try await userRef.updateData([
            "favorites": FieldValue.arrayRemove([foodItemId]),
            "updated_at": Timestamp(date: Date())
        ])
        
        print("DEBUG: Removed \(foodItemId) from favorites for user \(uid)")
    }
    
    func isFavorited(uid: String, foodItemId: String, userFavorites: [String]) -> Bool {
        return userFavorites.contains(foodItemId)
    }
}

// MARK: - Extensions for Firebase compatibility

extension FirebaseFoodItem: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: FirebaseFoodItem, rhs: FirebaseFoodItem) -> Bool {
        return lhs.id == rhs.id
    }
}