import Foundation
import Combine

public final class PreferenceStore: ObservableObject {
    public static let shared = PreferenceStore()
    
    private let userDefaults = UserDefaults.standard
    
    private enum Keys {
        static let lastWallpaperBookmark = "lastWallpaperBookmark"
        static let lastWallpaperName = "lastWallpaperName"
        static let lastWallpaperURL = "lastWallpaperURL"
        static let scalingMode = "scalingMode"
        static let isMuted = "isMuted"
        static let isStatic = "isStatic"
        static let appSettings = "appSettings"
    }
    
    @Published public var settings: AppSettings {
        didSet {
            saveSettings()
        }
    }
    
    private init() {
        if let data = userDefaults.data(forKey: Keys.appSettings),
           let decoded = try? JSONDecoder().decode(AppSettings.self, from: data) {
            self.settings = decoded
        } else {
            self.settings = .default
        }
    }
    
    private func saveSettings() {
        if let encoded = try? JSONEncoder().encode(settings) {
            userDefaults.set(encoded, forKey: Keys.appSettings)
        }
    }
    
    // MARK: - Bookmark & Last Wallpaper Storage
    
    public func saveLastWallpaper(_ wallpaper: Wallpaper) {
        userDefaults.set(wallpaper.name, forKey: Keys.lastWallpaperName)
        userDefaults.set(wallpaper.scalingMode.rawValue, forKey: Keys.scalingMode)
        userDefaults.set(wallpaper.isMuted, forKey: Keys.isMuted)
        userDefaults.set(wallpaper.isStatic, forKey: Keys.isStatic)
        
        // Security scoped bookmark 생성
        let url = wallpaper.fileURL
        do {
            let bookmarkData = try url.bookmarkData(
                options: .withSecurityScope,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            userDefaults.set(bookmarkData, forKey: Keys.lastWallpaperBookmark)
            userDefaults.set(url.path, forKey: Keys.lastWallpaperURL)
        } catch {
            print("[PreferenceStore] Failed to create bookmark data: \(error.localizedDescription)")
            userDefaults.set(url.path, forKey: Keys.lastWallpaperURL)
        }
    }
    
    public func loadLastWallpaper() -> Wallpaper? {
        guard settings.resumeLastWallpaper else { return nil }
        
        let scalingRaw = userDefaults.string(forKey: Keys.scalingMode) ?? ScalingMode.fill.rawValue
        let scalingMode = ScalingMode(rawValue: scalingRaw) ?? .fill
        let isMuted = userDefaults.bool(forKey: Keys.isMuted)
        let isStatic = userDefaults.bool(forKey: Keys.isStatic)
        let name = userDefaults.string(forKey: Keys.lastWallpaperName) ?? "Wallpaper"
        
        if let bookmarkData = userDefaults.data(forKey: Keys.lastWallpaperBookmark) {
            var isStale = false
            do {
                let resolvedURL = try URL(
                    resolvingBookmarkData: bookmarkData,
                    options: .withSecurityScope,
                    relativeTo: nil,
                    bookmarkDataIsStale: &isStale
                )
                
                if isStale {
                    print("[PreferenceStore] Bookmark is stale.")
                }
                
                if resolvedURL.startAccessingSecurityScopedResource() {
                    return Wallpaper(
                        name: name,
                        fileURL: resolvedURL,
                        scalingMode: scalingMode,
                        isMuted: isMuted,
                        isStatic: isStatic,
                        bookmarkData: bookmarkData
                    )
                } else {
                    if FileManager.default.fileExists(atPath: resolvedURL.path) {
                        return Wallpaper(
                            name: name,
                            fileURL: resolvedURL,
                            scalingMode: scalingMode,
                            isMuted: isMuted,
                            isStatic: isStatic
                        )
                    }
                }
            } catch {
                print("[PreferenceStore] Error resolving bookmark: \(error.localizedDescription)")
            }
        }
        
        if let path = userDefaults.string(forKey: Keys.lastWallpaperURL) {
            let url = URL(fileURLWithPath: path)
            if FileManager.default.fileExists(atPath: url.path) {
                return Wallpaper(
                    name: url.lastPathComponent,
                    fileURL: url,
                    scalingMode: scalingMode,
                    isMuted: isMuted,
                    isStatic: isStatic
                )
            }
        }
        
        return nil
    }
    
    public func clearLastWallpaper() {
        userDefaults.removeObject(forKey: Keys.lastWallpaperBookmark)
        userDefaults.removeObject(forKey: Keys.lastWallpaperName)
        userDefaults.removeObject(forKey: Keys.lastWallpaperURL)
        userDefaults.removeObject(forKey: Keys.scalingMode)
        userDefaults.removeObject(forKey: Keys.isMuted)
        userDefaults.removeObject(forKey: Keys.isStatic)
    }
}
