import SwiftUI
import CoreLocation

struct ExploreView: View {
    @EnvironmentObject var foodRepo: FoodRepository
    @State private var selectedFilter = 0
    @State private var searchText = ""
    @State private var showFridgeMap = false
    @State private var selectedTag: String? = nil
    @State private var locationManager = LocationManager()
    
    let filters = ["距離", "分類", "價格", "即期"]
    let tagFilters: [String?] = [nil, "有機", "自製", "環保", "即食", "甜品"]
    let tagFilterLabels = ["全部", "有機", "自製", "環保", "即食", "甜品"]
    
    //將 expires 字串轉成「代表時間早晚的權重值」再排序
    func expiryPriority(_ date: Date) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        if calendar.isDateInToday(date) {
            return 0
        } else if calendar.isDate(date, inSameDayAs: tomorrow) {
            return 1
        } else {
            return 2
        }
    }

    // 模擬排序
    func sortedFoodList(_ list: [FoodItem]) -> [FoodItem] {
        switch selectedFilter {
        case 0: // 距離
            return list.sorted { 
                let d0 = Double($0.distance.replacingOccurrences(of: "km", with: "")) ?? 999
                let d1 = Double($1.distance.replacingOccurrences(of: "km", with: "")) ?? 999
                return d0 < d1
            }
        case 1: // 分類
            return list.sorted { ($0.tags.first ?? "") < ($1.tags.first ?? "") }
        case 2: // 價格
            return list.sorted {
                let p0 = $0.price == nil ? 0 : (Int($0.price?.replacingOccurrences(of: "$", with: "") ?? "0") ?? 0)
                let p1 = $1.price == nil ? 0 : (Int($1.price?.replacingOccurrences(of: "$", with: "") ?? "0") ?? 0)
                return p0 < p1
            }
        case 3: // 即期
            return list.sorted {
                if expiryPriority($0.expires) == expiryPriority($1.expires) {
                    return $0.expires < $1.expires
                }
                return expiryPriority($0.expires) < expiryPriority($1.expires)
            }
        default:
            return list
        }
    }
    
    // 搜尋與排序後的清單
    var filteredList: [FoodItem] {
        var filtered = foodRepo.foodItems
        
        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { item in
                item.name.localizedStandardContains(searchText) ||
                item.tags.contains { $0.localizedStandardContains(searchText) }
            }
        }
        
        // Apply tag filter
        if let selectedTag = selectedTag {
            filtered = filtered.filter { item in
                item.tags.contains(selectedTag)
            }
        }
        
        return sortedFoodList(filtered)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 搜尋列
                HStack {
                    Image(systemName: "magnifyingglass")
                    TextField("搜尋食物...", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
                .padding(.top, 8)
                
                // 標籤篩選 chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(tagFilterLabels.indices, id: \.self) { idx in
                            FilterChip(
                                title: tagFilterLabels[idx], 
                                isSelected: selectedTag == tagFilters[idx]
                            ) {
                                selectedTag = tagFilters[idx]
                                print("DEBUG: Selected tag filter: \(tagFilters[idx] ?? "nil")")
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 4)
                
                // 排序篩選 chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(filters.indices, id: \.self) { idx in
                            FilterChip(title: filters[idx], isSelected: selectedFilter == idx) {
                                selectedFilter = idx
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 4)
                
                // 食物卡片列表（可捲動）+ 懸浮按鈕
                ZStack(alignment: .bottomTrailing) {
                    ScrollView {
                        LazyVStack(spacing: 20) {
                            // Loading indicator when refreshing
                            if foodRepo.isLoading {
                                HStack {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                    Text("載入中...")
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                }
                                .padding(.vertical, 8)
                            }
                            
                            ForEach(filteredList) { item in
                                NavigationLink(destination: FoodDetailView(foodItem: item)) {
                                    FoodCardView(item: item)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                        .padding(.bottom, 32)
                    }
                    .refreshable {
                        await refreshFoodData()
                    }
                    // 懸浮按鈕
                    Button(action: { showFridgeMap = true }) {
                        Image(systemName: "map")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 32, height: 32)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.green.opacity(0.3))
                            .clipShape(Circle())
                            .shadow(radius: 6)
                    }
                    .padding(.trailing, 24)
                    .padding(.bottom, 16)
                    .accessibilityLabel("社區冰箱地圖")
                }
            }
            .navigationTitle("探索食物")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $showFridgeMap) {
                FridgeMapView()
            }
        }
        .onAppear {
            locationManager.requestPermission()
            loadFilteredItems()
        }
        .onChange(of: selectedTag) { oldValue, newValue in
            print("DEBUG: Tag filter changed from \(oldValue ?? "nil") to \(newValue ?? "nil")")
            // No need to reload data, filteredList will automatically update
        }
    }
    
    // Load filtered items based on current selections
    private func loadFilteredItems() {
        print("DEBUG: ExploreView.loadFilteredItems called")
        print("DEBUG: Current location available: \(locationManager.currentLocation != nil)")
        print("DEBUG: Current foodRepo.foodItems count: \(foodRepo.foodItems.count)")
        
        Task {
            if let location = locationManager.currentLocation {
                // Load by location when we have location
                print("DEBUG: Loading items by location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
                await foodRepo.loadFoodItemsNearLocation(
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude
                )
                print("DEBUG: After location load - foodItems count: \(foodRepo.foodItems.count)")
            } else {
                // Load all items when no location
                print("DEBUG: Loading all items (no location)")
                await foodRepo.loadAllFoodItems()
                print("DEBUG: After loadAll - foodItems count: \(foodRepo.foodItems.count)")
            }
            
            if foodRepo.foodItems.isEmpty {
                print("⚠️ WARNING: No food items loaded! ErrorMessage: \(foodRepo.errorMessage ?? "none")")
            }
        }
    }
    
    // Pull-to-refresh function
    private func refreshFoodData() async {
        print("DEBUG: Pull-to-refresh triggered - refreshing food data")
        
        // Show a brief loading state
        foodRepo.isLoading = true
        
        // Small delay to show refresh animation
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        if let location = locationManager.currentLocation {
            // Refresh with location data
            print("DEBUG: Refreshing items by location")
            await foodRepo.loadFoodItemsNearLocation(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude
            )
        } else {
            // Refresh all items
            print("DEBUG: Refreshing all items")
            await foodRepo.loadAllFoodItems()
        }
        
        print("DEBUG: Pull-to-refresh completed")
    }
}

// Location Manager for getting user location
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }
    
    func startLocationUpdates() {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            return
        }
        manager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.last
        manager.stopUpdatingLocation() // Stop after getting first location
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        DispatchQueue.main.async {
            self.authorizationStatus = status
        }
        
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            startLocationUpdates()
        case .denied, .restricted:
            print("Location access denied")
        case .notDetermined:
            requestPermission()
        @unknown default:
            break
        }
    }
}

// FoodDetailView 需支援 foodItem 參數
