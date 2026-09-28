import AppKit
import ImageIO
import UniformTypeIdentifiers

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let output = root.appendingPathComponent("Zentra/Assets.xcassets/AppIcon.appiconset", isDirectory: true)
try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)

let sizes = [16, 32, 64, 128, 256, 512, 1024]

func drawIcon(size: Int) throws {
    let width = size
    let height = size
    let bytesPerRow = width * 4
    let colorSpace = CGColorSpaceCreateDeviceRGB()

    guard let ctx = CGContext(
        data: nil,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: bytesPerRow,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else {
        throw NSError(domain: "ZentraIconGenerator", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not create bitmap context"])
    }

    let s = CGFloat(size)
    ctx.setAllowsAntialiasing(true)
    ctx.setShouldAntialias(true)

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
    let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0, 1])!
    ctx.drawLinearGradient(
        gradient,
        start: CGPoint(x: rect.minX, y: rect.maxY),
        end: CGPoint(x: rect.maxX, y: rect.minY),
        options: []
    )

    let glow = CGGradient(
        colorsSpace: colorSpace,
        colors: [
            NSColor.white.withAlphaComponent(0.20).cgColor,
            NSColor.white.withAlphaComponent(0).cgColor
        ] as CFArray,
        locations: [0, 1]
    )!
    ctx.drawRadialGradient(
        glow,
        startCenter: CGPoint(x: s * 0.30, y: s * 0.74),
        startRadius: 0,
        endCenter: CGPoint(x: s * 0.30, y: s * 0.74),
        endRadius: s * 0.62,
        options: []
    )
    ctx.restoreGState()

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

    guard let image = ctx.makeImage() else {
        throw NSError(domain: "ZentraIconGenerator", code: 2, userInfo: [NSLocalizedDescriptionKey: "Could not create CGImage"])
    }

    let destinationURL = output.appendingPathComponent("AppIcon-\(size).png")
    guard let destination = CGImageDestinationCreateWithURL(
        destinationURL as CFURL,
        UTType.png.identifier as CFString,
        1,
        nil
    ) else {
        throw NSError(domain: "ZentraIconGenerator", code: 3, userInfo: [NSLocalizedDescriptionKey: "Could not create PNG destination"])
    }

    CGImageDestinationAddImage(destination, image, nil)
    guard CGImageDestinationFinalize(destination) else {
        throw NSError(domain: "ZentraIconGenerator", code: 4, userInfo: [NSLocalizedDescriptionKey: "Could not write AppIcon-\(size).png"])
    }
}

for size in sizes {
    try drawIcon(size: size)
}

let generated = sizes.map { "AppIcon-\($0).png" }
for filename in generated {
    let url = output.appendingPathComponent(filename)
    guard FileManager.default.fileExists(atPath: url.path) else {
        throw NSError(domain: "ZentraIconGenerator", code: 5, userInfo: [NSLocalizedDescriptionKey: "Missing generated icon: \(filename)"])
    }
}

print("Generated Zentra AppIcon PNG assets: \(generated.joined(separator: ", "))")
