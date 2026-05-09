import EvidenceArchiveCore
import Foundation
import XCTest

final class EvidenceArchiveCoreTests: XCTestCase {
    func testSafeFilenameSanitizesForbiddenCharacters() {
        let value = SafeFilename.sanitizeStem("  invoice:/2026*final?  ")
        XCTAssertEqual(value, "invoice__2026_final_")
    }

    func testSafeFilenameResolvesDuplicates() {
        let fixedDate = Date(timeIntervalSince1970: 1_700_000_000)
        let existing: Set<String> = [
            "20231114_221320_document.pdf",
            "20231114_221320_document_2.pdf"
        ]

        let resolved = SafeFilename.makeStoredFilename(
            originalFilename: "document.pdf",
            eventDate: fixedDate,
            existingNames: existing
        )

        XCTAssertEqual(resolved, "20231114_221320_document_3.pdf")
    }

    func testSHA256MatchesKnownVector() {
        let hash = HashService().sha256Hex(for: Data("abc".utf8))
        XCTAssertEqual(hash, "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
    }

    func testCSVEscapesQuotesCommasAndNewlines() {
        let input = "hello, \"world\"\nline2"
        let output = CSVEncoder.escape(input)
        XCTAssertEqual(output, "\"hello, \"\"world\"\"\nline2\"")
    }
}
