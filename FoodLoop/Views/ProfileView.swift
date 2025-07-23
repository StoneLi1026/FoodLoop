import SwiftUI
import FirebaseAuth
import FirebaseFirestore

class UserProfileModel: ObservableObject {
    @Published var name: String = "訪客"
    @Published var initials: String = "V"
    @Published var email: String?
    @Published var photoURL: URL?
    @Published var memberSince: String = "2024年3月"
    @Published var shareCount: Int = 0
    @Published var receiveCount: Int = 0
    @Published var isPremium: Bool = false
    @Published var points: Int = 0
    @Published var badges: [Badge] = []
    @Published var uploads: [String] = []
    @Published var favorites: [String] = []
    @Published var challenges: [Challenge] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let firebaseManager = FirebaseManager.shared
    private var listener: ListenerRegistration?
    
    var currentUserID: String? {
        return Auth.auth().currentUser?.uid
    }
    
    init() {
        setupAuthListener()
    }
    
    deinit {
        listener?.remove()
    }
    
    // Set up authentication state listener
    private func setupAuthListener() {
        Auth.auth().addStateDidChangeListener { [weak self] auth, user in
            guard let self = self else { return }
            
            if let user = user {
                self.setupUserListener(uid: user.uid)
            } else {
                self.resetToGuestMode()
            }
        }
    }
    
    // Set up real-time listener for user data
    private func setupUserListener(uid: String) {
        listener?.remove() // Remove previous listener if any
        
        listener = firebaseManager.listenToUser(uid: uid) { [weak self] firebaseUser in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if let firebaseUser = firebaseUser {
                    let userModel = firebaseUser.toUserProfileModel()
                    self.name = userModel.name
                    self.initials = userModel.initials
                    self.email = userModel.email
                    self.photoURL = userModel.photoURL
                    self.memberSince = userModel.memberSince
                    self.shareCount = userModel.shareCount
                    self.receiveCount = userModel.receiveCount
                    self.isPremium = userModel.isPremium
                    self.points = userModel.points
                    self.badges = userModel.badges
                    self.uploads = userModel.uploads
                    self.favorites = userModel.favorites
                    self.challenges = userModel.challenges
                    self.isLoading = false
                } else {
                    self.resetToGuestMode()
                }
            }
        }
    }
    
    // Create or update user in Firebase after authentication
    func createOrUpdateUser() async {
        guard let currentUser = Auth.auth().currentUser else {
            await MainActor.run {
                self.errorMessage = "No authenticated user found"
            }
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let _ = try await firebaseManager.createOrUpdateUser(from: currentUser)
            // User data will be updated automatically through the listener
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to sync user data: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    // Update user points
    func addPoints(_ points: Int) async {
        guard let uid = currentUserID else { return }
        
        do {
            try await firebaseManager.updateUserPoints(uid: uid, points: points)
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to update points: \(error.localizedDescription)"
            }
        }
    }
    
    // Update user stats
    func updateStats(shareCount: Int? = nil, receiveCount: Int? = nil) async {
        guard let uid = currentUserID else { return }
        
        do {
            try await firebaseManager.updateUserStats(uid: uid, shareCount: shareCount, receiveCount: receiveCount)
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to update stats: \(error.localizedDescription)"
            }
        }
    }
    
    // Reset to guest mode
    private func resetToGuestMode() {
        listener?.remove()
        
        name = "訪客"
        initials = "V"
        email = nil
        photoURL = nil
        memberSince = "未登入"
        shareCount = 0
        receiveCount = 0
        isPremium = false
        points = 0
        badges = []
        uploads = []
        favorites = []
        challenges = []
        isLoading = false
        errorMessage = nil
    }
    
    // Sign out
    func signOut() async {
        do {
            try Auth.auth().signOut()
            await MainActor.run {
                self.resetToGuestMode()
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to sign out: \(error.localizedDescription)"
            }
        }
    }
}

// Badge and Challenge structs moved to Components.swift

// MARK: - Profile Header View
struct ProfileHeaderView: View {
    @ObservedObject var user: UserProfileModel
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Circle()
                    .fill(Color(.systemGreen))
                    .frame(width: 64, height: 64)
                    .overlay(Text(user.initials).font(.largeTitle).foregroundColor(.white))
                VStack(alignment: .leading, spacing: 4) {
                    Text(user.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("會員自 \(user.memberSince)")
                        .foregroundColor(.secondary)
                    HStack(spacing: 12) {
                        Text("\(user.shareCount) 次分享")
                        Text("·")
                        Text("\(user.receiveCount) 次領取")
                    }
                    .foregroundColor(.green)
                    .font(.subheadline)
                }
                Spacer()
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Activities View
struct ActivitiesView: View {
    @Binding var showUploads: Bool
    @Binding var showFavorites: Bool
    @Binding var showGreenReport: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("📱 我的活動")
                .font(.headline)
                .padding(.bottom, 8)
            ActivityRow(icon: "square.and.arrow.up", title: "我的上傳") { showUploads = true }
            Divider()
            ActivityRow(icon: "heart.fill", title: "收藏") { showFavorites = true }
            Divider()
            ActivityRow(icon: "chart.bar.fill", title: "分享紀錄") { }
            Divider()
            ActivityRow(icon: "leaf.fill", title: "綠色報告") { showGreenReport = true }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(18)
        .shadow(color: Color(.black).opacity(0.04), radius: 4, x: 0, y: 2)
        .padding(.horizontal)
    }
}

// MARK: - Membership View
struct MembershipView: View {
    @ObservedObject var user: UserProfileModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("💎 會員資格")
                    .font(.headline)
                Spacer()
                if user.isPremium {
                    Text("Active")
                        .foregroundColor(.green)
                        .fontWeight(.bold)
                }
            }
            HStack {
                Text("狀態：")
                Text(user.isPremium ? "高級會員" : "一般會員")
                    .fontWeight(.bold)
                    .foregroundColor(.green)
            }
            HStack {
                Text("FoodLoop 點數：")
                Text("\(user.points) pts")
                    .fontWeight(.bold)
                    .foregroundColor(.green)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(18)
        .shadow(color: Color(.black).opacity(0.04), radius: 4, x: 0, y: 2)
        .padding(.horizontal)
    }
}

