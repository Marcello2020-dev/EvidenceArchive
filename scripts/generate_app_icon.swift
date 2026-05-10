import AppKit
import Foundation
import ImageIO
import UniformTypeIdentifiers

struct IconOutput {
    let filename: String
    let pixels: Int
}

let outputDirectory = URL(fileURLWithPath: "EvidenceArchive/Assets.xcassets/AppIcon.appiconset")

let outputs: [IconOutput] = [
    IconOutput(filename: "Icon-20.png", pixels: 20),
    IconOutput(filename: "Icon-20@2x.png", pixels: 40),
    IconOutput(filename: "Icon-20@3x.png", pixels: 60),
    IconOutput(filename: "Icon-29.png", pixels: 29),
    IconOutput(filename: "Icon-29@2x.png", pixels: 58),
    IconOutput(filename: "Icon-29@3x.png", pixels: 87),
    IconOutput(filename: "Icon-40.png", pixels: 40),
    IconOutput(filename: "Icon-40@2x.png", pixels: 80),
    IconOutput(filename: "Icon-40@3x.png", pixels: 120),
    IconOutput(filename: "Icon-60@2x.png", pixels: 120),
    IconOutput(filename: "Icon-60@3x.png", pixels: 180),
    IconOutput(filename: "Icon-76.png", pixels: 76),
    IconOutput(filename: "Icon-76@2x.png", pixels: 152),
    IconOutput(filename: "Icon-83.5@2x.png", pixels: 167),
    IconOutput(filename: "Icon-1024.png", pixels: 1024)
]

func color(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat, _ alpha: CGFloat = 1) -> NSColor {
    NSColor(srgbRed: red / 255, green: green / 255, blue: blue / 255, alpha: alpha)
}

func rect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> NSRect {
    NSRect(x: x, y: y, width: w, height: h)
}

func roundedRect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ radius: CGFloat) -> NSBezierPath {
    NSBezierPath(roundedRect: rect(x, y, w, h), xRadius: radius, yRadius: radius)
}

func drawScaledIcon(pixels: Int) throws -> NSBitmapImageRep {
    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixels,
        pixelsHigh: pixels,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 32
    ), let graphicsContext = NSGraphicsContext(bitmapImageRep: bitmap) else {
        throw NSError(domain: "GenerateAppIcon", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not create bitmap context"])
    }

    bitmap.size = NSSize(width: pixels, height: pixels)

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = graphicsContext
    defer { NSGraphicsContext.restoreGraphicsState() }

    let context = graphicsContext.cgContext
    let scale = CGFloat(pixels) / 1024
    context.scaleBy(x: scale, y: scale)
    context.setAllowsAntialiasing(true)
    context.setShouldAntialias(true)

    let canvas = rect(0, 0, 1024, 1024)
    let gradient = NSGradient(colors: [
        color(28, 44, 123),
        color(15, 127, 143),
        color(80, 174, 112)
    ])
    gradient?.draw(in: canvas, angle: 135)

    context.saveGState()
    color(255, 255, 255, 0.08).setFill()
    for index in 0..<5 {
        let offset = CGFloat(index) * 205 - 180
        let path = NSBezierPath()
        path.move(to: NSPoint(x: offset, y: -80))
        path.line(to: NSPoint(x: offset + 190, y: -80))
        path.line(to: NSPoint(x: offset + 720, y: 1104))
        path.line(to: NSPoint(x: offset + 530, y: 1104))
        path.close()
        path.fill()
    }
    context.restoreGState()

    let glow = NSBezierPath(ovalIn: rect(185, 155, 660, 660))
    color(255, 255, 255, 0.10).setFill()
    glow.fill()

    context.saveGState()
    context.setShadow(offset: CGSize(width: 0, height: -28), blur: 46, color: color(0, 24, 44, 0.33).cgColor)
    color(255, 195, 76).setFill()
    roundedRect(168, 590, 372, 146, 44).fill()
    context.restoreGState()

    context.saveGState()
    context.setShadow(offset: CGSize(width: 0, height: -28), blur: 50, color: color(0, 24, 44, 0.38).cgColor)
    let body = roundedRect(132, 270, 760, 462, 86)
    NSGradient(colors: [
        color(255, 226, 126),
        color(245, 171, 57)
    ])?.draw(in: body, angle: 90)
    context.restoreGState()

    color(34, 62, 139, 0.26).setFill()
    roundedRect(162, 630, 700, 56, 28).fill()

    color(255, 255, 255, 0.22).setFill()
    roundedRect(172, 620, 470, 28, 14).fill()

    context.saveGState()
    context.setShadow(offset: CGSize(width: 0, height: -12), blur: 26, color: color(0, 24, 44, 0.25).cgColor)
    let document = roundedRect(300, 345, 340, 455, 36)
    color(249, 253, 255).setFill()
    document.fill()
    context.restoreGState()

    let fold = NSBezierPath()
    fold.move(to: NSPoint(x: 568, y: 800))
    fold.line(to: NSPoint(x: 640, y: 728))
    fold.line(to: NSPoint(x: 568, y: 728))
    fold.close()
    color(209, 232, 245).setFill()
    fold.fill()

    let lineColors = [
        color(31, 118, 153, 0.58),
        color(31, 118, 153, 0.42),
        color(31, 118, 153, 0.34)
    ]
    for (index, y) in [690, 630, 570].enumerated() {
        lineColors[index].setFill()
        roundedRect(350, CGFloat(y), 220, 22, 11).fill()
    }

    color(234, 147, 43, 0.18).setFill()
    roundedRect(350, 505, 150, 20, 10).fill()

    context.saveGState()
    context.setShadow(offset: CGSize(width: 0, height: -14), blur: 28, color: color(0, 24, 44, 0.30).cgColor)
    let shield = NSBezierPath()
    shield.move(to: NSPoint(x: 682, y: 596))
    shield.curve(to: NSPoint(x: 792, y: 548), controlPoint1: NSPoint(x: 714, y: 584), controlPoint2: NSPoint(x: 754, y: 572))
    shield.curve(to: NSPoint(x: 744, y: 350), controlPoint1: NSPoint(x: 792, y: 466), controlPoint2: NSPoint(x: 774, y: 396))
    shield.curve(to: NSPoint(x: 682, y: 304), controlPoint1: NSPoint(x: 722, y: 327), controlPoint2: NSPoint(x: 701, y: 312))
    shield.curve(to: NSPoint(x: 620, y: 350), controlPoint1: NSPoint(x: 663, y: 312), controlPoint2: NSPoint(x: 642, y: 327))
    shield.curve(to: NSPoint(x: 572, y: 548), controlPoint1: NSPoint(x: 590, y: 396), controlPoint2: NSPoint(x: 572, y: 466))
    shield.curve(to: NSPoint(x: 682, y: 596), controlPoint1: NSPoint(x: 610, y: 572), controlPoint2: NSPoint(x: 650, y: 584))
    shield.close()
    NSGradient(colors: [
        color(37, 209, 171),
        color(12, 125, 148)
    ])?.draw(in: shield, angle: 90)
    context.restoreGState()

    let check = NSBezierPath()
    check.move(to: NSPoint(x: 623, y: 457))
    check.line(to: NSPoint(x: 666, y: 414))
    check.line(to: NSPoint(x: 746, y: 506))
    check.lineWidth = 38
    check.lineCapStyle = .round
    check.lineJoinStyle = .round
    color(255, 255, 255).setStroke()
    check.stroke()

    color(255, 255, 255, 0.18).setStroke()
    let rim = roundedRect(96, 96, 832, 832, 190)
    rim.lineWidth = 12
    rim.stroke()

    return bitmap
}

