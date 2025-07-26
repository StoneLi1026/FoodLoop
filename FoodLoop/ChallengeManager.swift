import Foundation
import SwiftUI
import FirebaseFirestore
import FirebaseAuth

// MARK: - Challenge Types
enum ChallengeType: String, CaseIterable {
    case sharing = "sharing_challenge"
    case ecoContainer = "eco_challenge" 
    case fridgeCleaning = "fridge_challenge"
    case zeroWaste = "zero_waste_challenge"
    
    var displayInfo: (title: String, subtitle: String, goal: Int, color: Color) {
        switch self {
        case .sharing:
            return ("分享達人挑戰", "分享10項食材", 10, .blue)
        case .ecoContainer:
            return ("環保小尖兵", "使用環保容器分享5次", 5, .green)
        case .fridgeCleaning:
            return ("冰箱清潔週", "整理3次家中冰箱", 3, .purple)
        case .zeroWaste:
            return ("Zero Waste Week", "Share 5 items this week", 5, .red)
        }
    }
}

// MARK: - Simple Challenge Manager
@MainActor
class ChallengeManager: ObservableObject {
    static let shared = ChallengeManager()
    
    @Published var activeChallenges: [Challenge] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let firebaseManager = FirebaseManager.shared
    
    private init() {
        setupDefaultChallenges()
    }
    
    // MARK: - Setup
    
    private func setupDefaultChallenges() {
        activeChallenges = ChallengeType.allCases.map { type in
            let info = type.displayInfo
            return Challenge(
                title: info.title,
                titleZh: info.title,
                subtitle: info.subtitle,
                subtitleZh: info.subtitle,
                progress: 0,
                goal: info.goal,
                color: info.color
            )
        }
    }
    
    // MARK: - Main Challenge Update Method
    
    func onFoodUpload(userID: String, userProfile: UserProfileModel) async {
        print("DEBUG: ChallengeManager.onFoodUpload called for user: \(userID)")
        
        // Update challenges that should increment on food upload
        await incrementChallenge(.sharing, for: userID, userProfile: userProfile)
        await incrementChallenge(.zeroWaste, for: userID, userProfile: userProfile)
        
        print("DEBUG: Challenge updates completed")
    }
    
    func onEcoContainerUsed(userID: String, userProfile: UserProfileModel) async {
        await incrementChallenge(.ecoContainer, for: userID, userProfile: userProfile)
    }
    
    func onFridgeCleaning(userID: String, userProfile: UserProfileModel) async {
        await incrementChallenge(.fridgeCleaning, for: userID, userProfile: userProfile)
    }
    
    // MARK: - Core Challenge Logic
    
    private func incrementChallenge(_ type: ChallengeType, for userID: String, userProfile: UserProfileModel) async {
        guard let challengeIndex = activeChallenges.firstIndex(where: { challenge in
            challenge.titleZh == type.displayInfo.title
        }) else {
            print("DEBUG: Challenge not found for type: \(type)")
            return
        }
        
        var challenge = activeChallenges[challengeIndex]
        
        // Don't increment if already completed
        guard challenge.progress < challenge.goal else {
            print("DEBUG: Challenge \(challenge.titleZh) already completed")
            return
        }
        
        // Increment progress
        let newProgress = challenge.progress + 1
        print("DEBUG: Incrementing \(challenge.titleZh): \(challenge.progress) -> \(newProgress)")
        
        // Update local challenge
        challenge = Challenge(
            title: challenge.title,
            titleZh: challenge.titleZh,
            subtitle: challenge.subtitle,
            subtitleZh: challenge.subtitleZh,
            progress: newProgress,
            goal: challenge.goal,
            color: challenge.color
        )
        
        activeChallenges[challengeIndex] = challenge
        
        // Update UserProfileModel immediately for UI
        if let userChallengeIndex = userProfile.challenges.firstIndex(where: { $0.titleZh == challenge.titleZh }) {
            userProfile.challenges[userChallengeIndex] = challenge
        } else {
            userProfile.challenges.append(challenge)
        }
        
        // Update Firebase
        await updateChallengeInFirebase(type, progress: newProgress, userID: userID, userProfile: userProfile)
        
        // Check for completion
        if newProgress >= challenge.goal {
            await handleChallengeCompletion(challenge, userID: userID, userProfile: userProfile)
        }
    }
    
