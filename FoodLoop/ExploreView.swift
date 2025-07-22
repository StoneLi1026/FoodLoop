import SwiftUI

struct ExploreView: View {
    @EnvironmentObject var foodRepo: FoodRepository
    @State private var selectedFilter = 0
    @State private var searchText = ""
    @State private var showFridgeMap = false
    let filters = ["距離", "分類", "價格", "即期"]
    
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
        let filtered = foodRepo.foodItems.filter { item in
            searchText.isEmpty ||
            item.name.localizedStandardContains(searchText) ||
            item.tags.contains { $0.localizedStandardContains(searchText) }
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
                
                // 篩選 chips
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
                .padding(.vertical, 8)
                
                // 食物卡片列表（可捲動）+ 懸浮按鈕
                ZStack(alignment: .bottomTrailing) {
                    ScrollView {
                        LazyVStack(spacing: 20) {
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
    }
}

// FoodDetailView 需支援 foodItem 參數
