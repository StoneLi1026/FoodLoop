import SwiftUI

struct HomeView: View {
    @State private var showUpload = false
    @State private var showExplore = false
    @State private var showGreenReport = false
    @EnvironmentObject var user: UserProfileModel
    @ObservedObject private var challengeManager = ChallengeManager.shared
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                headerView
                mainContentView
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $showUpload) {
                UploadView()
            }
            .navigationDestination(isPresented: $showExplore) {
                ExploreView()
            }
            .navigationDestination(isPresented: $showGreenReport) {
                GreenReportView()
            }
            .onAppear {
                // Load current challenge progress from Firebase
                challengeManager.syncWithUser(user)
            }
            .onChange(of: user.currentUserID) { oldValue, newValue in
                // Reload challenges when user changes
                if newValue != nil {
                    challengeManager.syncWithUser(user)
                }
            }
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 0) {
            // App 標題
            HStack(alignment: .center) {
                Image(systemName: "leaf")
                    .font(.title)
                Text("FoodLoop")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Image(systemName: "bell.fill")
                    .foregroundColor(.yellow)
            }
            .padding(.horizontal)
            .padding(.top, 10)
            .padding(.bottom, 10)
        }
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - Main Content View
    private var mainContentView: some View {
        ScrollView {
            VStack(spacing: 0) {
                welcomeSection
                actionButtonsSection
                impactSection
                challengesSection
            }
        }
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - Welcome Section
    private var welcomeSection: some View {
        Text("歡迎回來，\(user.name)！")
            .font(.title2)
            .fontWeight(.semibold)
            .foregroundColor(Color(.systemGreen))
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 12)
    }
    
    // MARK: - Action Buttons Section
    private var actionButtonsSection: some View {
        HStack(spacing: 16) {
            Button(action: { showUpload = true }) {
                HStack {
                    Image(systemName:"arrowshape.turn.up.right")
                    Text("分享食物")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGreen))
                .foregroundColor(.white)
                .cornerRadius(14)
            }
            Button(action: { showExplore = true }) {
                HStack {
                    Image(systemName: "magnifyingglass")
                    Text("尋找食物")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color(.systemGreen), lineWidth: 2)
                )
                .foregroundColor(Color(.systemGreen))
                .cornerRadius(14)
            }
        }
        .padding(.horizontal)
        .padding(.top, 10)
        .padding(.bottom, 18)
    }
    
    // MARK: - Impact Section
    private var impactSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "leaf")
                    .foregroundColor(.green)
                Text("我的影響")
                    .font(.title3)
                    .fontWeight(.bold)
            }
            .padding(.top, 8)
            
            HStack(spacing: 16) {
                StatCardView(title: "已分享", value: "\(user.shareCount)")
                StatCardView(title: "減少浪費", value: "8.5kg")
            }
            
            Button(action: { showGreenReport = true }) {
                Text("查看綠色報告")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(.systemGreen), lineWidth: 1.5)
                    )
                    .foregroundColor(Color(.systemGreen))
                    .cornerRadius(10)
            }
        }
        .padding()
        .background(Color(.systemGreen).opacity(0.08))
        .cornerRadius(22)
        .padding(.horizontal)
        .padding(.bottom, 28)
    }
    
    // MARK: - Challenges Section  
    private var challengesSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "trophy.fill")
                    .foregroundColor(.orange)
                Text("進行中挑戰")
                    .font(.title3)
                    .fontWeight(.bold)
            }
            .padding(.bottom, 8)
            
            // 挑戰項目列表 - 從 ChallengeManager 動態載入
            VStack(spacing: 12) {
                ForEach(challengeManager.activeChallenges) { challenge in
                    challengeCardView(challenge)
                }
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 32)
    }
    
    // MARK: - Challenge Card View
    private func challengeCardView(_ challenge: Challenge) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(challenge.titleZh.isEmpty ? challenge.title : challenge.titleZh)
                .font(.headline)
                .foregroundColor(.white)
            Text(challenge.subtitleZh.isEmpty ? challenge.subtitle : challenge.subtitleZh)
                .foregroundColor(.white)
            ProgressBarView(progress: CGFloat(challenge.progress) / CGFloat(challenge.goal))
                .frame(height: 10)
            Text("\(challenge.progress)/\(challenge.goal) completed")
                .font(.caption)
                .foregroundColor(.white.opacity(0.9))
        }
        .padding()
        .background(challenge.color.opacity(0.5))
        .cornerRadius(18)
    }
}
