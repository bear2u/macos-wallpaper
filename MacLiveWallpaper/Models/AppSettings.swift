import Foundation

public struct AppSettings: Codable, Equatable {
    public var launchAtLogin: Bool
    public var resumeLastWallpaper: Bool
    public var pauseOnSleep: Bool
    public var hideDockIcon: Bool
    public var defaultScalingMode: ScalingMode
    public var defaultIsMuted: Bool
    
    public static let `default` = AppSettings(
        launchAtLogin: false,
        resumeLastWallpaper: true,
        pauseOnSleep: true,
        hideDockIcon: false, // 기본값: 기존 방식 (Dock 표시)
        defaultScalingMode: .fill,
        defaultIsMuted: true
    )
}
