import SwiftUI

struct VirtualJoystick: View {
    let onChange: (_ forward: Float, _ right: Float) -> Void
    let onEnd: () -> Void

    @State private var knobOffset: CGSize = .zero

    private let radius: CGFloat = 52

    var body: some View {
        ZStack {
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: radius * 2, height: radius * 2)

            Circle()
                .fill(.white.opacity(0.8))
                .frame(width: 46, height: 46)
                .offset(knobOffset)
        }
        .frame(width: radius * 2, height: radius * 2)
        .contentShape(Circle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    let dx = value.translation.width
                    let dy = value.translation.height
                    let distance = max(sqrt(dx * dx + dy * dy), 0.001)
                    let scale = min(1, radius / distance)

                    let clampedX = dx * scale
                    let clampedY = dy * scale
                    knobOffset = CGSize(width: clampedX, height: clampedY)

                    let right = Float(clampedX / radius)
                    let forward = Float(-clampedY / radius)
                    onChange(forward, right)
                }
                .onEnded { _ in
                    withAnimation(.snappy(duration: 0.15)) {
                        knobOffset = .zero
                    }
                    onEnd()
                }
        )
    }
}
