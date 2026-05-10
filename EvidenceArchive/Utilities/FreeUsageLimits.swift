import Foundation

enum FreeUsageLimits {
    // Keep the freemium implementation in place, but disable enforcement for now.
    // Set this to true later to re-enable the 2-case / 3-evidence free limits.
    static let isEnabled = false

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
