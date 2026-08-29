import SwiftUI

struct MoveButton: View {
    let systemName: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.title2.bold())
                .frame(width: 54, height: 54)
                .background(.ultraThinMaterial, in: Circle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(.white)
    }
}
