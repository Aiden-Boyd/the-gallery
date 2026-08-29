import SceneKit
import SwiftUI

struct MuseumSceneView: UIViewRepresentable {
    @ObservedObject var controller: MuseumSceneController

    func makeCoordinator() -> Coordinator {
        Coordinator(controller: controller)
    }

    func makeUIView(context: Context) -> SCNView {
        let view = SCNView()
        view.scene = controller.scene
        view.pointOfView = controller.cameraNode
        view.backgroundColor = .black
        view.antialiasingMode = .multisampling4X
        view.preferredFramesPerSecond = 60

        let tap = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.didTap(_:))
        )
        view.addGestureRecognizer(tap)

        let pan = UIPanGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.didPan(_:))
        )
        view.addGestureRecognizer(pan)

        return view
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        uiView.pointOfView = controller.cameraNode
    }

    final class Coordinator: NSObject {
        private let controller: MuseumSceneController
        private var lastTranslation: CGPoint = .zero

        init(controller: MuseumSceneController) {
            self.controller = controller
        }

        @objc func didTap(_ recognizer: UITapGestureRecognizer) {
            guard let view = recognizer.view as? SCNView else { return }
            let point = recognizer.location(in: view)
            guard let hit = view.hitTest(point, options: nil).first else { return }

            Task { @MainActor in
                controller.select(node: hit.node)
            }
        }

        @objc func didPan(_ recognizer: UIPanGestureRecognizer) {
            let translation = recognizer.translation(in: recognizer.view)
            let delta = CGPoint(
                x: translation.x - lastTranslation.x,
                y: translation.y - lastTranslation.y
            )

            if recognizer.state == .began {
                lastTranslation = translation
                return
            }

            Task { @MainActor in
                controller.look(deltaX: delta.x, deltaY: delta.y)
            }

            lastTranslation = translation

            if recognizer.state == .ended || recognizer.state == .cancelled {
                lastTranslation = .zero
            }
        }
    }
}
