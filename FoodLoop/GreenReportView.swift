import SwiftUI

struct GreenReportView: View {
    @EnvironmentObject var user: UserProfileModel
    
    // Mock 資料（未來可從 user 取得）
    var foodSaved: Double { 8.5 }
    var peopleHelped: Int { 24 }
    var co2Saved: Double { 12 }
    var moneySaved: Int { 45 }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                // 標題
                VStack(spacing: 4) {
                    Text("你的環境影響")
                        .font(.title2).fontWeight(.bold)
                        .foregroundColor(.green)
                        .frame(maxWidth: .infinity)
                }
                .padding(.top, 8)
                
                // 月度摘要 2x2
                VStack(spacing: 18) {
                    Text("月度摘要")
                        .font(.title3).fontWeight(.bold)
                        .foregroundColor(.green)
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, 2)
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 18) {
                        StatCardView(title: "節省食物", value: String(format: "%.1fkg", foodSaved))
                        StatCardView(title: "幫助人數", value: "\(peopleHelped)")
                        StatCardView(title: "減碳量", value: String(format: "%.0fkg", co2Saved))
                        StatCardView(title: "省下金額", value: "$\(moneySaved)")
                    }
                }
                .padding()
                .background(
                    LinearGradient(gradient: Gradient(colors: [Color.green.opacity(0.10), Color.green.opacity(0.03)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .cornerRadius(24)
                .padding(.horizontal)
                
                // 里程碑
                VStack(alignment: .leading, spacing: 16) {
                    Text("🎯 里程碑達成進度")
                        .font(.title3).fontWeight(.bold)
                    HStack {
                        Text("100kg 食物已節省")
                        Spacer()
                        Text("85%")
                            .foregroundColor(.green)
                            .fontWeight(.bold)
                    }
                    ProgressBarView(progress: 0.85)
                        .frame(height: 10)
                    HStack {
                        Text("50人受惠")
                        Spacer()
                        Text("48%")
                            .foregroundColor(.green)
                            .fontWeight(.bold)
                    }
                    ProgressBarView(progress: 0.48)
                        .frame(height: 10)
                }
                .padding()
                .background(Color(.systemGreen).opacity(0.1))
                .cornerRadius(18)
                .padding(.horizontal)
                
                // ESG 詳細報告
                VStack(alignment: .leading, spacing: 12) {
                    Text("📊 詳細報告")
                        .font(.title3).fontWeight(.bold)
                    Text("取得完整 ESG 風格的環境影響報告，適合分享給雇主或永續倡議。")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Button(action: { /* mock PDF 下載 */ }) {
                        HStack {
                            Image(systemName: "doc.fill")
                            Text("下載 PDF 報告")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGreen))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    Button(action: { /* mock 分享 */ }) {
                        HStack {
                            Image(systemName: "building.2.fill")
                            Text("分享給公司")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(.systemGreen), lineWidth: 1.2)
                        )
                        .foregroundColor(Color(.systemGreen))
                        .cornerRadius(12)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(18)
                .padding(.horizontal)
                
                // 影響力排名
                VStack(alignment: .leading, spacing: 10) {
                    Text("🌟 影響力排名")
                        .font(.title3).fontWeight(.bold)
                    Text("你已進入 FoodLoop 前 15% 用戶！\n繼續努力，讓世界更美好！")
                        .font(.subheadline)
                        .foregroundColor(.black)
                }
                .padding()
                .background(
                    LinearGradient(gradient: Gradient(colors: [Color.yellow.opacity(0.25), Color.yellow.opacity(0.12)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .cornerRadius(18)
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
            .padding(.top)
        }
        .navigationTitle("綠色報告")
        .navigationBarTitleDisplayMode(.inline)
    }
}
