import AppKit
import AVFoundation

public final class WallpaperWindowController {
    public let screen: NSScreen
    public let window: NSWindow
    
    private var containerView: WallpaperContainerView
    
    public init(screen: NSScreen) {
        self.screen = screen
        
        let contentRect = screen.frame
        self.window = NSWindow(
            contentRect: contentRect,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false,
            screen: screen
        )
        
        self.containerView = WallpaperContainerView()
        
        setupWindowProperties()
    }
    
    private func setupWindowProperties() {
        window.contentView = containerView
        window.setFrame(screen.frame, display: true)
        
        let desktopLevel = Int(CGWindowLevelForKey(.desktopWindow))
        window.level = NSWindow.Level(rawValue: desktopLevel)
        
        window.collectionBehavior = [
            .canJoinAllSpaces,
            .stationary,
            .ignoresCycle
        ]
        
        window.ignoresMouseEvents = true
        window.hasShadow = false
        window.isOpaque = true
        window.backgroundColor = .black
        window.isReleasedWhenClosed = false
        
        window.orderFront(nil)
    }
    
    public func showImage(url: URL, scalingMode: ScalingMode, animated: Bool = true) {
        containerView.transitionToImage(url: url, scalingMode: scalingMode, animated: animated)
    }
    
    public func showVideo(url: URL, scalingMode: ScalingMode, isMuted: Bool, isStatic: Bool, animated: Bool = true) {
        containerView.transitionToVideo(url: url, scalingMode: scalingMode, isMuted: isMuted, isStatic: isStatic, animated: animated)
    }
    
    public func updateScalingMode(_ mode: ScalingMode) {
        containerView.updateScalingMode(mode)
    }
    
    public func updateScreen(_ newScreen: NSScreen) {
        window.setFrame(newScreen.frame, display: true)
        containerView.frame = NSRect(origin: .zero, size: newScreen.frame.size)
    }
    
    public func close() {
        containerView.clearAll()
        window.orderOut(nil)
        window.close()
    }
}

// MARK: - Dual-Layer Cross-Dissolve Wallpaper Container View
final class WallpaperContainerView: NSView {
    private var currentWrapper: MediaLayerWrapper?
    private var isTransitioning = false
    
    override init(frame: NSRect) {
        super.init(frame: frame)
        self.wantsLayer = true
        self.layer?.backgroundColor = NSColor.black.cgColor
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func transitionToVideo(url: URL, scalingMode: ScalingMode, isMuted: Bool, isStatic: Bool, animated: Bool) {
        _ = url.startAccessingSecurityScopedResource()
        
        let player = AVQueuePlayer()
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = (scalingMode == .fill) ? .resizeAspectFill : .resizeAspect
        player.isMuted = isMuted
        
        let item = AVPlayerItem(url: url)
        let looper = AVPlayerLooper(player: player, templateItem: item)
        
        if !isStatic {
            player.play()
        }
        
        let newWrapper = MediaLayerWrapper(
            layer: playerLayer,
            player: player,
            looper: looper,
            scalingMode: scalingMode
        )
        
        performCrossDissolve(to: newWrapper, animated: animated)
    }
    
    public func transitionToImage(url: URL, scalingMode: ScalingMode, animated: Bool) {
        _ = url.startAccessingSecurityScopedResource()
        
        let imageLayer = CALayer()
        imageLayer.contentsGravity = (scalingMode == .fill) ? .resizeAspectFill : .resizeAspect
        
        if let image = NSImage(contentsOf: url) {
            imageLayer.contents = image
        }
        
        let newWrapper = MediaLayerWrapper(
            layer: imageLayer,
            player: nil,
            looper: nil,
            scalingMode: scalingMode
        )
        
        performCrossDissolve(to: newWrapper, animated: animated)
    }
    
    private func performCrossDissolve(to newWrapper: MediaLayerWrapper, animated: Bool) {
        guard let mainLayer = self.layer else { return }
        
        newWrapper.layer.frame = self.bounds
        newWrapper.layer.opacity = animated ? 0.0 : 1.0
        mainLayer.addSublayer(newWrapper.layer)
        
        let oldWrapper = self.currentWrapper
        self.currentWrapper = newWrapper
        
        if animated && oldWrapper != nil {
            CATransaction.begin()
            CATransaction.setAnimationDuration(0.8) // 0.8초간 부드럽고 매끄러운 크로스 디졸브 페이드
            CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: .easeInEaseOut))
            
            CATransaction.setCompletionBlock {
                oldWrapper?.cleanup()
            }
            
            newWrapper.layer.opacity = 1.0
            oldWrapper?.layer.opacity = 0.0
            
            CATransaction.commit()
        } else {
            oldWrapper?.cleanup()
            newWrapper.layer.opacity = 1.0
        }
    }
    
    public func updateScalingMode(_ mode: ScalingMode) {
        currentWrapper?.updateScalingMode(mode)
    }
    
    public func clearAll() {
        currentWrapper?.cleanup()
        currentWrapper = nil
    }
    
    override func layout() {
        super.layout()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        currentWrapper?.layer.frame = self.bounds
        CATransaction.commit()
    }
}

// 미디어 레이어 및 캡슐화 래퍼
final class MediaLayerWrapper {
    let layer: CALayer
    let player: AVQueuePlayer?
    let looper: AVPlayerLooper?
    var scalingMode: ScalingMode
    
    init(layer: CALayer, player: AVQueuePlayer?, looper: AVPlayerLooper?, scalingMode: ScalingMode) {
        self.layer = layer
        self.player = player
        self.looper = looper
        self.scalingMode = scalingMode
    }
    
    func updateScalingMode(_ mode: ScalingMode) {
        self.scalingMode = mode
        let gravity: CALayerContentsGravity = (mode == .fill) ? .resizeAspectFill : .resizeAspect
        if let playerLayer = layer as? AVPlayerLayer {
            playerLayer.videoGravity = (mode == .fill) ? .resizeAspectFill : .resizeAspect
        } else {
            layer.contentsGravity = gravity
        }
    }
    
    func cleanup() {
        player?.pause()
        player?.removeAllItems()
        layer.removeFromSuperlayer()
    }
}
