import AppKit
import Combine

public final class WallpaperManager: ObservableObject {
    public static let shared = WallpaperManager()
    
    @Published public private(set) var currentWallpaper: Wallpaper?
    @Published public private(set) var isPlaying: Bool = false
    
    private var windowControllers: [WallpaperWindowController] = []
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupObservers()
    }
    
    private func setupObservers() {
        // Screen config changes
        ScreenManager.shared.onScreenConfigurationChanged = { [weak self] screens in
            self?.refreshDisplays(screens: screens)
        }
        
        // Power state changes (Sleep / Wake)
        PowerStateObserver.shared.onSleep = { [weak self] in
            guard PreferenceStore.shared.settings.pauseOnSleep else { return }
            self?.pause()
        }
        
        PowerStateObserver.shared.onWake = { [weak self] in
            guard PreferenceStore.shared.settings.pauseOnSleep else { return }
            self?.resume()
        }
    }
    
    public func setWallpaper(_ wallpaper: Wallpaper) {
        self.currentWallpaper = wallpaper
        PreferenceStore.shared.saveLastWallpaper(wallpaper)
        
        let screens = NSScreen.screens
        refreshDisplays(screens: screens)
    }
    
    public func removeWallpaper() {
        stop()
        PreferenceStore.shared.clearLastWallpaper()
    }
    
    public func updateScalingMode(_ mode: ScalingMode) {
        guard var wallpaper = currentWallpaper else { return }
        wallpaper.scalingMode = mode
        self.currentWallpaper = wallpaper
        PreferenceStore.shared.saveLastWallpaper(wallpaper)
        
        for wc in windowControllers {
            wc.updateScalingMode(mode)
        }
    }
    
    public func updateMuted(_ isMuted: Bool) {
        guard var wallpaper = currentWallpaper, wallpaper.mediaKind == .video else { return }
        wallpaper.isMuted = isMuted
        self.currentWallpaper = wallpaper
        PreferenceStore.shared.saveLastWallpaper(wallpaper)
        
        for wc in windowControllers {
            wc.playbackController.setMuted(isMuted)
        }
    }
    
    public func updateIsStatic(_ isStatic: Bool) {
        guard var wallpaper = currentWallpaper, wallpaper.mediaKind == .video else { return }
        wallpaper.isStatic = isStatic
        self.currentWallpaper = wallpaper
        PreferenceStore.shared.saveLastWallpaper(wallpaper)
        
        for wc in windowControllers {
            wc.playbackController.setStatic(isStatic)
        }
        isPlaying = !isStatic
    }
    
    public func pause() {
        guard let wallpaper = currentWallpaper, wallpaper.mediaKind == .video else { return }
        for wc in windowControllers {
            wc.playbackController.pause()
        }
        isPlaying = false
    }
    
    public func resume() {
        guard let wallpaper = currentWallpaper, wallpaper.mediaKind == .video, !wallpaper.isStatic else { return }
        for wc in windowControllers {
            wc.playbackController.play()
        }
        isPlaying = true
    }
    
    public func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            resume()
        }
    }
    
    public func stop() {
        for wc in windowControllers {
            wc.close()
        }
        windowControllers.removeAll()
        currentWallpaper = nil
        isPlaying = false
    }
    
    public func refreshDisplays(screens: [NSScreen] = NSScreen.screens) {
        for wc in windowControllers {
            wc.close()
        }
        windowControllers.removeAll()
        
        guard let wallpaper = currentWallpaper else { return }
        
        for screen in screens {
            let wc = WallpaperWindowController(screen: screen)
            if wallpaper.mediaKind == .image {
                wc.showImage(url: wallpaper.fileURL, scalingMode: wallpaper.scalingMode)
            } else {
                wc.showVideo(
                    url: wallpaper.fileURL,
                    scalingMode: wallpaper.scalingMode,
                    isMuted: wallpaper.isMuted,
                    isStatic: wallpaper.isStatic
                )
            }
            windowControllers.append(wc)
        }
        
        isPlaying = (wallpaper.mediaKind == .video) && !wallpaper.isStatic
    }
    
    public func loadSavedWallpaper() {
        if let saved = PreferenceStore.shared.loadLastWallpaper() {
            setWallpaper(saved)
        }
    }
}
