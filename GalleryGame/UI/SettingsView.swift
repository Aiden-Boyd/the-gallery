import SwiftUI

struct SettingsView: View {
    @AppStorage("movementSpeed") private var movementSpeed = 1.0
    @AppStorage("lookSensitivity") private var lookSensitivity = 1.0
    @AppStorage("showHints") private var showHints = true

    var body: some View {
        Form {
            Section("Controls") {
                VStack(alignment: .leading) {
                    HStack {
                        Text("Movement Speed")
                        Spacer()
                        Text(String(format: "%.1fx", movementSpeed))
                            .foregroundStyle(.secondary)
                    }

                    Slider(value: $movementSpeed, in: 0.5...2.0, step: 0.1)
                }

                VStack(alignment: .leading) {
                    HStack {
                        Text("Look Sensitivity")
                        Spacer()
                        Text(String(format: "%.1fx", lookSensitivity))
                            .foregroundStyle(.secondary)
                    }

                    Slider(value: $lookSensitivity, in: 0.5...2.0, step: 0.1)
                }
            }

            Section("Interface") {
                Toggle("Show gameplay hints", isOn: $showHints)
            }

            Section {
                Button("Reset Settings") {
                    movementSpeed = 1.0
                    lookSensitivity = 1.0
                    showHints = true
                }
            }
        }
        .navigationTitle("Settings")
    }
}
