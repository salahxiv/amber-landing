#!/usr/bin/env swift

import Foundation
import AppKit
import CoreGraphics

// MARK: - Icon Generator für EyeRest App
// Generiert ein minimalistisches Auge-Icon in allen benötigten macOS-Größen

/// Zeichnet das EyeRest App-Icon
/// - Parameter pixelSize: Die exakte Pixelgröße des Icons
/// - Returns: NSImage mit dem gezeichneten Icon
func createEyeIcon(pixelSize: Int) -> NSImage {
    let size = CGFloat(pixelSize)

    // Erstelle ein Bitmap-basiertes Image mit exakter Pixelgröße
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixelSize,
        pixelsHigh: pixelSize,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )!

    let image = NSImage(size: NSSize(width: size, height: size))
    image.addRepresentation(rep)

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

    guard let context = NSGraphicsContext.current?.cgContext else {
        NSGraphicsContext.restoreGraphicsState()
        return image
    }

    let rect = CGRect(x: 0, y: 0, width: size, height: size)

    // MARK: - Hintergrund mit Farbverlauf
    let gradientColors = [
        NSColor(red: 0.20, green: 0.60, blue: 0.95, alpha: 1.0).cgColor,  // Hellblau
        NSColor(red: 0.15, green: 0.45, blue: 0.85, alpha: 1.0).cgColor   // Dunkelblau
    ]
    let gradient = CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceRGB(),
        colors: gradientColors as CFArray,
        locations: [0.0, 1.0]
    )!

    // Abgerundetes Rechteck für macOS-Icon-Stil
    let cornerRadius = size * 0.22
    let backgroundPath = CGPath(
        roundedRect: rect.insetBy(dx: 1, dy: 1),
        cornerWidth: cornerRadius,
        cornerHeight: cornerRadius,
        transform: nil
    )

    context.saveGState()
    context.addPath(backgroundPath)
    context.clip()
    context.drawLinearGradient(
        gradient,
        start: CGPoint(x: 0, y: size),
        end: CGPoint(x: size, y: 0),
        options: []
    )
    context.restoreGState()

    // MARK: - Schatten für Tiefe
    context.saveGState()
    let shadowColor = NSColor.black.withAlphaComponent(0.3).cgColor
    context.setShadow(offset: CGSize(width: 0, height: -size * 0.02), blur: size * 0.05, color: shadowColor)

    // MARK: - Auge zeichnen
    let eyeWidth = size * 0.65
    let eyeHeight = size * 0.35
    let eyeCenterX = size / 2
    let eyeCenterY = size / 2

    // Äußere Augenform (Mandelform)
    let eyePath = CGMutablePath()

    // Linke Spitze
    let leftPoint = CGPoint(x: eyeCenterX - eyeWidth / 2, y: eyeCenterY)
    // Rechte Spitze
    let rightPoint = CGPoint(x: eyeCenterX + eyeWidth / 2, y: eyeCenterY)
    // Oberer Bogen Kontrollpunkte
    let topControl1 = CGPoint(x: eyeCenterX - eyeWidth * 0.25, y: eyeCenterY + eyeHeight * 0.9)
    let topControl2 = CGPoint(x: eyeCenterX + eyeWidth * 0.25, y: eyeCenterY + eyeHeight * 0.9)
    // Unterer Bogen Kontrollpunkte
    let bottomControl1 = CGPoint(x: eyeCenterX - eyeWidth * 0.25, y: eyeCenterY - eyeHeight * 0.9)
    let bottomControl2 = CGPoint(x: eyeCenterX + eyeWidth * 0.25, y: eyeCenterY - eyeHeight * 0.9)

    eyePath.move(to: leftPoint)
    eyePath.addCurve(to: rightPoint, control1: topControl1, control2: topControl2)
    eyePath.addCurve(to: leftPoint, control1: bottomControl2, control2: bottomControl1)
    eyePath.closeSubpath()

    // Weiße Augenfüllung
    context.setFillColor(NSColor.white.cgColor)
    context.addPath(eyePath)
    context.fillPath()

    context.restoreGState()

    // MARK: - Iris (blauer Ring)
    let irisRadius = eyeHeight * 0.55
    let irisRect = CGRect(
        x: eyeCenterX - irisRadius,
        y: eyeCenterY - irisRadius,
        width: irisRadius * 2,
        height: irisRadius * 2
    )

    // Iris-Farbverlauf
    let irisGradientColors = [
        NSColor(red: 0.25, green: 0.65, blue: 0.95, alpha: 1.0).cgColor,
        NSColor(red: 0.15, green: 0.40, blue: 0.75, alpha: 1.0).cgColor
    ]
    let irisGradient = CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceRGB(),
        colors: irisGradientColors as CFArray,
        locations: [0.0, 1.0]
    )!

    context.saveGState()
    context.addEllipse(in: irisRect)
    context.clip()
    context.drawRadialGradient(
        irisGradient,
        startCenter: CGPoint(x: eyeCenterX - irisRadius * 0.3, y: eyeCenterY + irisRadius * 0.3),
        startRadius: 0,
        endCenter: CGPoint(x: eyeCenterX, y: eyeCenterY),
        endRadius: irisRadius,
        options: []
    )
    context.restoreGState()

    // MARK: - Pupille (dunkler Kreis)
    let pupilRadius = irisRadius * 0.45
    let pupilRect = CGRect(
        x: eyeCenterX - pupilRadius,
        y: eyeCenterY - pupilRadius,
        width: pupilRadius * 2,
        height: pupilRadius * 2
    )

    context.setFillColor(NSColor(red: 0.1, green: 0.1, blue: 0.15, alpha: 1.0).cgColor)
    context.fillEllipse(in: pupilRect)

    // MARK: - Lichtreflex (weißer Punkt)
    let reflexRadius = pupilRadius * 0.35
    let reflexOffset = pupilRadius * 0.3
    let reflexRect = CGRect(
        x: eyeCenterX - reflexOffset - reflexRadius,
        y: eyeCenterY + reflexOffset - reflexRadius,
        width: reflexRadius * 2,
        height: reflexRadius * 2
    )

    context.setFillColor(NSColor.white.withAlphaComponent(0.9).cgColor)
    context.fillEllipse(in: reflexRect)

    // Kleiner sekundärer Reflex
    let smallReflexRadius = reflexRadius * 0.4
    let smallReflexRect = CGRect(
        x: eyeCenterX + reflexOffset * 0.5 - smallReflexRadius,
        y: eyeCenterY - reflexOffset * 0.8 - smallReflexRadius,
        width: smallReflexRadius * 2,
        height: smallReflexRadius * 2
    )
    context.setFillColor(NSColor.white.withAlphaComponent(0.6).cgColor)
    context.fillEllipse(in: smallReflexRect)

    NSGraphicsContext.restoreGraphicsState()

    return image
}

