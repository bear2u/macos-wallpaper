import Foundation

public struct AppSettings: Codable, Equatable {
    public var launchAtLogin: Bool
    public var resumeLastWallpaper: Bool
    public var pauseOnSleep: Bool
    public var defaultScalingMode: ScalingMode
    public var defaultIsMuted: Bool
    
    public static let `default` = AppSettings(
        launchAtLogin: false,
        resumeLastWallpaper: true,
        pauseOnSleep: true,
        defaultScalingMode: .fill,
        defaultIsMuted: true
    )
}
