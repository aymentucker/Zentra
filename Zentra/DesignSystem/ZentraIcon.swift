import AppKit
import SwiftUI

struct ZentraIcon: View {
    let name: String

    var body: some View {
        if let image = loadSVG() {
            Image(nsImage: image)
                .resizable()
                .renderingMode(.template)
                .scaledToFit()
        } else {
            fallback
        }
    }

    private func loadSVG() -> NSImage? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "svg", subdirectory: "Icons") ??
                        Bundle.main.url(forResource: name, withExtension: "svg") else {
            return nil
        }
        return NSImage(contentsOf: url)
    }

    private var fallback: some View {
        RoundedRectangle(cornerRadius: 4, style: .continuous)
            .stroke(lineWidth: 1.5)
            .padding(2)
    }
}
