# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

FoodLoop is a food-sharing iOS application built with SwiftUI and Firebase. The app enables users to share, donate, or sell excess food items to reduce food waste through a circular economy approach.

## Development Commands

### Building and Running
```bash
# Open project in Xcode
open /Users/litsungju/Documents/FoodLoop/FoodLoop.xcodeproj

# Build from command line (if needed)
xcodebuild -project /Users/litsungju/Documents/FoodLoop/FoodLoop.xcodeproj -scheme FoodLoop -configuration Debug build
```

### Testing
```bash
# Run unit tests
xcodebuild test -project /Users/litsungju/Documents/FoodLoop/FoodLoop.xcodeproj -scheme FoodLoop -destination 'platform=iOS Simulator,name=iPhone 15'

# Run UI tests
xcodebuild test -project /Users/litsungju/Documents/FoodLoop/FoodLoop.xcodeproj -scheme FoodLoop -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:FoodLoopUITests
```

## Architecture Overview

### App Structure
- **Entry Point**: `FoodLoopApp.swift` - Main app with Firebase configuration and Google Sign-In setup
- **Main Navigation**: Tab-based architecture with 5 sections (Home, Explore, Upload, Chat, Profile)
- **State Management**: Uses `@StateObject` and `@EnvironmentObject` for shared state

### Key Components
- **Components.swift**: Contains all data models (`FoodItem`, `FoodRepository`, `UserProfileModel`) and reusable UI components
- **Authentication**: Google Sign-In integration with Firebase Auth
- **Data Layer**: Currently uses mock data; designed for Firebase Firestore integration

### View Architecture
- **HomeView**: Main dashboard with user stats and quick actions
- **ExploreView**: Food discovery with search/filter capabilities  
- **UploadView**: Food sharing interface with photo upload and location selection
- **ProfileView**: User profile management and statistics
- **LoginView**: Google Sign-In authentication flow

### Dependencies
- Firebase iOS SDK v11.14.0 (Auth, Firestore, Analytics)
- Google Sign-In iOS v8.0.0
- Native SwiftUI for all UI components

## Development Notes

### Firebase Configuration
- `GoogleService-Info.plist` contains Firebase configuration
- `Info.plist` includes URL schemes for Google Sign-In
- Currently uses mock data; real Firebase integration needed for production

### State Management Pattern
```swift
// Global state objects injected at app level
@StateObject private var foodRepository = FoodRepository()
@StateObject private var userProfile = UserProfileModel()

// Accessed in views via environment objects
@EnvironmentObject var foodRepository: FoodRepository
```

### UI Patterns
- Traditional Chinese language interface
- Green theme (`#systemGreen`) throughout app
- Consistent use of `NavigationStack` and sheet presentations
- Reusable components in `Components.swift`

### Photo Handling
- Uses `PhotosPicker` for multi-photo selection
- `PermissionsManager.swift` handles photo library permissions
- Image upload/storage implementation pending

### Testing Structure
- Swift Testing framework
- Separate targets: `FoodLoopTests` (unit) and `FoodLoopUITests` (UI)
- Currently minimal test coverage

## File Organization

All Swift files are in the main `FoodLoop/` directory:
- App entry and main views
- Reusable components and data models
- Authentication and permissions
- All business logic in single location

## Current Limitations

- Backend integration incomplete (uses mock data)
- Real-time chat system needs implementation  
- Map/location services need full integration
- Image upload/storage pending Firebase Storage setup
- Limited test coverage