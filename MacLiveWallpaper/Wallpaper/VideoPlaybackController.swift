import AppKit
import AVFoundation

public final class VideoPlaybackController {
    public let player: AVQueuePlayer
    public let playerLayer: AVPlayerLayer
    
    // CRITICAL: AVPlayerLooper must be stored as a strong reference to prevent deallocation!
    private var playerLooper: AVPlayerLooper?
    private var currentItem: AVPlayerItem?
    private var activeURL: URL?
    public private(set) var isStaticMode: Bool = false
    
    public init() {
        self.player = AVQueuePlayer()
        self.playerLayer = AVPlayerLayer(player: player)
        self.playerLayer.videoGravity = .resizeAspectFill
        self.player.isMuted = true
    }
    
    public func loadVideo(url: URL, scalingMode: ScalingMode = .fill, isMuted: Bool = true, isStatic: Bool = false) {
        player.pause()
        player.removeAllItems()
        playerLooper = nil
        
        _ = url.startAccessingSecurityScopedResource()
        self.activeURL = url
        self.isStaticMode = isStatic
        
        let asset = AVURLAsset(url: url)
        let item = AVPlayerItem(asset: asset)
        self.currentItem = item
        
        // Setup AVPlayerLooper for seamless repeating playback
        self.playerLooper = AVPlayerLooper(player: player, templateItem: item)
        
        setScalingMode(scalingMode)
        setMuted(isMuted)
        
        if isStatic {
            player.pause()
        } else {
            player.play()
        }
    }
    
    public func setScalingMode(_ mode: ScalingMode) {
        switch mode {
        case .fill:
            playerLayer.videoGravity = .resizeAspectFill
        case .fit:
            playerLayer.videoGravity = .resizeAspect
        }
    }
    
    public func setMuted(_ isMuted: Bool) {
        player.isMuted = isMuted
    }
    
    public func setStatic(_ isStatic: Bool) {
        self.isStaticMode = isStatic
        if isStatic {
            player.pause()
        } else {
            player.play()
        }
    }
    
    public func play() {
        if !isStaticMode {
            player.play()
        }
    }
    
    public func pause() {
        player.pause()
    }
    
    public func stop() {
        player.pause()
        player.removeAllItems()
        playerLooper = nil
        currentItem = nil
    }
    
    public var isPlaying: Bool {
        return player.timeControlStatus == .playing
    }
}
