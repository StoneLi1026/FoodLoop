import Foundation
import SwiftUI
import FirebaseFirestore
import FirebaseAuth

// MARK: - Cached Challenge Model
struct CachedChallenge: Codable {
    let id: String
    let title: String
    let titleZh: String
    let subtitle: String
    let subtitleZh: String
    let progress: Int
    let goal: Int
    let colorHex: String
}

// MARK: - Challenge Types
enum ChallengeType: String, CaseIterable {
    case sharing = "sharing"
    case ecoContainer = "eco_container"
    case fridgeCleaning = "fridge_cleaning"
    case zeroWaste = "zero_waste"
    
    var displayName: String {
        switch self {
        case .sharing:
            return "分享達人挑戰"
        case .ecoContainer:
            return "環保小尖兵"
        case .fridgeCleaning:
            return "冰箱清潔週"
        case .zeroWaste:
            return "Zero Waste Week"
        }
    }
}

// MARK: - Challenge Manager
@MainActor
class ChallengeManager: ObservableObject {
    static let shared = ChallengeManager()
    
    @Published var activeChallenges: [Challenge] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let firebaseManager = FirebaseManager.shared
    private var listener: ListenerRegistration?
    
    // Local storage for challenges
    private let challengesKey = "cached_challenges"
    private let lastSyncKey = "last_challenge_sync"
    
    private init() {
        loadCachedChallenges()
        setupDefaultChallenges()
    }
    
    deinit {
        listener?.remove()
    }
    
    // MARK: - Setup Methods
    
    private func setupDefaultChallenges() {
        // Default challenges that match your existing UI design
        activeChallenges = [
            Challenge(
                title: "Zero Waste Week",
                titleZh: "Zero Waste Week",
                subtitle: "Share 5 items this week",
                subtitleZh: "Share 5 items this week",
                progress: 0, // Start at 0 for new users
                goal: 5,
                color: Color.red
            ),
            Challenge(
                title: "分享達人挑戰",
                titleZh: "分享達人挑戰",
                subtitle: "分享10項食材",
                subtitleZh: "分享10項食材",
                progress: 0,
                goal: 10,
                color: Color.blue
            ),
            Challenge(
                title: "冰箱清潔週",
                titleZh: "冰箱清潔週",
                subtitle: "整理3次家中冰箱",
                subtitleZh: "整理3次家中冰箱",
                progress: 0,
                goal: 3,
                color: Color.green
            ),
            Challenge(
                title: "環保小尖兵",
                titleZh: "環保小尖兵",
                subtitle: "使用環保容器分享5次",
                subtitleZh: "使用環保容器分享5次",
                progress: 0,
                goal: 5,
                color: Color.purple
            )
        ]
    }
    
    // MARK: - Local Storage
    
    private func loadCachedChallenges() {
        if let data = UserDefaults.standard.data(forKey: challengesKey),
           let cachedChallenges = try? JSONDecoder().decode([CachedChallenge].self, from: data) {
            
            activeChallenges = cachedChallenges.map { cached in
                Challenge(
                    title: cached.title,
                    titleZh: cached.titleZh,
                    subtitle: cached.subtitle,
                    subtitleZh: cached.subtitleZh,
                    progress: cached.progress,
                    goal: cached.goal,
                    color: Color(hex: cached.colorHex) ?? .gray
                )
            }
        }
    }
    
    private func saveChallengesLocally() {
        let cachedChallenges = activeChallenges.map { challenge in
            CachedChallenge(
                id: challenge.id.uuidString,
                title: challenge.title,
                titleZh: challenge.titleZh,
                subtitle: challenge.subtitle,
                subtitleZh: challenge.subtitleZh,
                progress: challenge.progress,
                goal: challenge.goal,
                colorHex: challenge.color.toHexString()
            )
        }
        
        if let data = try? JSONEncoder().encode(cachedChallenges) {
            UserDefaults.standard.set(data, forKey: challengesKey)
            UserDefaults.standard.set(Date(), forKey: lastSyncKey)
        }
    }
    
