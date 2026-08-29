import PhotosUI
import SwiftUI
import UIKit

struct MuseumView: View {
    let multiplayer: MultiplayerManager?

    @StateObject private var museum = MuseumSceneController()
    @State private var pickerItem: PhotosPickerItem?
    @State private var isPickingPhoto = false

    init(multiplayer: MultiplayerManager? = nil) {
        self.multiplayer = multiplayer
    }

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
        .onAppear {
            guard let multiplayer else { return }

            museum.onLocalPoseChanged = { pose in
                multiplayer.sendPose(pose)
            }

            multiplayer.onPoseReceived = { name, pose in
                museum.updateRemotePlayer(name: name, pose: pose)
            }

            multiplayer.onPhotoReceived = { index, image in
                museum.applyPhoto(image, to: index)
            }

            multiplayer.onPeerDisconnected = { name in
                museum.removeRemotePlayer(name: name)
            }

            multiplayer.sendPose(museum.currentPose())
        }
        .onDisappear {
            museum.onLocalPoseChanged = nil

            if let multiplayer {
                multiplayer.onPoseReceived = nil
                multiplayer.onPhotoReceived = nil
                multiplayer.onPeerDisconnected = nil
            }
        }
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
                        multiplayer?.sendPhoto(index: frameIndex, image: image)
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
        HStack(alignment: .bottom) {
            VirtualJoystick(
                onChange: { forward, right in
                    museum.setMovement(forward: forward, right: right)
                },
                onEnd: {
                    museum.stopMovement()
                }
            )

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                Image(systemName: "hand.draw")
                    .font(.title2)
                Text("Drag the right side\nto look around")
                    .font(.caption2)
                    .multilineTextAlignment(.trailing)
            }
            .padding(12)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
        .padding(.horizontal)
    }
}
