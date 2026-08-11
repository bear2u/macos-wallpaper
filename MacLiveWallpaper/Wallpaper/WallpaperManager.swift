import AppKit
import Combine
import AVFoundation

public final class WallpaperManager: ObservableObject {
    public static let shared = WallpaperManager()
    
    @Published public private(set) var currentWallpaper: Wallpaper?
    @Published public private(set) var isPlaying: Bool = false
    @Published public private(set) var playlist: [Wallpaper] = []
    @Published public var playbackOrder: PlaybackOrder = .sequential {
        didSet {
            PreferenceStore.shared.savePlaybackOptions(order: playbackOrder, interval: switchInterval)
        }
    }
    @Published public var switchInterval: SwitchInterval = .onEnd {
        didSet {
            PreferenceStore.shared.savePlaybackOptions(order: playbackOrder, interval: switchInterval)
            restartSwitchTimer()
        }
    }
    @Published public private(set) var currentIndex: Int = 0
    
    private var windowControllers: [WallpaperWindowController] = []
    private var cancellables = Set<AnyCancellable>()
    private var switchTimer: Timer?
    private var lastSwitchTime: Date = Date.distantPast
    
    private init() {
        self.playbackOrder = PreferenceStore.shared.loadPlaybackOrder()
        self.switchInterval = PreferenceStore.shared.loadSwitchInterval()
        self.playlist = PreferenceStore.shared.loadPlaylist()
        
        setupObservers()
    }
    
