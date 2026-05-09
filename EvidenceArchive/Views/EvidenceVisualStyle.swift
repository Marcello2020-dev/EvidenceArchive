import SwiftUI

extension CaseCategory {
    var tintColor: Color {
        switch self {
        case .privateCase:
            return .indigo
        case .work:
            return .blue
        case .housing:
            return .teal
        case .insurance:
            return .green
        case .authority:
            return .purple
        case .onlineFraud:
            return .red
        case .other:
            return .gray
        }
    }

    var iconName: String {
        switch self {
        case .privateCase:
            return "lock.shield"
        case .work:
            return "briefcase"
        case .housing:
            return "house"
        case .insurance:
            return "checkmark.shield"
        case .authority:
            return "building.columns"
        case .onlineFraud:
            return "exclamationmark.shield"
        case .other:
            return "folder"
        }
    }
}

extension EvidenceType {
    var tintColor: Color {
        switch self {
        case .pdf:
            return .red
        case .image:
            return .cyan
        case .audio:
            return .purple
        case .video:
            return .pink
        case .text:
            return .blue
        case .zip:
            return .orange
        case .webLink:
            return .teal
        case .other:
            return .gray
        }
    }
}

struct IconBadge: View {
    let systemName: String
    let color: Color
    var size: CGFloat = 42

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.16))
            Image(systemName: systemName)
                .font(.system(size: size * 0.42, weight: .semibold))
                .foregroundStyle(color)
        }
        .frame(width: size, height: size)
    }
}

struct CapsuleBadge: View {
    let text: String
    let systemName: String?
    let color: Color

    init(_ text: String, systemName: String? = nil, color: Color) {
        self.text = text
        self.systemName = systemName
        self.color = color
    }

    var body: some View {
        HStack(spacing: 4) {
            if let systemName {
                Image(systemName: systemName)
            }
            Text(text)
        }
        .font(.caption.weight(.medium))
        .foregroundStyle(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.12), in: Capsule())
    }
}

struct ImportActionLabel: View {
    let title: String
    let systemName: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            IconBadge(systemName: systemName, color: color, size: 34)
            Text(title)
                .foregroundStyle(.primary)
            Spacer()
        }
        .padding(.vertical, 2)
    }
}
