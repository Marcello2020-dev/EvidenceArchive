import QuickLookThumbnailing
import SwiftUI
import UIKit

struct EvidenceThumbnailView: View {
    let evidence: EvidenceItem
    var size: CGFloat = 48

    @State private var thumbnail: UIImage?

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Group {
                if let thumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .scaledToFill()
                        .frame(width: size, height: size)
                } else {
                    IconBadge(
                        systemName: evidence.evidenceType.iconName,
                        color: evidence.evidenceType.tintColor,
                        size: size
                    )
                }
            }
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(.quaternary, lineWidth: 1)
            }

            Image(systemName: "eye.fill")
                .font(.system(size: max(10, size * 0.22), weight: .semibold))
                .foregroundStyle(.white)
                .padding(max(4, size * 0.08))
                .background(.blue, in: Circle())
                .overlay {
                    Circle()
                        .strokeBorder(.background, lineWidth: 1)
                }
                .offset(x: 4, y: 4)
        }
        .frame(width: size + 4, height: size + 4)
        .onAppear(perform: loadThumbnail)
        .onChange(of: evidence.storedFilename) { _, _ in
            thumbnail = nil
            loadThumbnail()
        }
    }

    private func loadThumbnail() {
        guard thumbnail == nil,
              let url = try? StorageLayout.storedFileURL(for: evidence) else {
            return
        }

        let requestSize = CGSize(width: size * 2, height: size * 2)
        let request = QLThumbnailGenerator.Request(
            fileAt: url,
            size: requestSize,
            scale: UIScreen.main.scale,
            representationTypes: .all
        )

        QLThumbnailGenerator.shared.generateBestRepresentation(for: request) { representation, _ in
            guard let image = representation?.uiImage else { return }
            DispatchQueue.main.async {
                thumbnail = image
            }
        }
    }
}
