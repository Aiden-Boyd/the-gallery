import SwiftUI

struct AppRootView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [.black, Color(white: 0.12)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 26) {
                    Spacer()

                    Image(systemName: "photo.artframe")
                        .font(.system(size: 74))
                        .foregroundStyle(.white)

                    VStack(spacing: 5) {
                        Text("Gallery")
                            .font(.system(size: 46, weight: .bold, design: .rounded))

                        Text("Build a museum from your camera roll.")
                            .foregroundStyle(.secondary)

                        Text("BUILD MAIN-MENU-002")
                            .font(.caption2.monospaced())
                            .foregroundStyle(.tertiary)
                    }

                    Spacer()

                    VStack(spacing: 14) {
                        NavigationLink {
                            MuseumView()
                        } label: {
                            MenuButtonLabel(title: "Single Player", icon: "person.fill")
                        }

                        NavigationLink {
                            MultiplayerLobbyView()
                        } label: {
                            MenuButtonLabel(title: "Multiplayer", icon: "person.2.fill")
                        }

                        NavigationLink {
                            SettingsView()
                        } label: {
                            MenuButtonLabel(title: "Settings", icon: "gearshape.fill")
                        }
                    }
                    .buttonStyle(.plain)

                    Spacer()
                }
                .padding(.horizontal, 30)
            }
            .preferredColorScheme(.dark)
        }
    }
}

private struct MenuButtonLabel: View {
    let title: String
    let icon: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .frame(width: 28)

            Text(title)
                .font(.headline)

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 20)
        .frame(height: 62)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
        .foregroundStyle(.white)
    }
}