    private func setupObservers() {
        ScreenManager.shared.onScreenConfigurationChanged = { [weak self] screens in
            self?.rebuildDisplays(screens: screens)
        }
        
        PowerStateObserver.shared.onSleep = { [weak self] in
            guard PreferenceStore.shared.settings.pauseOnSleep else { return }
            self?.pause()
        }
        
        PowerStateObserver.shared.onWake = { [weak self] in
            guard PreferenceStore.shared.settings.pauseOnSleep else { return }
            self?.resume()
        }
        
        // 영상 1회 재생 종료 시 다음 비디오로 넘김 (switchInterval == .onEnd 일 때)
        NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime)
            .sink { [weak self] _ in
                guard let self = self else { return }
                guard self.playlist.count > 1 && self.switchInterval == .onEnd else { return }
                
                // 최소 1초 디바운스 가드로 중복 넘김 방지
                let now = Date()
                if now.timeIntervalSince(self.lastSwitchTime) > 1.0 {
                    self.lastSwitchTime = now
                    DispatchQueue.main.async {
                        self.playNextWallpaper()
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Playlist Operations
    
    public func setPlaylist(_ list: [Wallpaper]) {
        self.playlist = list
        PreferenceStore.shared.savePlaylist(list)
        
        if list.isEmpty {
            removeWallpaper()
            return
        }
        
        if currentWallpaper == nil, let first = list.first {
            self.currentIndex = 0
            setWallpaper(first)
        } else if let current = currentWallpaper, let idx = list.firstIndex(where: { $0.fileURL.path == current.fileURL.path }) {
            self.currentIndex = idx
        } else if let first = list.first {
            self.currentIndex = 0
            setWallpaper(first)
        }
        restartSwitchTimer()
    }
    
    public func addToPlaylist(urls: [URL]) {
        var updated = playlist
        var addedAny = false
        
        for url in urls {
            let wp = Wallpaper(name: url.lastPathComponent, fileURL: url)
            if !updated.contains(where: { $0.fileURL.path == url.path }) {
                updated.append(wp)
                addedAny = true
            }
        }
        
        if addedAny {
            self.playlist = updated
            PreferenceStore.shared.savePlaylist(updated)
            
            if currentWallpaper == nil, let first = updated.first {
                self.currentIndex = 0
                setWallpaper(first)
            } else if let current = currentWallpaper, let idx = updated.firstIndex(where: { $0.fileURL.path == current.fileURL.path }) {
                self.currentIndex = idx
            }
            
            restartSwitchTimer()
        }
    }
    
    public func removeFromPlaylist(id: UUID) {
        var updated = playlist
        updated.removeAll(where: { $0.id == id })
        setPlaylist(updated)
    }
    
    public func clearPlaylist() {
        switchTimer?.invalidate()
        switchTimer = nil
        playlist.removeAll()
        removeWallpaper()
    }
    
    public func playNextWallpaper() {
        guard !playlist.isEmpty else { return }
        
        let nextIndex: Int
        if playlist.count == 1 {
            nextIndex = 0
        } else if playbackOrder == .random {
            var rand = Int.random(in: 0..<playlist.count)
            if rand == currentIndex {
                rand = (currentIndex + 1) % playlist.count
            }
            nextIndex = rand
        } else {
            nextIndex = (currentIndex + 1) % playlist.count
        }
        
        self.currentIndex = nextIndex
        let targetWallpaper = playlist[nextIndex]
        applyWallpaperInternal(targetWallpaper, animated: true)
    }
    
    public func playPreviousWallpaper() {
        guard !playlist.isEmpty else { return }
        
        let prevIndex: Int
        if playlist.count == 1 {
            prevIndex = 0
        } else if playbackOrder == .random {
            prevIndex = Int.random(in: 0..<playlist.count)
        } else {
            prevIndex = (currentIndex - 1 + playlist.count) % playlist.count
        }
        
        self.currentIndex = prevIndex
        let targetWallpaper = playlist[prevIndex]
        applyWallpaperInternal(targetWallpaper, animated: true)
    }
    
    private func restartSwitchTimer() {
        switchTimer?.invalidate()
        switchTimer = nil
        
        guard playlist.count > 1 else { return }
        
        if let seconds = switchInterval.timeIntervalSeconds {
            switchTimer = Timer.scheduledTimer(withTimeInterval: seconds, repeats: true) { [weak self] _ in
                self?.playNextWallpaper()
            }
        }
    }
    
    // MARK: - Single Wallpaper Control
    
    public func setWallpaper(_ wallpaper: Wallpaper) {
        if !playlist.contains(where: { $0.fileURL.path == wallpaper.fileURL.path }) {
            self.playlist.append(wallpaper)
            PreferenceStore.shared.savePlaylist(playlist)
        }
        
        if let idx = playlist.firstIndex(where: { $0.fileURL.path == wallpaper.fileURL.path }) {
            self.currentIndex = idx
        }
        
        applyWallpaperInternal(wallpaper, animated: true)
        restartSwitchTimer()
    }
    
    private func applyWallpaperInternal(_ wallpaper: Wallpaper, animated: Bool) {
        self.currentWallpaper = wallpaper
        PreferenceStore.shared.saveLastWallpaper(wallpaper)
        refreshDisplays(animated: animated)
    }
    
    public func removeWallpaper() {
        switchTimer?.invalidate()
        switchTimer = nil
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
        
        refreshDisplays(animated: false)
    }
    
    public func updateIsStatic(_ isStatic: Bool) {
        guard var wallpaper = currentWallpaper, wallpaper.mediaKind == .video else { return }
        wallpaper.isStatic = isStatic
        self.currentWallpaper = wallpaper
        PreferenceStore.shared.saveLastWallpaper(wallpaper)
        
        refreshDisplays(animated: false)
        isPlaying = !isStatic
    }
    
    public func pause() {
        guard let wallpaper = currentWallpaper, wallpaper.mediaKind == .video else { return }
        isPlaying = false
    }
    
    public func resume() {
        guard let wallpaper = currentWallpaper, wallpaper.mediaKind == .video, !wallpaper.isStatic else { return }
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
    
    public func refreshDisplays(animated: Bool = true) {
        let screens = NSScreen.screens
        guard let wallpaper = currentWallpaper else { return }
        
        if windowControllers.count != screens.count {
            rebuildDisplays(screens: screens)
            return
        }
        
        for wc in windowControllers {
            if wallpaper.mediaKind == .image {
                wc.showImage(url: wallpaper.fileURL, scalingMode: wallpaper.scalingMode, animated: animated)
            } else {
                wc.showVideo(
                    url: wallpaper.fileURL,
                    scalingMode: wallpaper.scalingMode,
                    isMuted: wallpaper.isMuted,
                    isStatic: wallpaper.isStatic,
                    animated: animated
                )
            }
        }
        
        isPlaying = (wallpaper.mediaKind == .video) && !wallpaper.isStatic
    }
    
    private func rebuildDisplays(screens: [NSScreen]) {
        for wc in windowControllers {
            wc.close()
        }
        windowControllers.removeAll()
        
        guard let wallpaper = currentWallpaper else { return }
        
        for screen in screens {
            let wc = WallpaperWindowController(screen: screen)
            if wallpaper.mediaKind == .image {
                wc.showImage(url: wallpaper.fileURL, scalingMode: wallpaper.scalingMode, animated: false)
            } else {
                wc.showVideo(
                    url: wallpaper.fileURL,
                    scalingMode: wallpaper.scalingMode,
                    isMuted: wallpaper.isMuted,
                    isStatic: wallpaper.isStatic,
                    animated: false
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