func writePNG(_ bitmap: NSBitmapImageRep, to url: URL) throws {
    guard let source = bitmap.bitmapData else {
        throw NSError(domain: "GenerateAppIcon", code: 2, userInfo: [NSLocalizedDescriptionKey: "Could not access bitmap data"])
    }

    let width = bitmap.pixelsWide
    let height = bitmap.pixelsHigh
    let sourceBytesPerRow = bitmap.bytesPerRow
    let sourceSamplesPerPixel = bitmap.samplesPerPixel
    var rgbData = Data(count: width * height * 3)

    rgbData.withUnsafeMutableBytes { destinationBuffer in
        guard let destination = destinationBuffer.bindMemory(to: UInt8.self).baseAddress else { return }

        for y in 0..<height {
            for x in 0..<width {
                let sourceIndex = y * sourceBytesPerRow + x * sourceSamplesPerPixel
                let destinationIndex = (y * width + x) * 3
                destination[destinationIndex] = source[sourceIndex]
                destination[destinationIndex + 1] = source[sourceIndex + 1]
                destination[destinationIndex + 2] = source[sourceIndex + 2]
            }
        }
    }

    guard let provider = CGDataProvider(data: rgbData as CFData),
          let image = CGImage(
              width: width,
              height: height,
              bitsPerComponent: 8,
              bitsPerPixel: 24,
              bytesPerRow: width * 3,
              space: CGColorSpaceCreateDeviceRGB(),
              bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue),
              provider: provider,
              decode: nil,
              shouldInterpolate: true,
              intent: .defaultIntent
          ),
          let destination = CGImageDestinationCreateWithURL(
              url as CFURL,
              UTType.png.identifier as CFString,
              1,
              nil
          ) else {
        throw NSError(domain: "GenerateAppIcon", code: 3, userInfo: [NSLocalizedDescriptionKey: "Could not encode RGB PNG"])
    }

    CGImageDestinationAddImage(destination, image, nil)
    if !CGImageDestinationFinalize(destination) {
        throw NSError(domain: "GenerateAppIcon", code: 4, userInfo: [NSLocalizedDescriptionKey: "Could not write PNG"])
    }
}

try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

for output in outputs {
    let icon = try drawScaledIcon(pixels: output.pixels)
    try writePNG(icon, to: outputDirectory.appendingPathComponent(output.filename))
}

print("Generated \(outputs.count) app icon PNGs in \(outputDirectory.path)")
