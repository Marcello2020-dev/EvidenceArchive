import SwiftUI
import UIKit
import UniformTypeIdentifiers
import VisionKit

struct DocumentScannerView: UIViewControllerRepresentable {
    let onScan: (Result<EvidenceStore.DataImportPayload, Error>) -> Void

    @Environment(\.dismiss) private var dismiss

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let controller = VNDocumentCameraViewController()
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) { }

    final class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        private let parent: DocumentScannerView

        init(parent: DocumentScannerView) {
            self.parent = parent
        }

        func documentCameraViewController(
            _ controller: VNDocumentCameraViewController,
            didFinishWith scan: VNDocumentCameraScan
        ) {
            do {
                let payload = try Self.makePayload(from: scan)
                parent.onScan(.success(payload))
            } catch {
                parent.onScan(.failure(error))
            }
            parent.dismiss()
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            parent.dismiss()
        }

        func documentCameraViewController(
            _ controller: VNDocumentCameraViewController,
            didFailWithError error: Error
        ) {
            parent.onScan(.failure(error))
            parent.dismiss()
        }

        private static func makePayload(from scan: VNDocumentCameraScan) throws -> EvidenceStore.DataImportPayload {
            guard scan.pageCount > 0 else {
                throw EvidenceError.importFailed(L10n.text("Scanned document was empty."))
            }

            let images = (0..<scan.pageCount).map { scan.imageOfPage(at: $0) }
            let data = renderPDF(from: images)
            let recognizedText = TextRecognitionService.recognizeText(in: images)

            return EvidenceStore.DataImportPayload(
                data: data,
                suggestedFilename: "\(L10n.text("Scanned Document")) \(Self.filenameTimestamp()).pdf",
                typeIdentifier: UTType.pdf.identifier,
                recognizedText: recognizedText
            )
        }

        private static func renderPDF(from images: [UIImage]) -> Data {
            let pageBounds = CGRect(x: 0, y: 0, width: 612, height: 792)
            let contentBounds = pageBounds.insetBy(dx: 36, dy: 36)
            let renderer = UIGraphicsPDFRenderer(bounds: pageBounds)

            return renderer.pdfData { context in
                for image in images {
                    let imageSize = image.size
                    let scale = min(
                        contentBounds.width / imageSize.width,
                        contentBounds.height / imageSize.height
                    )
                    let drawSize = CGSize(
                        width: imageSize.width * scale,
                        height: imageSize.height * scale
                    )
                    let drawOrigin = CGPoint(
                        x: pageBounds.midX - drawSize.width / 2,
                        y: pageBounds.midY - drawSize.height / 2
                    )

                    context.beginPage()
                    image.draw(in: CGRect(origin: drawOrigin, size: drawSize))
                }
            }
        }

        private static func filenameTimestamp() -> String {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = .current
            formatter.dateFormat = "yyyyMMdd_HHmmss"
            return formatter.string(from: Date())
        }
    }
}
