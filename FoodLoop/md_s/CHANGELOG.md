# Changelog

All notable changes to the FoodLoop project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

### Importance Levels
- ***Major Feature***: Core functionality or significant architectural changes
- **Important Feature**: Notable improvements or new capabilities  
- *Minor Feature*: Small enhancements or utility additions

## [Unreleased]

## [0.4.0] - 2025-08-04

### Added
- ***Complete Favorites System***: Interactive heart toggle functionality in ExploreView with real-time Firebase synchronization
- ***FavoritesView***: Dedicated favorites page accessible from ProfileView with consistent UI design matching MyUploadsView patterns
- **Heart Animation**: Smooth scale animation when toggling favorites (red for favorited, gray for non-favorited)
- **Badge System Migration**: Automatic data migration ensuring all users have exactly 5 badges (1 active newcomer + 4 challenge badges)
- **Enhanced Challenge-Badge Mapping**: Perfect 1:1 relationship between 4 challenges and 4 corresponding challenge badges
- *Firebase Favorites Operations*: `addToFavorites()` and `removeFromFavorites()` with array-based storage

### Fixed
- ***Points Double Counting***: Removed local points addition to prevent users getting +100 instead of +50 points for challenge completion
- ***Badge Data Consistency***: Implemented migration system to ensure uniform badge structure across all Firebase users
- ***Badge Icon Migration***: Automatic update from old 'recycle' icon to 'arrow.3.trianglepath' for Zero Waste Week badge
- **Build Errors**: Fixed missing `firebaseId` parameter in FoodRepository distance calculations
- **Challenge Badge Activation**: Badges now properly activate when challenges are completed (no more duplicate badge creation)
- **Heart Toggle State**: Disabled heart button for mock data items without Firebase IDs to prevent errors

### Changed
- ***FoodItem Model***: Added `firebaseId` field to support favorites functionality and Firebase document linking
- **FoodCardView**: Now requires `userProfile` parameter for heart toggle and favorites state management
- **UserProfileModel**: Enhanced with automatic badge migration trigger during user setup
- **Challenge System**: Now activates existing badges instead of creating new ones when challenges complete
- *Firebase Badge Structure*: Updated to include `id` field for better tracking and migration support

### Technical
- **Real-Time Sync**: Firestore listeners ensure favorites stay synchronized between ExploreView and ProfileView
- **Migration System**: Backward-compatible badge migration preserves existing active badge states
- **Debug Infrastructure**: Enhanced logging for troubleshooting favorites operations and badge migrations
- **Data Validation**: Proper handling of missing Firebase IDs and empty favorites arrays
- *UI Consistency*: FavoritesView follows established patterns from MyUploadsView (loading states, empty states, Chinese text)

## [0.3.1] - 2025-08-03

### Added
- **Pull-to-Refresh**: ExploreView now supports pull-to-refresh functionality for real-time food data updates
- ***Flexible Tag Layout System***: Implemented intelligent tag wrapping that properly handles Chinese text without breaking words
- **Enhanced Debug Logging**: Comprehensive logging throughout FoodRepository, ExploreView, and ProfileView for better troubleshooting

### Fixed
- ***Tag Layout for Chinese Text***: Fixed tags being broken into individual characters ([有] [自] [農場] 機 製 直送) - now displays properly ([有機] [自製] [農場直送])
- ***Real-Time Data Sync***: Fixed food items not appearing immediately after upload - users no longer need to restart app
- ***Firebase Decoding Errors***: Resolved keyNotFound errors for `image_urls` and `id` fields in older Firebase data
- **MainActor Threading**: Fixed "Publishing changes from background threads" warnings in ProfileView
- **Profile Re-sync**: Added manual profile re-sync functionality for troubleshooting user data issues

### Changed
- ***Text Width Calculation***: Implemented accurate UIKit-based text measurement for proper Chinese character width calculation
- **FlexibleTagsView**: Enhanced with precise text measurement to prevent word breaking
- **Firebase Models**: Made `imageURLs` optional and added custom decoders for backward compatibility with older data
- **Error Handling**: Improved error handling for missing fields in Firebase documents

