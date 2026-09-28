import AppKit

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let output = root.appendingPathComponent("Zentra/Assets.xcassets/AppIcon.appiconset", isDirectory: true)
try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)

let sizes = [16, 32, 64, 128, 256, 512, 1024]

func drawIcon(size: Int) throws {
    let s = CGFloat(size)
    let image = NSImage(size: NSSize(width: s, height: s))
    image.lockFocus()
    defer { image.unlockFocus() }

    guard let ctx = NSGraphicsContext.current?.cgContext else { return }
    ctx.setAllowsAntialiasing(true)
    ctx.setShouldAntialias(true)

    // macOS-style rounded tile with breathing room around the brand mark.
    let inset = s * 0.065
    let rect = CGRect(x: inset, y: inset, width: s - inset * 2, height: s - inset * 2)
    let radius = s * 0.215
    let path = CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
    ctx.saveGState()
    ctx.addPath(path)
    ctx.clip()

    let colors = [
        NSColor(red: 0.98, green: 0.66, blue: 0.35, alpha: 1).cgColor,
        NSColor(red: 0.91, green: 0.35, blue: 0.20, alpha: 1).cgColor
    ] as CFArray
    let space = CGColorSpaceCreateDeviceRGB()
    let gradient = CGGradient(colorsSpace: space, colors: colors, locations: [0, 1])!
    ctx.drawLinearGradient(gradient, start: CGPoint(x: rect.minX, y: rect.maxY), end: CGPoint(x: rect.maxX, y: rect.minY), options: [])

    // Soft premium highlight.
    let glow = CGGradient(colorsSpace: space, colors: [
        NSColor.white.withAlphaComponent(0.20).cgColor,
        NSColor.white.withAlphaComponent(0).cgColor
    ] as CFArray, locations: [0, 1])!
    ctx.drawRadialGradient(glow, startCenter: CGPoint(x: s * 0.30, y: s * 0.74), startRadius: 0, endCenter: CGPoint(x: s * 0.30, y: s * 0.74), endRadius: s * 0.62, options: [])
    ctx.restoreGState()

    // Same Z mark used by ZentraMark in the application.
    ctx.setStrokeColor(NSColor.white.withAlphaComponent(0.96).cgColor)
    ctx.setLineWidth(max(2, s * 0.078))
    ctx.setLineCap(.round)
    ctx.setLineJoin(.round)
    ctx.beginPath()
    ctx.move(to: CGPoint(x: s * 0.30, y: s * 0.68))
    ctx.addLine(to: CGPoint(x: s * 0.70, y: s * 0.68))
    ctx.addLine(to: CGPoint(x: s * 0.31, y: s * 0.32))
    ctx.addLine(to: CGPoint(x: s * 0.70, y: s * 0.32))
    ctx.strokePath()

    guard let tiff = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiff),
          let png = bitmap.representation(using: .png, properties: [:]) else { return }
    try png.write(to: output.appendingPathComponent("AppIcon-\(size).png"))
}

for size in sizes { try drawIcon(size: size) }
print("Generated Zentra AppIcon assets.")
