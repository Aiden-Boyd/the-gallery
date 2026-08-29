import SwiftUI

struct MultiplayerLobbyView: View {
    @StateObject private var multiplayer = MultiplayerManager()
    @State private var started = false

    var body: some View {
        Group {
            if !multiplayer.connectedPeers.isEmpty {
                MuseumView(multiplayer: multiplayer)
            } else {
                List {
                    Section {
                        Button {
                            multiplayer.startHosting()
                            started = true
                        } label: {
                            Label("Host Game", systemImage: "wifi")
                        }

                        Button {
                            multiplayer.startBrowsing()
                            started = true
                        } label: {
                            Label("Join Game", systemImage: "magnifyingglass")
                        }
                    }

                    if started {
                        Section("Status") {
                            HStack {
                                ProgressView()
                                Text(multiplayer.status)
                            }
                        }
                    }

                    if !multiplayer.discoveredPeers.isEmpty {
                        Section("Nearby Games") {
                            ForEach(multiplayer.discoveredPeers, id: \.self) { peer in
                                Button {
                                    multiplayer.invite(peer)
                                } label: {
                                    HStack {
                                        Image(systemName: "iphone")
                                        Text(peer.displayName)
                                        Spacer()
                                        Text("Join")
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }

                    Section {
                        Text("Both iPhones should have Wi-Fi and Bluetooth turned on. They do not need to be connected to the internet.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .navigationTitle("Multiplayer")
            }
        }
        .onDisappear {
            multiplayer.disconnect()
        }
    }
}
