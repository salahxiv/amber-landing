import SwiftUI

/// Picker-Zeile für Sound-Auswahl mit Vorschau-Button
struct SoundPickerRow: View {
    let label: String
    @Binding var selection: String
    let sounds: [AudioService.SoundOption]

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)

            Spacer()

            Picker("", selection: $selection) {
                ForEach(sounds) { sound in
                    Text(sound.label).tag(sound.id)
                }
            }
            #if os(macOS)
            .frame(width: 120)
            #endif
            .labelsHidden()

            Button {
                AudioService.shared.previewSound(id: selection)
            } label: {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.accentColor)
            }
            .buttonStyle(.plain)
        }
    }
}
