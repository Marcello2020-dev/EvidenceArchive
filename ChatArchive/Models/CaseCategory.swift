import Foundation

enum CaseCategory: String, Codable, CaseIterable, Identifiable {
    case privateCase = "Private"
    case work = "Work"
    case housing = "Housing"
    case insurance = "Insurance"
    case authority = "Authority"
    case onlineFraud = "Online Fraud"
    case other = "Other"

    var id: String { rawValue }
}
