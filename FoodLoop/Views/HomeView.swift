import SwiftUI

struct HomeView: View {
    @State private var showUpload = false
    @State private var showExplore = false
    @State private var showGreenReport = false
    @EnvironmentObject var user: UserProfileModel
    @StateObject private var challengeManager = ChallengeManager.shared
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 固定在頂部的 Header
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
                
                // 可滾動的內容
                ScrollView {
                     // 歡迎詞
                    Text("歡迎回來，\(user.name)！")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(.systemGreen))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 12)
                    
                    VStack(spacing: 0) {
                        // 主要按鈕
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
                        
                        // 我的影響
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
                        
                        // 進行中挑戰
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
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 32)
                    }
                }
                .background(Color(.systemGroupedBackground))
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
                // Sync challenges with ChallengeManager
                challengeManager.syncChallengesWithUser(user)
            }
            .onChange(of: user.challenges) { oldValue, newValue in
                // Update challenges when user data changes
                challengeManager.syncChallengesWithUser(user)
            }
        }
    }
}
