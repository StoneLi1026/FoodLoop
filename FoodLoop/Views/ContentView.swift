//
//  ContentView.swift
//  FoodLoop
//
//  Created by 李宗儒 on 2025/6/14.
//

import SwiftUI

struct ContentView: View {
    @StateObject var userProfile = UserProfileModel()

    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("首頁", systemImage: "house") }
            ExploreView()
                .tabItem { Label("探索", systemImage: "magnifyingglass") }
            UploadView()
                .tabItem { Label("上傳", systemImage: "plus.circle") }
            ChatView()
                .tabItem { Label("聊天", systemImage: "bubble.left.and.bubble.right") }
            ProfileView()
                .tabItem { Label("個人", systemImage: "person.crop.circle") }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(FoodRepository())
        .environmentObject(UserProfileModel())

}

//hex with opacity
extension Color {
    init(hex: String, alpha: Double = 1.0) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if hexSanitized.hasPrefix("#") {
            hexSanitized.remove(at: hexSanitized.startIndex)
        }

        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)

        let r = Double((rgb >> 16) & 0xFF) / 255
        let g = Double((rgb >> 8) & 0xFF) / 255
        let b = Double(rgb & 0xFF) / 255

        self.init(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }
}
