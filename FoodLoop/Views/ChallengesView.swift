import SwiftUI

struct ChallengesView: View {
    @EnvironmentObject var user: UserProfileModel
    
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
                
                // Active Challenges
                VStack(alignment: .leading, spacing: 18) {
                    Text("🎯 Active Challenges")
                        .font(.title3).fontWeight(.bold)
                        .padding(.bottom, 2)
                    ForEach(user.challenges) { challenge in
                        VStack(alignment: .leading, spacing: 10) {
                            Text(challenge.titleZh)
                                .font(.headline)
                                .foregroundColor(.white)
                            Text(challenge.subtitleZh)
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.92))
                            ProgressBarView(progress: Double(challenge.progress) / Double(challenge.goal))
                                .frame(height: 10)
                                .padding(.vertical, 2)
                            HStack {
                                Text("\(challenge.progress)/\(challenge.goal) completed")
                                    .foregroundColor(.white)
                                Spacer()
                                Button(action: {}) {
                                    Text(challenge.progress == challenge.goal ? "完成" : "繼續")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .padding(.horizontal, 18)
                                        .padding(.vertical, 6)
                                        .background(Color.white.opacity(0.25))
                                        .foregroundColor(.white)
                                        .cornerRadius(12)
                                }
                                .disabled(challenge.progress == challenge.goal)
                                .opacity(challenge.progress == challenge.goal ? 0.5 : 1)
                            }
                        }
                        .padding()
                        .background(challenge.color)
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
    }
}
