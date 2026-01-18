import SwiftUI

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Privacy Policy")
                    .font(.largeTitle)
                    .bold()
                    .padding(.bottom, 10)
                
                Text("Last Updated: " + Date().formatted(.dateTime.year().month().day()))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Section(header: Text("Information We Collect").font(.title2).bold()) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("1. User-Provided Information")
                            .font(.headline)
                        Text("- Dietary preferences and restrictions")
                        Text("- Flavor preferences")
                        Text("- Vegetarian/vegan status")
                        Text("- Spice level preferences")
                        
                        Text("2. Automatically Collected Information")
                            .font(.headline)
                        Text("- Scanned menu images (temporarily processed and not stored)")
                        Text("- Search and scan history")
                        Text("- App usage data")
                    }
                }
                
                Section(header: Text("How We Use Your Information").font(.title2).bold()) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("- To provide personalized dish recommendations based on your dietary preferences")
                        Text("- To analyze menu items and provide dietary safety information")
                        Text("- To maintain your search and order history for convenience")
                        Text("- To improve our app's functionality and user experience")
                    }
                }
                
                Section(header: Text("Data Storage and Security").font(.title2).bold()) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("- Your personal data is stored locally on your device using Apple's secure Keychain service for sensitive information")
                        Text("- We do not transmit your personal data to any third-party servers without your explicit consent")
                        Text("- Menu images are processed locally and temporarily, and are not stored on our servers")
                        Text("- We implement industry-standard security measures to protect your data")
                    }
                }
                
                Section(header: Text("Permissions").font(.title2).bold()) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("- Camera: Used to scan menu images for dish recognition")
                        Text("- Photo Library: Used to select menu images from your device")
                        Text("- Storage: Used to save your search history and preferences")
                    }
                }
                
                Section(header: Text("Third-Party Services").font(.title2).bold()) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("- SiliconFlow API: Used for menu image recognition and dish information analysis")
                        Text("- Unsplash API: Used to fetch dish images for display")
                        Text("These third-party services may have their own privacy policies, and we encourage you to review them")
                    }
                }
                
                Section(header: Text("Changes to This Privacy Policy").font(.title2).bold()) {
                    Text("We may update our privacy policy from time to time. We will notify you of any changes by posting the new privacy policy on this page.")
                }
                
                Section(header: Text("Contact Us").font(.title2).bold()) {
                    Text("If you have any questions or concerns about our privacy policy, please contact us at: support@menutrans.com")
                }
            }
            .padding()
        }
        .navigationBarTitle("Privacy Policy", displayMode: .inline)
    }
}

struct PrivacyPolicyView_Previews: PreviewProvider {
    static var previews: some View {
        PrivacyPolicyView()
    }
}
