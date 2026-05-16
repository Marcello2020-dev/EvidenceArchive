import Foundation
import ImageIO
import UIKit
import Vision

enum TextRecognitionService {
    static func recognizeText(in image: UIImage) -> String {
        guard let cgImage = image.cgImage else { return "" }

        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.automaticallyDetectsLanguage = true

        let handler = VNImageRequestHandler(
            cgImage: cgImage,
            orientation: CGImagePropertyOrientation(image.imageOrientation),
            options: [:]
        )

        do {
            try handler.perform([request])
        } catch {
            return ""
        }

        return text(from: request.results ?? [])
    }

    static func recognizeText(in images: [UIImage]) -> String {
        images
            .map { recognizeText(in: $0) }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: "\n\n")
    }

    static func recognizeText(in data: Data, typeIdentifier: String?) -> String {
        guard isImage(typeIdentifier: typeIdentifier),
              let image = UIImage(data: data) else {
            return ""
        }

        return recognizeText(in: image)
    }

    static func recognizeText(inFileAt url: URL, typeIdentifier: String?) -> String {
        guard isImage(typeIdentifier: typeIdentifier),
              let data = try? Data(contentsOf: url) else {
            return ""
        }

        return recognizeText(in: data, typeIdentifier: typeIdentifier)
    }

    private static func text(from observations: [VNRecognizedTextObservation]) -> String {
        var lines: [String] = []

        for observation in observations {
            guard let candidate = observation.topCandidates(1).first else { continue }
            let line = candidate.string.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !line.isEmpty, !lines.contains(line) else { continue }
            lines.append(line)
        }

        return lines.joined(separator: "\n")
    }

    private static func isImage(typeIdentifier: String?) -> Bool {
        guard let typeIdentifier else { return false }
        return typeIdentifier.hasPrefix("public.image")
            || typeIdentifier.hasPrefix("com.apple.quicktime-image")
            || typeIdentifier == "public.jpeg"
            || typeIdentifier == "public.png"
            || typeIdentifier == "public.heic"
            || typeIdentifier == "public.heif"
    }
}

private extension CGImagePropertyOrientation {
    init(_ orientation: UIImage.Orientation) {
        switch orientation {
        case .up:
            self = .up
        case .upMirrored:
            self = .upMirrored
        case .down:
            self = .down
        case .downMirrored:
            self = .downMirrored
        case .left:
            self = .left
        case .leftMirrored:
            self = .leftMirrored
        case .right:
            self = .right
        case .rightMirrored:
            self = .rightMirrored
        @unknown default:
            self = .up
        }
    }
}
