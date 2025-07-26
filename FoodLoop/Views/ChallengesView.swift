import SwiftUI

struct ChallengesView: View {
    @EnvironmentObject var user: UserProfileModel
    @ObservedObject private var challengeManager = ChallengeManager.shared
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                // 標題
                VStack(alignment: .center, spacing: 4) {
                    Text("🏆 Challenges")
                        .font(.title2).fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                    Text("Earn Badges & Make Impact!")
                        .foregroundColor(.green)
                        .font(.headline)
                }
                .padding(.top, 8)
                
                // Active Challenges - Using ChallengeManager to match HomeView
                VStack(alignment: .leading, spacing: 18) {
                    Text("🎯 Active Challenges")
                        .font(.title3).fontWeight(.bold)
                        .padding(.bottom, 2)
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
                .padding(.horizontal)
                
                // 徽章區
                VStack(alignment: .leading, spacing: 10) {
                    Text("🏅 My Badges")
                        .font(.title3).fontWeight(.bold)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 20) {
                            ForEach(user.badges) { badge in
                                BadgeView(icon: badge.icon, label: badge.name, gray: !badge.active)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
                .padding(.horizontal)
                
                // 社群分享按鈕
                Button(action: {}) {
                    HStack {
                        Image(systemName: "iphone")
                        Text("Share to Social Media")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(.systemGray3), lineWidth: 1)
                    )
                    .cornerRadius(16)
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
            .padding(.top)
        }
        .navigationTitle("挑戰")
        .navigationBarTitleDisplayMode(.inline)
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
