import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var userSettings: UserSettings
    
    // 常见的忌口选项
    private let commonRestrictions = [
        "Peanuts", "Tree Nuts", "Seafood", "Shellfish", "Dairy", "Eggs", 
        "Soy", "Wheat", "Gluten", "Cilantro", "Onions", "Garlic", "Mushrooms"
    ]
    
    // 常见的口味偏好
    private let commonFlavors = [
        "Sweet", "Sour", "Spicy", "Savory", "Umami", "Bitter", "Tangy", "Smoky"
    ]
    
    var body: some View {
        NavigationView {
            Form {
                // Dietary Restrictions Section
                Section(header: Text("Dietary Restrictions")) {
                    ForEach(commonRestrictions, id: \.self) { restriction in
                        HStack {
                            Text(restriction)
                            Spacer()
                            if userSettings.profile.restrictions.contains(restriction) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if userSettings.profile.restrictions.contains(restriction) {
                                userSettings.profile.restrictions.remove(restriction)
                            } else {
                                userSettings.profile.restrictions.insert(restriction)
                            }
                        }
                    }
                }
                
                // Habits Section
                Section(header: Text("Habits")) {
                    Toggle("Vegetarian", isOn: $userSettings.profile.isVegetarian)
                    Toggle("Vegan", isOn: $userSettings.profile.isVegan)
                }
                
                // Flavor Profile Section
                Section(header: Text("Flavor Profile")) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Spice Level")
                            .font(.headline)
                        
                        Picker("Spice Level", selection: $userSettings.profile.spiceLevel) {
                            ForEach(UserProfile.SpiceLevel.allCases) { level in
                                Text(level.rawValue).tag(level)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Flavor Preferences")
                            .font(.headline)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                            ForEach(commonFlavors, id: \.self) { flavor in
                                HStack {
                                    Text(flavor)
                                        .font(.caption)
                                    Spacer()
                                    if userSettings.profile.flavorPreferences.contains(flavor) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                            .font(.caption)
                                    }
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(userSettings.profile.flavorPreferences.contains(flavor) ? Color.green.opacity(0.2) : Color.gray.opacity(0.1))
                                )
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    if userSettings.profile.flavorPreferences.contains(flavor) {
                                        userSettings.profile.flavorPreferences.remove(flavor)
                                    } else {
                                        userSettings.profile.flavorPreferences.insert(flavor)
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Disclaimer Section
                Section {
                    Text("AI analysis is for reference only. For severe allergies, please confirm with restaurant staff.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // Privacy Policy Section
                Section {
                    NavigationLink(destination: PrivacyPolicyView()) {
                        HStack {
                            Text("Privacy Policy")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Dietary Profile")
        }
    }
} 