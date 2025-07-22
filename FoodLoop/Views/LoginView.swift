import SwiftUI
import FirebaseAuth
import FirebaseCore
import GoogleSignIn
import GoogleSignInSwift

struct LoginView: View {
    @EnvironmentObject var userProfile: UserProfileModel
    @AppStorage("isSignedIn") var isSignedIn: Bool = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            Text("歡迎使用 FoodLoop")
                .font(.largeTitle).fontWeight(.bold)
                .foregroundColor(.green)
            Text("用 Google 帳號快速登入，開始你的綠色行動！")
                .foregroundColor(.secondary)
            Spacer()
            GoogleSignInButton {
                print("Google Sign-In Button Pressed")
                handleSignIn()
            }
            .frame(height: 50)
            .cornerRadius(12)
            .padding(.horizontal, 32)
            Spacer()
        }
        .background(
            LinearGradient(gradient: Gradient(colors: [Color.green.opacity(0.1), .white]), startPoint: .top, endPoint: .bottom)
        )
    }

    // 檢查與修正 Google 登入流程，確保彈出登入畫面
    func handleSignIn() {
        print("Handle Sign-In ...")
        // 依官方建議，從 FirebaseApp 取得 clientID
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            print("找不到 Firebase clientID")
            return
        }
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        // 取得 rootViewController (iOS 15+)
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            print("找不到 rootViewController")
            return
        }
        // 啟動 Google Sign-In 流程
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { result, error in
            if let error = error {
                print("Google 登入失敗：\(error.localizedDescription)")
                return
            }
            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString else {
                print("找不到 Google 使用者或 idToken")
                return
            }
            let accessToken = user.accessToken.tokenString
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
            Auth.auth().signIn(with: credential) { result, error in
                if let error = error {
                    print("Firebase 登入失敗：\(error.localizedDescription)")
                    return
                }
                
                print("Firebase 登入成功！")
                isSignedIn = true
                
                // Create or update user in Firestore
                Task {
                    await userProfile.createOrUpdateUser()
                }
            }
        }
    }
}
