import SceneKit
import UIKit

@MainActor
final class MuseumSceneController: ObservableObject {
    let scene = SCNScene()
    let cameraNode = SCNNode()

    @Published var selectedFrameIndex: Int?
    @Published var hint = "Walk around and tap a picture frame."

    private var yaw: Float = 0
    private var pitch: Float = 0
    private var movementForward: Float = 0
    private var movementRight: Float = 0
    private var movementTimer: Timer?

    init() {
        buildScene()
        startMovementLoop()
    }

    private func startMovementLoop() {
        movementTimer?.invalidate()
        movementTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateMovement()
            }
        }
    }

    private func updateMovement() {
        guard abs(movementForward) > 0.01 || abs(movementRight) > 0.01 else { return }

        let speedPerFrame: Float = 0.055
        let sinYaw = sin(yaw)
        let cosYaw = cos(yaw)

        // SceneKit cameras face local -Z. Build movement from the camera's
        // horizontal forward/right vectors so controls stay camera-relative.
        let dx = (-movementForward * sinYaw + movementRight * cosYaw) * speedPerFrame
        let dz = (-movementForward * cosYaw - movementRight * sinYaw) * speedPerFrame

        var next = cameraNode.position
        next.x += dx
        next.z += dz

        next.x = min(max(next.x, -3.55), 3.55)
        next.z = min(max(next.z, -4.45), 4.45)

        cameraNode.position = next
    }

    func setMovement(forward: Float, right: Float) {
        movementForward = min(max(forward, -1), 1)
        movementRight = min(max(right, -1), 1)
    }

    func stopMovement() {
        movementForward = 0
        movementRight = 0
    }

    private func buildScene() {
        scene.background.contents = UIColor.black

        let ambient = SCNLight()
        ambient.type = .ambient
        ambient.intensity = 350
        let ambientNode = SCNNode()
        ambientNode.light = ambient
        scene.rootNode.addChildNode(ambientNode)

        let key = SCNLight()
        key.type = .omni
        key.intensity = 1100
        key.color = UIColor(white: 1.0, alpha: 1.0)
        let keyNode = SCNNode()
        keyNode.light = key
        keyNode.position = SCNVector3(0, 2.5, 0)
        scene.rootNode.addChildNode(keyNode)

        cameraNode.camera = SCNCamera()
        cameraNode.camera?.fieldOfView = 65
        cameraNode.position = SCNVector3(0, 1.65, 4.2)
        scene.rootNode.addChildNode(cameraNode)

        addBox(name: "floor", width: 8, height: 0.1, length: 10,
               position: SCNVector3(0, -0.05, 0),
               color: UIColor(white: 0.22, alpha: 1))

        addBox(name: "backWall", width: 8, height: 3.2, length: 0.12,
               position: SCNVector3(0, 1.6, -5),
               color: UIColor(white: 0.88, alpha: 1))

        addBox(name: "leftWall", width: 0.12, height: 3.2, length: 10,
               position: SCNVector3(-4, 1.6, 0),
               color: UIColor(white: 0.84, alpha: 1))

        addBox(name: "rightWall", width: 0.12, height: 3.2, length: 10,
               position: SCNVector3(4, 1.6, 0),
               color: UIColor(white: 0.84, alpha: 1))

        addFrame(index: 0, position: SCNVector3(-2.2, 1.65, -4.88), rotationY: 0)
        addFrame(index: 1, position: SCNVector3(0, 1.65, -4.88), rotationY: 0)
        addFrame(index: 2, position: SCNVector3(2.2, 1.65, -4.88), rotationY: 0)
        addFrame(index: 3, position: SCNVector3(-3.88, 1.65, -1.9), rotationY: .pi / 2)
        addFrame(index: 4, position: SCNVector3(-3.88, 1.65, 1.0), rotationY: .pi / 2)
        addFrame(index: 5, position: SCNVector3(3.88, 1.65, -1.9), rotationY: -.pi / 2)
        addFrame(index: 6, position: SCNVector3(3.88, 1.65, 1.0), rotationY: -.pi / 2)
    }

    private func addBox(
        name: String,
        width: CGFloat,
        height: CGFloat,
        length: CGFloat,
        position: SCNVector3,
        color: UIColor
    ) {
        let box = SCNBox(width: width, height: height, length: length, chamferRadius: 0)
        box.firstMaterial?.diffuse.contents = color
        let node = SCNNode(geometry: box)
        node.name = name
        node.position = position
        scene.rootNode.addChildNode(node)
    }

    private func addFrame(index: Int, position: SCNVector3, rotationY: Float) {
        let frame = SCNBox(width: 1.45, height: 1.05, length: 0.08, chamferRadius: 0.03)
        frame.firstMaterial?.diffuse.contents = UIColor(white: 0.12, alpha: 1)
        let frameNode = SCNNode(geometry: frame)
        frameNode.position = position
        frameNode.eulerAngles.y = rotationY
        frameNode.name = "frameContainer_\(index)"
        scene.rootNode.addChildNode(frameNode)

        let picture = SCNPlane(width: 1.25, height: 0.85)
        picture.cornerRadius = 0.01
        picture.firstMaterial?.isDoubleSided = true
        picture.firstMaterial?.diffuse.contents = placeholderImage(number: index + 1)

        let pictureNode = SCNNode(geometry: picture)
        pictureNode.name = "photoFrame_\(index)"
        pictureNode.position = SCNVector3(0, 0, 0.045)
        frameNode.addChildNode(pictureNode)
    }

    private func placeholderImage(number: Int) -> UIImage {
        let size = CGSize(width: 600, height: 400)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            UIColor(white: 0.92, alpha: 1).setFill()
            context.fill(CGRect(origin: .zero, size: size))

            let text = "\(number)"
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 150, weight: .bold),
                .foregroundColor: UIColor(white: 0.25, alpha: 1)
            ]
            let measured = text.size(withAttributes: attrs)
            text.draw(
                at: CGPoint(
                    x: (size.width - measured.width) / 2,
                    y: (size.height - measured.height) / 2
                ),
                withAttributes: attrs
            )
        }
    }

    func select(node: SCNNode) {
        var candidate: SCNNode? = node

        while let current = candidate {
            if let name = current.name,
               name.hasPrefix("photoFrame_"),
               let index = Int(name.replacingOccurrences(of: "photoFrame_", with: "")) {
                selectedFrameIndex = index
                hint = "Choose a photo for frame \(index + 1)."
                return
            }
            candidate = current.parent
        }
    }

    func applyPhoto(_ image: UIImage, to index: Int) {
        guard let node = scene.rootNode.childNode(
            withName: "photoFrame_\(index)",
            recursively: true
        ),
        let plane = node.geometry as? SCNPlane else {
            return
        }

        plane.firstMaterial?.diffuse.contents = image
        hint = "Photo added to frame \(index + 1)."
    }

    func look(deltaX: CGFloat, deltaY: CGFloat) {
        yaw -= Float(deltaX) * 0.004
        pitch -= Float(deltaY) * 0.003
        pitch = min(max(pitch, -0.85), 0.85)

        cameraNode.eulerAngles = SCNVector3(pitch, yaw, 0)
    }
}