    // MARK: - Firebase Operations
    
    private func updateChallengeInFirebase(_ type: ChallengeType, progress: Int, userID: String, userProfile: UserProfileModel) async {
        do {
            // Use a simple field update approach
            let userRef = Firestore.firestore().collection("users").document(userID)
            let challengeField = "challenge_progress.\(type.rawValue)"
            
            try await userRef.updateData([
                challengeField: progress,
                "updated_at": Timestamp(date: Date())
            ])
            
            print("DEBUG: Successfully updated \(type.rawValue) progress to \(progress) in Firebase")
            
        } catch {
            print("DEBUG: Failed to update challenge in Firebase: \(error)")
            errorMessage = "Failed to update challenge: \(error.localizedDescription)"
        }
    }
    
    private func handleChallengeCompletion(_ challenge: Challenge, userID: String, userProfile: UserProfileModel) async {
        print("DEBUG: Challenge completed: \(challenge.titleZh)")
        
        // Create badge
        let newBadge = Badge(
            name: challenge.titleZh,
            icon: getBadgeIcon(for: challenge),
            active: true
        )
        
        // Update local data
        userProfile.badges.append(newBadge)
        userProfile.points += 50 // Bonus points
        
        // Remove completed challenge
        if let index = activeChallenges.firstIndex(where: { $0.id == challenge.id }) {
            activeChallenges.remove(at: index)
        }
        if let index = userProfile.challenges.firstIndex(where: { $0.id == challenge.id }) {
            userProfile.challenges.remove(at: index)
        }
        
        // Update Firebase
        await updateBadgeInFirebase(newBadge, userID: userID)
    }
    
    private func updateBadgeInFirebase(_ badge: Badge, userID: String) async {
        do {
            let userRef = Firestore.firestore().collection("users").document(userID)
            
            // Add badge to user's badges array
            try await userRef.updateData([
                "badges": FieldValue.arrayUnion([
                    [
                        "name": badge.name,
                        "icon": badge.icon,
                        "active": badge.active,
                        "earned_at": Timestamp(date: Date())
                    ]
                ]),
                "points": FieldValue.increment(Int64(50)),
                "updated_at": Timestamp(date: Date())
            ])
            
            print("DEBUG: Successfully added badge: \(badge.name)")
            
        } catch {
            print("DEBUG: Failed to update badge in Firebase: \(error)")
        }
    }
    
    // MARK: - Data Loading and Sync
    
    func loadChallengeProgress(for userID: String, userProfile: UserProfileModel) async {
        isLoading = true
        
        do {
            let userRef = Firestore.firestore().collection("users").document(userID)
            let snapshot = try await userRef.getDocument()
            
            if let data = snapshot.data(),
               let challengeProgress = data["challenge_progress"] as? [String: Int] {
                
                // Update local challenges with Firebase data
                for (index, challenge) in activeChallenges.enumerated() {
                    let challengeType = getChallengeType(for: challenge)
                    if let progress = challengeProgress[challengeType.rawValue] {
                        activeChallenges[index] = Challenge(
                            title: challenge.title,
                            titleZh: challenge.titleZh,
                            subtitle: challenge.subtitle,
                            subtitleZh: challenge.subtitleZh,
                            progress: progress,
                            goal: challenge.goal,
                            color: challenge.color
                        )
                    }
                }
                
                // Update UserProfileModel
                userProfile.challenges = activeChallenges
                
                print("DEBUG: Loaded challenge progress from Firebase")
            }
            
        } catch {
            print("DEBUG: Failed to load challenge progress: \(error)")
            errorMessage = "Failed to load challenges: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // MARK: - Helper Methods
    
    private func getChallengeType(for challenge: Challenge) -> ChallengeType {
        return ChallengeType.allCases.first { type in
            type.displayInfo.title == challenge.titleZh
        } ?? .sharing
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
    
    // MARK: - Public Interface
    
    func syncWithUser(_ userProfile: UserProfileModel) {
        guard let userID = userProfile.currentUserID else { return }
        
        Task {
            await loadChallengeProgress(for: userID, userProfile: userProfile)
        }
    }
}

// MARK: - Color Extensions
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