### Technical
- **UIKit Integration**: Added NSAttributedString-based text width calculation for accurate Chinese text measurement
- **FlexibleView Layout**: Enhanced generic layout system with proper width estimation
- **Backward Compatibility**: Custom decoders handle missing fields in older Firebase documents
- **Debug Infrastructure**: Added comprehensive debug logging for data flow tracking

## [0.3.0] - 2025-07-26

### Added
- ***Complete Challenge/Mission System***: Fully rebuilt real-time progress tracking system with automatic badge conversion
- ***Points Reward System***: Users earn 10 points per upload + 50 bonus points for completing challenges
- **Tag-Based Filtering**: ExploreView filters now work with food tags/labels instead of share types
- **Real-Time Progress Bars**: Challenge progress updates immediately when users upload food (+1 per upload)
- **Automatic Badge Conversion**: Challenges disappear and convert to badges when goals are reached
- *Consistent Challenge IDs*: Challenges now use title-based IDs for proper SwiftUI tracking

### Fixed
- ***Challenge Progress Tracking***: Fixed progress bars not updating in ChallengesView while HomeView stats worked correctly
- ***ProfileView My Uploads***: Resolved empty uploads section with proper Firebase query handling and composite index workaround
- ***ExploreView Filters***: Changed from server-side share type filtering to client-side tag filtering for better performance
- **ChallengeManager Sync**: Fixed data flow between ChallengeManager and UserProfileModel for real-time UI updates
- **Firebase Query Optimization**: Implemented local sorting to avoid composite index requirements temporarily

### Changed
- ***Challenge System Architecture***: Completely rebuilt with simplified, reliable Firebase integration
- **Challenge Progress Storage**: Uses simple field-based storage (`challenge_progress.{type}`) instead of complex arrays
- **Filter System**: ExploreView now filters by food tags ("有機", "自製", "環保", etc.) instead of share types
- *Challenge Initialization*: Fresh start approach - progress begins from today, not historical uploads

### Technical
- **Simplified Firebase Operations**: Reduced complex document operations to simple field updates
- **Debug Logging**: Comprehensive logging for challenge progress tracking and filtering
- **Code Cleanup**: Removed 625 lines of complex legacy code, added 291 lines of streamlined logic
- *Firestore Index Configuration*: Added firestore.indexes.json for future composite index deployment

## [0.2.2] - 2025-07-23

### Fixed
- ***Challenge Progress Logic***: Fixed exact challenge matching in ChallengeManager with proper string comparison  
- **Share Type Filter Debug**: Added comprehensive debug logging for share type filtering issues
- *Challenge Increment Flow*: Verified challenge progress +1 per upload with badge conversion when completed

### Technical
- **Debug Logging**: Enhanced ChallengeManager and ExploreView with detailed progress tracking logs
- **Challenge Matching**: Replaced contains() logic with exact switch-case matching for reliable challenge detection

## [0.2.1] - 2025-07-23

### Fixed
- ***ExploreView Food Display***: Fixed uploaded food not appearing in ExploreView by properly handling "全部" (All) filter
- ***Photo Upload Integration***: Implemented complete Firebase Storage photo upload functionality
- ***Challenge Progress Tracking***: Fixed challenge progress not incrementing after food upload
- **Filter System Logic**: Resolved duplicate filtering logic causing conflicts between share type filters
- **Challenge UI Synchronization**: Synced challenge bars between HomeView and ChallengesView using ChallengeManager
- *Data Loading*: Added loadAllFoodItems() method for proper "全部" filter functionality

### Technical
- **Firebase Storage**: Added photo upload to Storage with proper path structure and metadata
- **ChallengeManager Integration**: Updated ChallengesView to use centralized challenge management
- **Filter Logic Cleanup**: Removed duplicate filtering in ExploreView's filteredList computed property
- *Progress Bar Consistency*: Standardized challenge progress bar styling across views

