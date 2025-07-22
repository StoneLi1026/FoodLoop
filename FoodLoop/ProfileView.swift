import SwiftUI
import FirebaseAuth

class UserProfileModel: ObservableObject {
    @Published var name: String = "訪客"
    @Published var initials: String = "V"
    @Published var email: String?
    @Published var photoURL: URL?
    @Published var memberSince: String = "2024年3月"
    @Published var shareCount: Int = 24
    @Published var receiveCount: Int = 18
    @Published var isPremium: Bool = true
    @Published var points: Int = 245
    @Published var badges: [Badge] = [
        Badge(name: "新手上路", icon: "star.fill", active: true),
        Badge(name: "分享達人", icon: "gift.fill", active: true),
        Badge(name: "綠色小尖兵", icon: "leaf.fill", active: false)
    ]
    @Published var uploads: [String] = ["蔬菜箱", "自製麵包"]
    @Published var favorites: [String] = ["有機蘋果", "剩餘牛奶"]
    @Published var challenges: [Challenge] = [
        Challenge(
            title: "Zero Waste Week",
            titleZh: "Zero Waste Week",
            subtitle: "Share 5 items this week",
            subtitleZh: "分享5項食材",
            progress: 3,
            goal: 5,
            color: .red.opacity(0.5)
        ),
        Challenge(
            title: "分享達人挑戰",
            titleZh: "分享達人挑戰",
            subtitle: "Share 10 items",
            subtitleZh: "分享10項食材",
            progress: 8,
            goal: 10,
            color: .blue.opacity(0.5)
        ),
        Challenge(
            title: "冰箱清潔週",
            titleZh: "冰箱清潔週",
            subtitle: "Clean your fridge 3 times",
            subtitleZh: "整理3次家中冰箱",
            progress: 1,
            goal: 3,
            color: .green.opacity(0.5)
        ),
        Challenge(
            title: "環保小尖兵",
            titleZh: "環保小尖兵",
            subtitle: "Use eco containers 5 times",
            subtitleZh: "使用環保容器分享5次",
            progress: 2,
            goal: 5,
            color: .purple.opacity(0.5)
        )
    ]
    // ...可擴充更多欄位
}

struct Badge: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let icon: String
    let active: Bool
}

struct Challenge: Identifiable {
    let id = UUID()
    let title: String
    let titleZh: String
    let subtitle: String
    let subtitleZh: String
    let progress: Int
    let goal: Int
    let color: Color
}

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
            VStack {
                Text("我的上傳")
                    .font(.title2)
                    .padding()
                List(user.uploads, id: \.self) { upload in
                    Text(upload)
                }
                Button("關閉") { showUploads = false }
                    .padding()
            }
            .presentationDetents([.medium, .large])
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