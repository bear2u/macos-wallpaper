import Foundation
import CoreGraphics

public enum MediaKind: String, Codable {
    case video
    case image
}

public enum ScalingMode: String, Codable, CaseIterable, Identifiable {
    case fill = "fill"
    case fit = "fit"
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .fill: return "Fill"
        case .fit: return "Fit"
        }
    }
    
    public var description: String {
        switch self {
        case .fill: return "Fills the screen (aspect ratio preserved, cropped if needed)"
        case .fit: return "Fits inside the screen (aspect ratio preserved, black borders if needed)"
        }
    }
}

public enum PlaybackOrder: String, Codable, CaseIterable, Identifiable {
    case sequential = "sequential"
    case random = "random"
    
    public var id: String { rawValue }
    public var displayName: String {
        switch self {
        case .sequential: return "Sequential (In Order)"
        case .random: return "Random (Shuffle)"
        }
    }
}

public enum SwitchInterval: String, Codable, CaseIterable, Identifiable {
    case onEnd = "onEnd"
    case min1 = "1min"
    case min5 = "5min"
    case min15 = "15min"
    case min30 = "30min"
    case hour1 = "1hour"
    
    public var id: String { rawValue }
    public var displayName: String {
        switch self {
        case .onEnd: return "When Video Ends"
        case .min1: return "Every 1 minute"
        case .min5: return "Every 5 minutes"
        case .min15: return "Every 15 minutes"
        case .min30: return "Every 30 minutes"
        case .hour1: return "Every 1 hour"
        }
    }
    
    public var timeIntervalSeconds: TimeInterval? {
        switch self {
        case .onEnd: return nil
        case .min1: return 60
        case .min5: return 300
        case .min15: return 900
        case .min30: return 1800
        case .hour1: return 3600
        }
    }
}

public struct Wallpaper: Identifiable, Codable, Equatable {
    public let id: UUID
    public var name: String
    public var fileURL: URL
    public var mediaKind: MediaKind
    public var scalingMode: ScalingMode
    public var isMuted: Bool
    public var isStatic: Bool
    public var bookmarkData: Data?
    
    public init(
        id: UUID = UUID(),
        name: String,
        fileURL: URL,
        mediaKind: MediaKind? = nil,
        scalingMode: ScalingMode = .fill,
        isMuted: Bool = true,
        isStatic: Bool = false,
        bookmarkData: Data? = nil
    ) {
        self.id = id
        self.name = name
        self.fileURL = fileURL
        self.mediaKind = mediaKind ?? Wallpaper.detectMediaKind(for: fileURL)
        self.scalingMode = scalingMode
        self.isMuted = isMuted
        self.isStatic = isStatic
        self.bookmarkData = bookmarkData
    }
    
    public static func detectMediaKind(for url: URL) -> MediaKind {
        let ext = url.pathExtension.lowercased()
        let imageExtensions = ["png", "jpg", "jpeg", "heic", "heif", "tiff", "bmp", "webp", "gif"]
        if imageExtensions.contains(ext) {
            return .image
        } else {
            return .video
        }
    }
}

public struct VideoMetadata: Sendable {
    public let duration: TimeInterval
    public let resolution: CGSize
    public let fileSize: Int64
    public let isImage: Bool
    
    public init(duration: TimeInterval, resolution: CGSize, fileSize: Int64, isImage: Bool = false) {
        self.duration = duration
        self.resolution = resolution
        self.fileSize = fileSize
        self.isImage = isImage
    }
    
    public var formattedDuration: String {
        if isImage { return "Image" }
        let seconds = Int(duration)
        let mins = seconds / 60
        let secs = seconds % 60
        if mins > 0 {
            return String(format: "%d min %d sec", mins, secs)
        } else {
            return String(format: "%d sec", secs)
        }
    }
    
    public var formattedResolution: String {
        return "\(Int(resolution.width)) × \(Int(resolution.height))"
    }
    
    public var formattedFileSize: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: fileSize)
    }
}
