import Foundation

enum FreeUsageLimits {
    static let isEnabled = true

    static let maxCaseFiles = 2
    static let maxEvidenceItemsPerCase = 3

    static func canCreateCase(currentCaseCount: Int, hasFullAccess: Bool) -> Bool {
        guard isEnabled else { return true }
        return hasFullAccess || currentCaseCount < maxCaseFiles
    }

    static func canAddEvidence(
        currentEvidenceCount: Int,
        adding newEvidenceCount: Int,
        hasFullAccess: Bool
    ) -> Bool {
        guard isEnabled else { return true }
        return hasFullAccess || currentEvidenceCount + max(0, newEvidenceCount) <= maxEvidenceItemsPerCase
    }
}