// MARK: - Badges View
struct BadgesView: View {
    @ObservedObject var user: UserProfileModel
    @Binding var showChallenges: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("徽章")
                .font(.headline)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 18) {
                    ForEach(user.badges) { badge in
                        Button(action: { showChallenges = true }) {
                            VStack {
                                Image(systemName: badge.icon)
                                    .resizable()
                                    .frame(width: 36, height: 36)
                                    .foregroundColor(.yellow)
                                    .opacity(badge.active ? 1.0 : 0.3)
                                Text(badge.name)
                                    .font(.caption)
                                    .foregroundColor(.primary)
                                    .opacity(badge.active ? 1.0 : 0.3)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(18)
        .shadow(color: Color(.black).opacity(0.04), radius: 4, x: 0, y: 2)
        .padding(.horizontal)
    }
}

// MARK: - Main Profile View
struct ProfileView: View {
    @EnvironmentObject var user: UserProfileModel
    @AppStorage("isSignedIn") var isSignedIn: Bool = false
    @State private var showUploads = false
    @State private var showFavorites = false
    @State private var showChallenges = false
    @State private var showAdminPanel = false
    @State private var showGreenReport = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    ProfileHeaderView(user: user)
                    ActivitiesView(showUploads: $showUploads,
                                 showFavorites: $showFavorites,
                                 showGreenReport: $showGreenReport)
                    MembershipView(user: user)
                    BadgesView(user: user, showChallenges: $showChallenges)
                    
                    // Explanation Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("說明")
                            .font(.headline)
                        Text("了解您的貢獻如何幫助環境！")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Button(action: { showAdminPanel = true }) {
                            Text("前往管理員資訊")
                                .font(.body)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(18)
                    .shadow(color: Color(.black).opacity(0.04), radius: 4, x: 0, y: 2)
                    .padding(.horizontal)
                    
                    // Logout Button
                    Button(action: handleLogout) {
                        Text("登出")
                            .font(.body)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 24)
                }
                .padding(.top, 16)
            }
            .navigationTitle("個人資訊")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $showGreenReport) {
                GreenReportView()
            }
        }
        .sheet(isPresented: $showUploads) {
            MyUploadsView(user: user, isPresented: $showUploads)
        }
        .sheet(isPresented: $showFavorites) {
            VStack {
                Text("收藏")
                    .font(.title2)
                    .padding()
                List(user.favorites, id: \.self) { fav in
                    Text(fav)
                }
                Button("關閉") { showFavorites = false }
                    .padding()
            }
            .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showChallenges) {
            ChallengesView().environmentObject(user)
        }
        .sheet(isPresented: $showAdminPanel) {
            AdminPanelView()
        }
    }

    func handleLogout() {
        do {
            try Auth.auth().signOut()
            isSignedIn = false
        } catch {
            print(error.localizedDescription)
        }
    }
}

// MARK: - Activity Row View
struct ActivityRow: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(.green)
                    .frame(width: 24, height: 24, alignment: .center)
                Text(title)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .frame(width: 20, alignment: .center)
            }
            .padding(.vertical, 10)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - My Uploads View
struct MyUploadsView: View {
    @ObservedObject var user: UserProfileModel
    @Binding var isPresented: Bool
    @State private var userFoodItems: [FoodItem] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    private let firebaseManager = FirebaseManager.shared
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("載入中...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if userFoodItems.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "tray")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        Text("尚未上傳任何食物")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("開始分享食物來幫助社區！")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(userFoodItems) { item in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(item.name)
                                            .font(.headline)
                                        Text(item.category)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    VStack(alignment: .trailing) {
                                        Text(item.price ?? "免費")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.green)
                                        Text(item.expires.toRelativeExpireString())
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                // Tags
                                if !item.tags.isEmpty {
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 6) {
                                            ForEach(item.tags, id: \.self) { tag in
                                                Text(tag)
                                                    .font(.caption)
                                                    .padding(.horizontal, 8)
                                                    .padding(.vertical, 4)
                                                    .background(Color(.systemGreen).opacity(0.1))
                                                    .foregroundColor(.green)
                                                    .cornerRadius(8)
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }
            }
            .navigationTitle("我的上傳")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("關閉") {
                        isPresented = false
                    }
                }
            }
            .onAppear {
                loadUserUploads()
            }
        }
        .presentationDetents([.medium, .large])
    }
    
    private func loadUserUploads() {
        guard let currentUserID = user.currentUserID else {
            print("DEBUG: MyUploadsView - No current user ID")
            errorMessage = "用戶未登入"
            isLoading = false
            return
        }
        
        print("DEBUG: MyUploadsView - Loading uploads for user: \(currentUserID)")
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let firebaseItems = try await firebaseManager.getFoodItemsByUser(uid: currentUserID)
                print("DEBUG: MyUploadsView - Found \(firebaseItems.count) items for user")
                
                await MainActor.run {
                    self.userFoodItems = firebaseItems.map { $0.toFoodItem() }
                    self.isLoading = false
                    print("DEBUG: MyUploadsView - Updated UI with \(self.userFoodItems.count) items")
                }
            } catch {
                print("DEBUG: MyUploadsView - Error loading user uploads: \(error)")
                await MainActor.run {
                    self.errorMessage = "載入失敗: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
}