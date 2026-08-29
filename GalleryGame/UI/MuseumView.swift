import PhotosUI
import SwiftUI
import UIKit

struct MuseumView: View {
    @StateObject private var museum = MuseumSceneController()
    @State private var pickerItem: PhotosPickerItem?
    @State private var isPickingPhoto = false

    var body: some View {
        ZStack {
            MuseumSceneView(controller: museum)
                .ignoresSafeArea()

            VStack {
                HStack {
                    Text("Gallery")
                        .font(.headline)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        .background(.ultraThinMaterial, in: Capsule())

                    Spacer()
                }
                .padding()

                Spacer()

                Text(museum.hint)
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background(.ultraThinMaterial, in: Capsule())
                    .padding(.bottom, 12)

                movementControls
                    .padding(.bottom, 24)
            }
        }
        .preferredColorScheme(.dark)
        .onChange(of: museum.selectedFrameIndex) { _, newValue in
            isPickingPhoto = newValue != nil
        }
        .photosPicker(
            isPresented: $isPickingPhoto,
            selection: $pickerItem,
            matching: .images,
            preferredItemEncoding: .automatic
        )
        .onChange(of: pickerItem) { _, newItem in
            guard let newItem, let frameIndex = museum.selectedFrameIndex else { return }

            Task {
                do {
                    guard let data = try await newItem.loadTransferable(type: Data.self),
                          let image = UIImage(data: data) else {
                        return
                    }

                    await MainActor.run {
                        museum.applyPhoto(image, to: frameIndex)
                        museum.selectedFrameIndex = nil
                        pickerItem = nil
                    }
                } catch {
                    await MainActor.run {
                        museum.hint = "Could not load that photo."
                        museum.selectedFrameIndex = nil
                        pickerItem = nil
                    }
                }
            }
        }
    }

    private var movementControls: some View {
        HStack(alignment: .bottom, spacing: 16) {
            VStack(spacing: 8) {
                MoveButton(systemName: "arrow.up") {
                    museum.move(forward: 1, right: 0)
                }

                HStack(spacing: 8) {
                    MoveButton(systemName: "arrow.left") {
                        museum.move(forward: 0, right: -1)
                    }

                    MoveButton(systemName: "arrow.down") {
                        museum.move(forward: -1, right: 0)
                    }

                    MoveButton(systemName: "arrow.right") {
                        museum.move(forward: 0, right: 1)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                Image(systemName: "hand.draw")
                    .font(.title2)
                Text("Drag anywhere\nto look around")
                    .font(.caption2)
                    .multilineTextAlignment(.trailing)
            }
            .padding(12)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
        .padding(.horizontal)
    }
}
