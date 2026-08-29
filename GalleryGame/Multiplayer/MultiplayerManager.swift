import Foundation
import MultipeerConnectivity
import UIKit

struct PlayerPose: Codable {
    let x: Float
    let y: Float
    let z: Float
    let yaw: Float
}

private struct NetworkMessage: Codable {
    enum Kind: String, Codable {
        case pose
        case photo
    }

    let kind: Kind
    let pose: PlayerPose?
    let frameIndex: Int?
    let imageData: Data?
}

@MainActor
final class MultiplayerManager: NSObject, ObservableObject {
    enum Mode {
        case host
        case join
    }

    @Published private(set) var connectedPeers: [MCPeerID] = []
    @Published private(set) var discoveredPeers: [MCPeerID] = []
    @Published private(set) var status = "Not connected"

    var onPoseReceived: ((String, PlayerPose) -> Void)?
    var onPhotoReceived: ((Int, UIImage) -> Void)?
    var onPeerDisconnected: ((String) -> Void)?

    let localPeer: MCPeerID

    private let serviceType = "gallerygame"
    private let session: MCSession
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?
    private var lastPoseSentAt = Date.distantPast

    override init() {
        let deviceName = UIDevice.current.name
        self.localPeer = MCPeerID(displayName: deviceName)
        self.session = MCSession(
            peer: localPeer,
            securityIdentity: nil,
            encryptionPreference: .required
        )

        super.init()
        session.delegate = self
    }

    func startHosting() {
        stopDiscovery()

        let advertiser = MCNearbyServiceAdvertiser(
            peer: localPeer,
            discoveryInfo: ["game": "Gallery"],
            serviceType: serviceType
        )
        advertiser.delegate = self
        advertiser.startAdvertisingPeer()
        self.advertiser = advertiser
        status = "Hosting — waiting for another iPhone…"
    }

    func startBrowsing() {
        stopDiscovery()

        let browser = MCNearbyServiceBrowser(peer: localPeer, serviceType: serviceType)
        browser.delegate = self
        browser.startBrowsingForPeers()
        self.browser = browser
        status = "Looking for nearby galleries…"
    }

    func invite(_ peer: MCPeerID) {
        browser?.invitePeer(peer, to: session, withContext: nil, timeout: 20)
        status = "Inviting \(peer.displayName)…"
    }

    func disconnect() {
        stopDiscovery()
        session.disconnect()
        connectedPeers = []
        discoveredPeers = []
        status = "Disconnected"
    }

    private func stopDiscovery() {
        advertiser?.stopAdvertisingPeer()
        advertiser = nil
        browser?.stopBrowsingForPeers()
        browser = nil
    }

    func sendPose(_ pose: PlayerPose) {
        guard !session.connectedPeers.isEmpty else { return }

        let now = Date()
        guard now.timeIntervalSince(lastPoseSentAt) >= 1.0 / 15.0 else { return }
        lastPoseSentAt = now

        let message = NetworkMessage(
            kind: .pose,
            pose: pose,
            frameIndex: nil,
            imageData: nil
        )
        send(message, mode: .unreliable)
    }

    func sendPhoto(index: Int, image: UIImage) {
        guard !session.connectedPeers.isEmpty,
              let data = image.jpegData(compressionQuality: 0.72) else { return }

        let message = NetworkMessage(
            kind: .photo,
            pose: nil,
            frameIndex: index,
            imageData: data
        )
        send(message, mode: .reliable)
    }

    private func send(_ message: NetworkMessage, mode: MCSessionSendDataMode) {
        do {
            let data = try JSONEncoder().encode(message)
            try session.send(data, toPeers: session.connectedPeers, with: mode)
        } catch {
            status = "Send failed: \(error.localizedDescription)"
        }
    }

    private func receive(_ data: Data, from peer: MCPeerID) {
        do {
            let message = try JSONDecoder().decode(NetworkMessage.self, from: data)

            switch message.kind {
            case .pose:
                if let pose = message.pose {
                    onPoseReceived?(peer.displayName, pose)
                }

            case .photo:
                if let index = message.frameIndex,
                   let imageData = message.imageData,
                   let image = UIImage(data: imageData) {
                    onPhotoReceived?(index, image)
                }
            }
        } catch {
            status = "Received invalid game data."
        }
    }
}

extension MultiplayerManager: MCSessionDelegate {
    nonisolated func session(
        _ session: MCSession,
        peer peerID: MCPeerID,
        didChange state: MCSessionState
    ) {
        Task { @MainActor in
            self.connectedPeers = session.connectedPeers

            switch state {
            case .connected:
                self.status = "Connected to \(peerID.displayName)"
                self.stopDiscovery()

            case .connecting:
                self.status = "Connecting to \(peerID.displayName)…"

            case .notConnected:
                self.status = self.session.connectedPeers.isEmpty ? "Disconnected" : "Connected"
                self.onPeerDisconnected?(peerID.displayName)

            @unknown default:
                self.status = "Connection changed"
            }
        }
    }

    nonisolated func session(
        _ session: MCSession,
        didReceive data: Data,
        fromPeer peerID: MCPeerID
    ) {
        Task { @MainActor in
            self.receive(data, from: peerID)
        }
    }

    nonisolated func session(
        _ session: MCSession,
        didReceive stream: InputStream,
        withName streamName: String,
        fromPeer peerID: MCPeerID
    ) {}

    nonisolated func session(
        _ session: MCSession,
        didStartReceivingResourceWithName resourceName: String,
        fromPeer peerID: MCPeerID,
        with progress: Progress
    ) {}

    nonisolated func session(
        _ session: MCSession,
        didFinishReceivingResourceWithName resourceName: String,
        fromPeer peerID: MCPeerID,
        at localURL: URL?,
        withError error: Error?
    ) {}

    nonisolated func session(
        _ session: MCSession,
        didReceiveCertificate certificate: [Any]?,
        fromPeer peerID: MCPeerID,
        certificateHandler: @escaping (Bool) -> Void
    ) {
        certificateHandler(true)
    }
}

extension MultiplayerManager: MCNearbyServiceAdvertiserDelegate {
    nonisolated func advertiser(
        _ advertiser: MCNearbyServiceAdvertiser,
        didReceiveInvitationFromPeer peerID: MCPeerID,
        withContext context: Data?,
        invitationHandler: @escaping (Bool, MCSession?) -> Void
    ) {
        Task { @MainActor in
            invitationHandler(true, self.session)
        }
    }

    nonisolated func advertiser(
        _ advertiser: MCNearbyServiceAdvertiser,
        didNotStartAdvertisingPeer error: Error
    ) {
        Task { @MainActor in
            self.status = "Hosting failed: \(error.localizedDescription)"
        }
    }
}

extension MultiplayerManager: MCNearbyServiceBrowserDelegate {
    nonisolated func browser(
        _ browser: MCNearbyServiceBrowser,
        foundPeer peerID: MCPeerID,
        withDiscoveryInfo info: [String : String]?
    ) {
        Task { @MainActor in
            if !self.discoveredPeers.contains(peerID) {
                self.discoveredPeers.append(peerID)
            }
        }
    }

    nonisolated func browser(
        _ browser: MCNearbyServiceBrowser,
        lostPeer peerID: MCPeerID
    ) {
        Task { @MainActor in
            self.discoveredPeers.removeAll { $0 == peerID }
        }
    }

    nonisolated func browser(
        _ browser: MCNearbyServiceBrowser,
        didNotStartBrowsingForPeers error: Error
    ) {
        Task { @MainActor in
            self.status = "Browsing failed: \(error.localizedDescription)"
        }
    }
}
