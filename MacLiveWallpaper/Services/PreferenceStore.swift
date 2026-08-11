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
        static let playlistBookmarks = "playlistBookmarks"
        static let playlistNames = "playlistNames"
        static let playbackOrder = "playbackOrder"
        static let switchInterval = "switchInterval"
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
    
    // MARK: - Playlist & Storage
    
    public func savePlaylist(_ playlist: [Wallpaper]) {
        var bookmarks: [Data] = []
        var names: [String] = []
        
        for item in playlist {
            names.append(item.name)
            let url = item.fileURL
            if let bData = try? url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil) {
                bookmarks.append(bData)
            } else {
                if let pathData = url.path.data(using: .utf8) {
                    bookmarks.append(pathData)
                }
            }
        }
        
        userDefaults.set(bookmarks, forKey: Keys.playlistBookmarks)
        userDefaults.set(names, forKey: Keys.playlistNames)
    }
    
    public func loadPlaylist() -> [Wallpaper] {
        guard let bookmarks = userDefaults.array(forKey: Keys.playlistBookmarks) as? [Data],
              let names = userDefaults.array(forKey: Keys.playlistNames) as? [String],
              bookmarks.count == names.count else {
            return []
        }
        
        var result: [Wallpaper] = []
        for (i, bData) in bookmarks.enumerated() {
            var isStale = false
            if let url = try? URL(resolvingBookmarkData: bData, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale) {
                _ = url.startAccessingSecurityScopedResource()
                result.append(Wallpaper(name: names[i], fileURL: url, bookmarkData: bData))
            } else if let path = String(data: bData, encoding: .utf8) {
                let url = URL(fileURLWithPath: path)
                if FileManager.default.fileExists(atPath: url.path) {
                    result.append(Wallpaper(name: names[i], fileURL: url))
                }
            }
        }
        return result
    }
    
    public func savePlaybackOptions(order: PlaybackOrder, interval: SwitchInterval) {
        userDefaults.set(order.rawValue, forKey: Keys.playbackOrder)
        userDefaults.set(interval.rawValue, forKey: Keys.switchInterval)
    }
    
    public func loadPlaybackOrder() -> PlaybackOrder {
        let raw = userDefaults.string(forKey: Keys.playbackOrder) ?? PlaybackOrder.sequential.rawValue
        return PlaybackOrder(rawValue: raw) ?? .sequential
    }
    
    public func loadSwitchInterval() -> SwitchInterval {
        let raw = userDefaults.string(forKey: Keys.switchInterval) ?? SwitchInterval.onEnd.rawValue
        return SwitchInterval(rawValue: raw) ?? .onEnd
    }
    
    // MARK: - Bookmark & Last Wallpaper Storage
    
    public func saveLastWallpaper(_ wallpaper: Wallpaper) {
        userDefaults.set(wallpaper.name, forKey: Keys.lastWallpaperName)
        userDefaults.set(wallpaper.scalingMode.rawValue, forKey: Keys.scalingMode)
        userDefaults.set(wallpaper.isMuted, forKey: Keys.isMuted)
        userDefaults.set(wallpaper.isStatic, forKey: Keys.isStatic)
        
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
        userDefaults.removeObject(forKey: Keys.playlistBookmarks)
        userDefaults.removeObject(forKey: Keys.playlistNames)
    }
}
