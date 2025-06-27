import SwiftUI
import Foundation

public struct ExamplesView: View {
    @Environment(\.uiaiStyle) private var uiaiStyle: any UIAIStyle
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 32) {
                    headerSection
                    productivityExample
                    socialExample
                    ecommerceExample
                    dashboardExample
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 24)
            }
            .background(uiaiStyle.backgroundColor.ignoresSafeArea())
            .navigationTitle("Examples")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            Text("Real-World Examples")
                .font(.title.bold())
                .foregroundColor(uiaiStyle.foregroundColor)
            
            Text("See how SwiftUIKit components work together in practical scenarios")
                .font(.subheadline)
                .foregroundColor(uiaiStyle.foregroundColor.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding(.bottom, 16)
    }
    
    private var productivityExample: some View {
        VStack(alignment: .leading, spacing: 16) {
            exampleHeader("Productivity App", icon: "doc.text.fill")
            productivityTaskList
        }
    }
    
    private var productivityTaskList: some View {
        VStack(spacing: 12) {
            VStack(spacing: 8) {
                HStack {
                    Text("Today's Tasks")
                        .font(.headline)
                        .foregroundColor(uiaiStyle.foregroundColor)
                    Spacer()
                    Text("3/5 completed")
                        .font(.caption)
                        .foregroundColor(uiaiStyle.foregroundColor.opacity(0.7))
                }
                ProgressView(value: 0.6)
                    .progressViewStyle(.linear)
                    .tint(uiaiStyle.accentColor)
                VStack(spacing: 6) {
                    taskRow("Review project proposal", isCompleted: true)
                    taskRow("Schedule team meeting", isCompleted: true)
                    taskRow("Update documentation", isCompleted: true)
                    taskRow("Prepare presentation", isCompleted: false)
                    taskRow("Send follow-up emails", isCompleted: false)
                }
            }
            .padding(16)
            .background(uiaiStyle.backgroundColor)
            .cornerRadius(uiaiStyle.cornerRadius)
            .shadow(color: uiaiStyle.shadow?.color ?? .clear, radius: uiaiStyle.shadow?.radius ?? 0, x: uiaiStyle.shadow?.x ?? 0, y: uiaiStyle.shadow?.y ?? 0)
        }
    }
    
    private var socialExample: some View {
        VStack(alignment: .leading, spacing: 16) {
            exampleHeader("Social App", icon: "bubble.left.and.bubble.right.fill")
            socialFeed
        }
    }
    
    private var socialFeed: some View {
        VStack(spacing: 12) {
            socialPost(user: "@alice", content: "Just shipped a new SwiftUI package! 🚀", time: "2m ago", isLiked: true)
            socialPost(user: "@bob", content: "Anyone tried the new visionOS APIs?", time: "10m ago", isLiked: false)
            socialPost(user: "@carol", content: "Minimalism is the ultimate sophistication.", time: "1h ago", isLiked: false)
        }
        .padding(16)
        .background(uiaiStyle.backgroundColor)
        .cornerRadius(uiaiStyle.cornerRadius)
        .shadow(color: uiaiStyle.shadow?.color ?? .clear, radius: uiaiStyle.shadow?.radius ?? 0, x: uiaiStyle.shadow?.x ?? 0, y: uiaiStyle.shadow?.y ?? 0)
    }
    
    private var ecommerceExample: some View {
        VStack(alignment: .leading, spacing: 16) {
            exampleHeader("E-Commerce App", icon: "cart.fill")
            ecommerceProductList
        }
    }
    
    private var ecommerceProductList: some View {
        VStack(spacing: 12) {
            ecommerceProductCard(name: "SwiftUI Hoodie", price: "$49", isInStock: true)
            ecommerceProductCard(name: "AI Sticker Pack", price: "$9", isInStock: false)
            ecommerceProductCard(name: "Gradient Mug", price: "$19", isInStock: true)
        }
        .padding(16)
        .background(uiaiStyle.backgroundColor)
        .cornerRadius(uiaiStyle.cornerRadius)
        .shadow(color: uiaiStyle.shadow?.color ?? .clear, radius: uiaiStyle.shadow?.radius ?? 0, x: uiaiStyle.shadow?.x ?? 0, y: uiaiStyle.shadow?.y ?? 0)
    }
    
    private var dashboardExample: some View {
        VStack(alignment: .leading, spacing: 16) {
            exampleHeader("Analytics Dashboard", icon: "chart.bar.fill")
            dashboardStats
            dashboardRecentActivity
        }
    }
    
    private var dashboardStats: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            statCard("Total Users", value: "12,847", change: "+12%", isPositive: true)
            statCard("Revenue", value: "$45,230", change: "+8%", isPositive: true)
            statCard("Active Sessions", value: "2,341", change: "-3%", isPositive: false)
            statCard("Conversion Rate", value: "3.2%", change: "+1.5%", isPositive: true)
        }
    }
    
    private var dashboardRecentActivity: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recent Activity")
                .font(.headline)
                .foregroundColor(uiaiStyle.foregroundColor)
            VStack(spacing: 6) {
                activityRow("New user registration", time: "2 min ago", icon: "person.badge.plus")
                activityRow("Payment processed", time: "5 min ago", icon: "creditcard.fill")
                activityRow("Support ticket closed", time: "12 min ago", icon: "checkmark.circle.fill")
            }
        }
        .padding(16)
        .background(uiaiStyle.backgroundColor)
        .cornerRadius(uiaiStyle.cornerRadius)
        .shadow(color: uiaiStyle.shadow?.color ?? .clear, radius: uiaiStyle.shadow?.radius ?? 0, x: uiaiStyle.shadow?.x ?? 0, y: uiaiStyle.shadow?.y ?? 0)
    }
    
    private func exampleHeader(_ title: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(uiaiStyle.accentColor)
            Text(title)
                .font(.title2.bold())
                .foregroundColor(uiaiStyle.foregroundColor)
        }
        .padding(.top, 8)
    }
    
    private func taskRow(_ title: String, isCompleted: Bool) -> some View {
        HStack {
            Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isCompleted ? uiaiStyle.accentColor : uiaiStyle.foregroundColor.opacity(0.5))
            
            Text(title)
                .font(.body)
                .foregroundColor(uiaiStyle.foregroundColor)
                .strikethrough(isCompleted)
                .opacity(isCompleted ? 0.6 : 1.0)
            
            Spacer()
        }
    }
    
    private func statCard(_ title: String, value: String, change: String, isPositive: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(uiaiStyle.foregroundColor.opacity(0.7))
            
            Text(value)
                .font(.title2.bold())
                .foregroundColor(uiaiStyle.foregroundColor)
            
            HStack(spacing: 4) {
                Image(systemName: isPositive ? "arrow.up" : "arrow.down")
                Text(change)
            }
            .font(.caption.bold())
            .foregroundColor(isPositive ? .green : .red)
        }
        .padding(16)
        .background(uiaiStyle.backgroundColor)
        .cornerRadius(uiaiStyle.cornerRadius)
        .shadow(color: uiaiStyle.shadow?.color ?? .clear, radius: uiaiStyle.shadow?.radius ?? 0, x: uiaiStyle.shadow?.x ?? 0, y: uiaiStyle.shadow?.y ?? 0)
    }
    
    private func activityRow(_ title: String, time: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(uiaiStyle.accentColor)
                .frame(width: 20)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.body)
                    .foregroundColor(uiaiStyle.foregroundColor)
                Text(time)
                    .font(.caption)
                    .foregroundColor(uiaiStyle.foregroundColor.opacity(0.6))
            }
            
            Spacer()
        }
    }
    
    private func socialPost(user: String, content: String, time: String, isLiked: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 36, height: 36)
                VStack(alignment: .leading) {
                    Text(user)
                        .font(.headline)
                    Text(time)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: isLiked ? "heart.fill" : "heart")
                    .foregroundColor(isLiked ? .red : .gray)
            }
            Text(content)
                .font(.body)
            Divider()
        }
        .padding(8)
    }
    
    private func ecommerceProductCard(name: String, price: String, isInStock: Bool) -> some View {
        HStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.2))
                .frame(width: 60, height: 60)
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.headline)
                Text(price)
                    .font(.subheadline)
                    .foregroundColor(.accentColor)
                Text(isInStock ? "In Stock" : "Out of Stock")
                    .font(.caption)
                    .foregroundColor(isInStock ? .green : .red)
            }
            Spacer()
            Button(action: {}) {
                Text("Buy")
            }
            .buttonStyle(.borderedProminent)
            .disabled(!isInStock)
        }
        .padding(8)
        .background(Color(.systemBackground).opacity(0.7))
        .cornerRadius(12)
    }
}

#if DEBUG
#Preview {
    ExamplesView()
        .uiaiStyle(MinimalStyle(colorScheme: .light))
}
#endif 