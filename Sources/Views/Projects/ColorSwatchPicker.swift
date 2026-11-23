import SwiftUI

public struct ColorSwatchPicker: View {
    @Binding public var selectedHex: String
    @State private var customColor: Color

    public init(selectedHex: Binding<String>) {
        self._selectedHex = selectedHex
        self._customColor = State(initialValue: Color(hex: selectedHex.wrappedValue))
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Color")
                .font(AppTypography.label)
                .foregroundStyle(.secondary)

            HStack(spacing: AppSpacing.sm) {
                ForEach(AppColors.projectColors, id: \.self) { hex in
                    let isSelected = selectedHex.uppercased() == hex.uppercased()
                    Button {
                        selectedHex = hex
                        customColor = Color(hex: hex)
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color(hex: hex))
                                .frame(width: 22, height: 22)

                            if isSelected {
                                Circle()
                                    .strokeBorder(Color.primary.opacity(0.8), lineWidth: 2)
                                    .frame(width: 28, height: 28)
                            }
                        }
                        .frame(width: 28, height: 28)
                    }
                    .buttonStyle(.plain)
                    .help(hex)
                }

                Divider()
                    .frame(height: 20)
                    .padding(.horizontal, AppSpacing.xs)

                // Custom ColorPicker
                ColorPicker("", selection: Binding(
                    get: { customColor },
                    set: { newColor in
                        customColor = newColor
                        selectedHex = newColor.toHex()
                    }
                ), supportsOpacity: false)
                .labelsHidden()
                .help("Custom color")
            }
        }
    }
}