## [0.2.0] - 2025-07-23

### Added
- ***ChallengeManager System***: Complete challenge tracking and badge conversion system
- ***Enhanced Food Upload***: Food name and price input fields with proper Firebase sync  
- **Photo Management**: Multi-image upload with swipe navigation and zoom functionality
- **My Uploads Feature**: ProfileView now shows user's actual uploaded food items
- **Food Tags Display**: Tags shown above uploader info in FoodDetailView
- **Local Storage**: Challenges cached locally for improved performance (6-hour sync)
- *Keyboard Management*: Proper keyboard dismissal in text fields
- *Image Viewer*: Full-screen photo viewer with pinch-to-zoom and swipe navigation

### Changed
- ***UploadView***: Added food name/price fields, enhanced with challenge progression triggers
- ***HomeView***: Now integrates with ChallengeManager for dynamic challenge display  
- **FoodDetailView**: Enhanced with photo gallery, zoom functionality, and food tags
- **ProfileView**: "My Uploads" now shows real food items instead of placeholder strings
- **Challenge System**: Progress starts at 0 for new users, increments on actions, converts to badges when completed

### Fixed
- **Data Synchronization**: Proper sync between UploadView, FoodDetailView, and ExploreView
- **User Data Display**: Correct uploader name, photo, and ratings in FoodDetailView
- *Challenge Progress*: Real-time tracking with local caching for performance

### Technical
- ***ChallengeManager.swift***: New centralized challenge management system
- **Local Caching**: UserDefaults-based caching for challenges with smart sync
- *ImageViewerView*: Custom zoom and navigation component  
- *MyUploadsView*: New view component for user's uploaded items
- *Challenge Types*: Enum-based system for different challenge categories

## [0.1.1] - 2025-07-22

### Added
- Complete Firebase backend integration replacing mock data
- FirebaseModels.swift with comprehensive data structures
- FirebaseManager.swift service for all database operations
- Real-time user profile sync with Firebase Authentication
- Location-based food discovery using GeoFireUtils
- Share type filtering (Free, Discounted, Donation)
- Automatic location tagging for food uploads
- Firebase security rules with privacy protection
- Enhanced ExploreView with location and type filters
- UploadView with Firebase integration and progress indicators
- LocationManager for GPS-based functionality
- Comprehensive Firebase integration documentation

### Changed
- UserProfileModel now syncs with Firebase in real-time
- FoodRepository uses Firebase Firestore instead of mock data
- LoginView creates/updates user data in Firestore
- All views now support real-time data updates
- Food items include geolocation for proximity matching

### Technical
- Added GeoFireUtils for geographic queries
- Implemented Core Location for user positioning
- Real-time listeners for data synchronization
- Comprehensive error handling and loading states
- Data validation and spam prevention measures

## [0.1.0] - 2025-07-22

### Added
- Initial FoodLoop iOS application structure
- SwiftUI-based user interface with tab navigation
- Firebase integration (Auth, Firestore, Analytics)
- Google Sign-In authentication
- Core views: Home, Explore, Upload, Chat, Profile
- Mock data system for development
- Basic photo picker integration
- User profile and food repository models
- Admin panel and challenges system
- Green report for sustainability tracking

### Technical
- Swift Package Manager dependencies
- Firebase iOS SDK v11.14.0
- Google Sign-In iOS v8.0.0
- SwiftUI navigation and state management
- Testing framework setup (unit and UI tests)

---

## Version Format

- **Major.Minor.Patch** (e.g., 1.0.0)
- **Major**: Breaking changes or major feature releases
- **Minor**: New features, backwards compatible
- **Patch**: Bug fixes and minor improvements

## Types of Changes

- **Added**: New features
- **Changed**: Changes in existing functionality
- **Deprecated**: Soon-to-be removed features
- **Removed**: Removed features
- **Fixed**: Bug fixes
- **Security**: Security improvements
- **Technical**: Infrastructure, build, or development changes