/// Speichert ein NSImage als PNG-Datei
func saveImageAsPNG(_ image: NSImage, to path: String) -> Bool {
    guard let tiffData = image.tiffRepresentation,
          let bitmapRep = NSBitmapImageRep(data: tiffData),
          let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
        print("Fehler: Konnte Bild nicht in PNG konvertieren")
        return false
    }

    do {
        try pngData.write(to: URL(fileURLWithPath: path))
        return true
    } catch {
        print("Fehler beim Speichern: \(error)")
        return false
    }
}

// MARK: - Hauptprogramm

print("🎨 EyeRest Icon Generator")
print("========================\n")

// Icon-Größen für macOS App
// Für macOS: Die Datei enthält die tatsächliche Pixelgröße
// 16x16@1x = 16px, 16x16@2x = 32px, 32x32@1x = 32px, 32x32@2x = 64px, etc.
let iconSizes: [(pixelSize: CGFloat, filename: String)] = [
    (16, "icon_16x16.png"),        // 16x16 @1x
    (32, "icon_16x16@2x.png"),     // 16x16 @2x = 32px
    (32, "icon_32x32.png"),        // 32x32 @1x
    (64, "icon_32x32@2x.png"),     // 32x32 @2x = 64px
    (128, "icon_128x128.png"),     // 128x128 @1x
    (256, "icon_128x128@2x.png"),  // 128x128 @2x = 256px
    (256, "icon_256x256.png"),     // 256x256 @1x
    (512, "icon_256x256@2x.png"),  // 256x256 @2x = 512px
    (512, "icon_512x512.png"),     // 512x512 @1x
    (1024, "icon_512x512@2x.png")  // 512x512 @2x = 1024px
]

// Ausgabepfad ermitteln
let scriptPath = URL(fileURLWithPath: CommandLine.arguments[0])
let projectRoot = scriptPath.deletingLastPathComponent().deletingLastPathComponent()
let outputPath = projectRoot.appendingPathComponent("EyeRest/Assets.xcassets/AppIcon.appiconset")

print("📁 Ausgabeverzeichnis: \(outputPath.path)\n")

// Prüfen ob Verzeichnis existiert
let fileManager = FileManager.default
if !fileManager.fileExists(atPath: outputPath.path) {
    print("❌ Fehler: AppIcon.appiconset nicht gefunden!")
    print("   Erwartet: \(outputPath.path)")
    exit(1)
}

// Icons generieren
var successCount = 0
for iconSpec in iconSizes {
    let icon = createEyeIcon(pixelSize: Int(iconSpec.pixelSize))
    let filePath = outputPath.appendingPathComponent(iconSpec.filename).path

    if saveImageAsPNG(icon, to: filePath) {
        let size = Int(iconSpec.pixelSize)
        print("✅ \(iconSpec.filename) (\(size)x\(size) px)")
        successCount += 1
    } else {
        print("❌ \(iconSpec.filename) - Fehler beim Speichern")
    }
}

print("\n📊 Ergebnis: \(successCount)/\(iconSizes.count) Icons erfolgreich erstellt")

// Contents.json aktualisieren
let contentsJson = """
{
  "images" : [
    {
      "filename" : "icon_16x16.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "16x16"
    },
    {
      "filename" : "icon_16x16@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "16x16"
    },
    {
      "filename" : "icon_32x32.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "32x32"
    },
    {
      "filename" : "icon_32x32@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "32x32"
    },
    {
      "filename" : "icon_128x128.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "128x128"
    },
    {
      "filename" : "icon_128x128@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "128x128"
    },
    {
      "filename" : "icon_256x256.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "256x256"
    },
    {
      "filename" : "icon_256x256@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "256x256"
    },
    {
      "filename" : "icon_512x512.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "512x512"
    },
    {
      "filename" : "icon_512x512@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "512x512"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
"""

let contentsPath = outputPath.appendingPathComponent("Contents.json").path
do {
    try contentsJson.write(toFile: contentsPath, atomically: true, encoding: .utf8)
    print("✅ Contents.json aktualisiert")
} catch {
    print("❌ Fehler beim Aktualisieren von Contents.json: \(error)")
}

print("\n🎉 Icon-Generierung abgeschlossen!")
print("   Führe 'xcodebuild clean build' aus, um die neuen Icons zu verwenden.")
