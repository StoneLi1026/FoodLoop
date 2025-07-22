import Foundation
import Photos

enum PhotoPermissionStatus {
    case authorized
    case limited
    case denied
    case notDetermined
    case restricted
}

class PermissionsManager {
    static func checkPhotoPermission(completion: @escaping (PhotoPermissionStatus) -> Void) {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        switch status {
        case .authorized:
            completion(.authorized)
        case .limited:
            completion(.limited)
        case .denied:
            completion(.denied)
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { newStatus in
                DispatchQueue.main.async {
                    switch newStatus {
                    case .authorized:
                        completion(.authorized)
                    case .limited:
                        completion(.limited)
                    case .denied:
                        completion(.denied)
                    case .restricted:
                        completion(.restricted)
                    default:
                        completion(.notDetermined)
                    }
                }
            }
        case .restricted:
            completion(.restricted)
        @unknown default:
            completion(.notDetermined)
        }
    }
} 