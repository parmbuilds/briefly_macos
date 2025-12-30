import SwiftUI

struct ReadingSettingsView: View {
    @ObservedObject var settings: ReadingSettings

    var body: some View {
        Form {
            Section("Typography") {
                HStack {
                    Text("A")
                        .font(.custom("System", size: 12))
                    Slider(value: $settings.fontSize, in: 12...32, step: 1)
                    Text("A")
                        .font(.custom("System", size: 24))
                }
                Text("Size: \(Int(settings.fontSize))pt")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Layout") {
                VStack(alignment: .leading) {
                    Text("Alignment")
                    Picker("Alignment", selection: $settings.textAlignment) {
                        Image(systemName: "text.alignleft").tag("Leading")
                        Image(systemName: "text.aligncenter").tag("Center")
                        Image(systemName: "text.alignright").tag("Trailing")
                    }
                    .pickerStyle(.segmented)
                }

                VStack(alignment: .leading) {
                    Text("Line Spacing: \(String(format: "%.1f", settings.lineSpacing))")
                    Slider(value: $settings.lineSpacing, in: 1.0...3.0, step: 0.1)
                        { Text("Line Spacing") } minimumValueLabel: {
                            Image(systemName: "arrow.up.and.down.text.horizontal").scaleEffect(0.7)
                        } maximumValueLabel: {
                            Image(systemName: "arrow.up.and.down.text.horizontal").scaleEffect(1.3)
                        }
                }

                VStack(alignment: .leading) {
                    Text("Character Spacing: \(String(format: "%.1f", settings.characterSpacing))")
                    Slider(value: $settings.characterSpacing, in: -2.0...10.0, step: 0.5)
                        { Text("Kerning") } minimumValueLabel: {
                            Image(systemName: "textformat.size").scaleEffect(0.7)
                        } maximumValueLabel: {
                            Image(systemName: "textformat.size").scaleEffect(1.3)
                        }
                }
            }
        }
        .formStyle(.grouped)
        .frame(minWidth: 300, minHeight: 400)
    }
}
