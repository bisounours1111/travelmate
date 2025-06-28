import SwiftUI

struct ErrorBanner: View {
    var message: String

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.white)
            Text(message)
                .foregroundColor(.white)
                .font(.body)
                .multilineTextAlignment(.leading)
        }
        .padding()
        .background(Color.red.opacity(0.85))
        .cornerRadius(8)
        .shadow(radius: 4)
        .padding(.vertical, 8)
        .transition(.move(edge: .top).combined(with: .opacity))
        .animation(.spring(), value: message)
    }
}