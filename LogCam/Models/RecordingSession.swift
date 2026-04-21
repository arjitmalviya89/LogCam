import Foundation

struct RecordingSession: Identifiable {
    let id = UUID()
    let url: URL
    let duration: TimeInterval
    let date: Date
    let isAppleLog: Bool
    let resolution: String
    let fps: Int

    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var thumbnail: URL? {
        return url
    }
}

enum Resolution: String, CaseIterable, Identifiable {
    case uhd4k = "4K (3840×2160)"
    case fhd1080 = "1080p (1920×1080)"
    case hd720 = "720p (1280×720)"

    var id: String { rawValue }

    var width: Int {
        switch self {
        case .uhd4k: return 3840
        case .fhd1080: return 1920
        case .hd720: return 1280
        }
    }

    var height: Int {
        switch self {
        case .uhd4k: return 2160
        case .fhd1080: return 1080
        case .hd720: return 720
        }
    }
}

enum FrameRate: Int, CaseIterable, Identifiable {
    case fps24 = 24
    case fps30 = 30
    case fps60 = 60

    var id: Int { rawValue }
    var label: String { "\(rawValue) fps" }
}