    private func shouldSyncWithServer() -> Bool {
        guard let lastSync = UserDefaults.standard.object(forKey: lastSyncKey) as? Date else {
            return true // First time, should sync
        }
        
        // Sync every 6 hours
        return Date().timeIntervalSince(lastSync) > 6 * 60 * 60
    }
    
    // MARK: - User Challenge Sync
    
    func syncChallengesWithUser(_ userProfile: UserProfileModel) {
        if !userProfile.challenges.isEmpty && shouldSyncWithServer() {
            // Use challenges from Firebase if available and need sync
            activeChallenges = userProfile.challenges
            saveChallengesLocally()
        } else if !userProfile.challenges.isEmpty {
            // Use Firebase data but don't need full sync
            activeChallenges = userProfile.challenges
        } else if let currentUserID = userProfile.currentUserID {
            // Initialize challenges for new user
            Task {
                await initializeChallengesForNewUser(uid: currentUserID)
            }
        }
    }
    
    private func initializeChallengesForNewUser(uid: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Get current user document
            if let user = try await firebaseManager.getUser(uid: uid) {
                // Update user with default challenges
                let firebaseChallenges = activeChallenges.map { challenge in
                    FirebaseChallenge(
                        id: challenge.id.uuidString,
                        title: challenge.title,
                        titleZh: challenge.titleZh,
                        subtitle: challenge.subtitle,
                        subtitleZh: challenge.subtitleZh,
                        progress: 0,
                        goal: challenge.goal,
                        colorHex: challenge.color.toHexString(),
                        startDate: Date(),
                        endDate: Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date(),
                        isActive: true
                    )
                }
                
                // Update user document in Firebase
                let userRef = Firestore.firestore().collection("users").document(uid)
                try await userRef.updateData([
                    "challenges": firebaseChallenges.map { try Firestore.Encoder().encode($0) },
                    "updated_at": Timestamp(date: Date())
                ])
            }
            isLoading = false
        } catch {
            errorMessage = "Failed to initialize challenges: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    // MARK: - Challenge Progress Tracking
    
    func incrementChallenge(type: ChallengeType, userID: String) async {
        guard let challengeIndex = activeChallenges.firstIndex(where: { challenge in
            switch type {
            case .sharing:
                return challenge.titleZh == "分享達人挑戰" || challenge.title == "分享達人挑戰"
            case .zeroWaste:
                return challenge.titleZh == "Zero Waste Week" || challenge.title == "Zero Waste Week"
            case .ecoContainer:
                return challenge.titleZh == "環保小尖兵" || challenge.title == "環保小尖兵"
            case .fridgeCleaning:
                return challenge.titleZh == "冰箱清潔週" || challenge.title == "冰箱清潔週"
            }
        }) else {
            print("DEBUG: No challenge found for type \(type)")
            return
        }
        
        var challenge = activeChallenges[challengeIndex]
        print("DEBUG: Found challenge '\(challenge.titleZh)' with progress \(challenge.progress)/\(challenge.goal)")
        
        // Don't increment if already completed
        guard challenge.progress < challenge.goal else { 
            print("DEBUG: Challenge already completed")
            return 
        }
        
        // Increment progress
        challenge = Challenge(
            title: challenge.title,
            titleZh: challenge.titleZh,
            subtitle: challenge.subtitle,
            subtitleZh: challenge.subtitleZh,
            progress: challenge.progress + 1,
            goal: challenge.goal,
            color: challenge.color
        )
        
        activeChallenges[challengeIndex] = challenge
        print("DEBUG: Incremented challenge to \(challenge.progress)/\(challenge.goal)")
        
        // Save locally for performance
        saveChallengesLocally()
        
        // Update Firebase
        await updateChallengeInFirebase(challenge: challenge, userID: userID)
        
        print("DEBUG: Challenge update completed for \(challenge.titleZh)")
        
        // Check if challenge is completed
        if challenge.progress >= challenge.goal {
            await convertChallengeToeBadge(challenge: challenge, userID: userID)
        }
    }
    
    private func updateChallengeInFirebase(challenge: Challenge, userID: String) async {
        do {
            let userRef = Firestore.firestore().collection("users").document(userID)
            
            // Get current user data
            let snapshot = try await userRef.getDocument()
            var userData = snapshot.data() ?? [:]
            
            if var challenges = userData["challenges"] as? [[String: Any]] {
                // Find and update the specific challenge
                for (index, challengeData) in challenges.enumerated() {
                    if let id = challengeData["id"] as? String,
                       id == challenge.id.uuidString {
                        challenges[index]["progress"] = challenge.progress
                        challenges[index]["updated_at"] = Timestamp(date: Date())
                        break
                    }
                }
                
                // Update Firebase
                try await userRef.updateData([
                    "challenges": challenges,
                    "updated_at": Timestamp(date: Date())
                ])
            }
        } catch {
            errorMessage = "Failed to update challenge: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Badge Conversion
    
    private func convertChallengeToeBadge(challenge: Challenge, userID: String) async {
        do {
            let userRef = Firestore.firestore().collection("users").document(userID)
            
            // Create badge from completed challenge
            let newBadge = FirebaseBadge(
                id: "badge_\(challenge.id.uuidString)",
                name: challenge.titleZh,
                icon: getBadgeIcon(for: challenge),
                active: true,
                earnedAt: Date()
            )
            
            // Get current user data
            let snapshot = try await userRef.getDocument()
            var userData = snapshot.data() ?? [:]
            
            // Add badge
            var badges = userData["badges"] as? [[String: Any]] ?? []
            let badgeData = try Firestore.Encoder().encode(newBadge)
            badges.append(badgeData)
            
            // Remove completed challenge from active challenges
            if var challenges = userData["challenges"] as? [[String: Any]] {
                challenges.removeAll { challengeData in
                    if let id = challengeData["id"] as? String {
                        return id == challenge.id.uuidString
                    }
                    return false
                }
                userData["challenges"] = challenges
            }
            
            // Update Firebase
            try await userRef.updateData([
                "badges": badges,
                "challenges": userData["challenges"] ?? [],
                "points": FieldValue.increment(Int64(50)), // Bonus points for completing challenge
                "updated_at": Timestamp(date: Date())
            ])
            
            // Remove from local active challenges
            activeChallenges.removeAll { $0.id == challenge.id }
            
        } catch {
            errorMessage = "Failed to convert challenge to badge: \(error.localizedDescription)"
        }
    }
    
    private func getBadgeIcon(for challenge: Challenge) -> String {
        if challenge.titleZh.contains("分享") {
            return "gift.fill"
        } else if challenge.titleZh.contains("環保") {
            return "leaf.fill"
        } else if challenge.titleZh.contains("冰箱") {
            return "archivebox.fill"
        } else if challenge.title.contains("Zero Waste") {
            return "recycle"
        } else {
            return "star.fill"
        }
    }
    
    // MARK: - Action Triggers
    
    func onFoodUpload(userID: String, useEcoContainer: Bool = false) async {
        print("DEBUG: onFoodUpload called for user \(userID), useEcoContainer: \(useEcoContainer)")
        print("DEBUG: Active challenges count: \(activeChallenges.count)")
        
        // Increment sharing challenges
        await incrementChallenge(type: .sharing, userID: userID)
        await incrementChallenge(type: .zeroWaste, userID: userID)
        
        // Increment eco container challenge if applicable
        if useEcoContainer {
            await incrementChallenge(type: .ecoContainer, userID: userID)
        }
    }
    
    func onFridgeCleaningAction(userID: String) async {
        await incrementChallenge(type: .fridgeCleaning, userID: userID)
    }
    
    func getActiveChallengesCount() -> Int {
        return activeChallenges.count
    }
    
    func getCompletedChallengesThisMonth(userProfile: UserProfileModel) -> Int {
        // This would calculate based on badges earned this month
        return userProfile.badges.filter { $0.active }.count
    }
}

// MARK: - Color Extension
extension Color {
    func toHexString() -> String {
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        let r = Int(red * 255)
        let g = Int(green * 255)
        let b = Int(blue * 255)
        
        return String(format: "%02X%02X%02X", r, g, b)
    }
}