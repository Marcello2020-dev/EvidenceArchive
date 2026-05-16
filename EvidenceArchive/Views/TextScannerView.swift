import SwiftUI
import VisionKit

struct TextScannerView: UIViewControllerRepresentable {
    @Binding var recognizedText: String
    @Binding var scannerError: String?

    @MainActor
    static var isAvailable: Bool {
        DataScannerViewController.isSupported && DataScannerViewController.isAvailable
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = DataScannerViewController(
            recognizedDataTypes: [.text()],
            qualityLevel: .accurate,
            recognizesMultipleItems: true,
            isHighFrameRateTrackingEnabled: false,
            isPinchToZoomEnabled: true,
            isGuidanceEnabled: true,
            isHighlightingEnabled: true
        )
        scanner.delegate = context.coordinator
        return scanner
    }

    func updateUIViewController(_ scanner: DataScannerViewController, context: Context) {
        guard !scanner.isScanning else { return }

        do {
            try scanner.startScanning()
        } catch {
            scannerError = error.localizedDescription
        }
    }

    static func dismantleUIViewController(_ scanner: DataScannerViewController, coordinator: Coordinator) {
        scanner.stopScanning()
    }

    @MainActor
    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        private var parent: TextScannerView

        init(parent: TextScannerView) {
            self.parent = parent
        }

        func dataScanner(
            _ dataScanner: DataScannerViewController,
            didAdd addedItems: [RecognizedItem],
            allItems: [RecognizedItem]
        ) {
            updateRecognizedText(from: allItems)
        }

        func dataScanner(
            _ dataScanner: DataScannerViewController,
            didUpdate updatedItems: [RecognizedItem],
            allItems: [RecognizedItem]
        ) {
            updateRecognizedText(from: allItems)
        }

        func dataScanner(
            _ dataScanner: DataScannerViewController,
            didRemove removedItems: [RecognizedItem],
            allItems: [RecognizedItem]
        ) {
            updateRecognizedText(from: allItems)
        }

        func dataScanner(
            _ dataScanner: DataScannerViewController,
            becameUnavailableWithError error: DataScannerViewController.ScanningUnavailable
        ) {
            parent.scannerError = Self.message(for: error)
        }

        private func updateRecognizedText(from items: [RecognizedItem]) {
            var lines: [String] = []

            for item in items {
                guard case .text(let text) = item else { continue }
                let transcript = text.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !transcript.isEmpty, !lines.contains(transcript) else { continue }
                lines.append(transcript)
            }

            parent.recognizedText = lines.joined(separator: "\n")
        }

        private static func message(for error: DataScannerViewController.ScanningUnavailable) -> String {
            switch error {
            case .cameraRestricted:
                return L10n.text("Camera access is restricted.")
            case .unsupported:
                return L10n.text("Text scanner is not available on this device.")
            @unknown default:
                return L10n.text("Text scanner is not available right now.")
            }
        }
    }
}
