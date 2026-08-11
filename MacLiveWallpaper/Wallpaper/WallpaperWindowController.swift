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
            playerLayer: playerLayer,
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
            playerLayer: nil,
            scalingMode: scalingMode
        )
        
        performCrossDissolve(to: newWrapper, animated: animated)
    }
    
    private func performCrossDissolve(to newWrapper: MediaLayerWrapper, animated: Bool) {
        guard let mainLayer = self.layer else { return }
        
        newWrapper.layer.frame = self.bounds
        newWrapper.layer.opacity = 0.0
        mainLayer.addSublayer(newWrapper.layer)
        
        let oldWrapper = self.currentWrapper
        self.currentWrapper = newWrapper
        
        guard animated && oldWrapper != nil else {
            oldWrapper?.cleanup()
            newWrapper.layer.opacity = 1.0
            return
        }
        
        let startAnimationBlock = { [weak self, weak oldWrapper, weak newWrapper] in
            guard let self = self, let old = oldWrapper, let new = newWrapper else { return }
            
            let duration: CFTimeInterval = 1.0 // 1초간 완벽하게 은은한 크로스 페이드 디졸브
            
            // New Layer Fade In
            let fadeIn = CABasicAnimation(keyPath: "opacity")
            fadeIn.fromValue = 0.0
            fadeIn.toValue = 1.0
            fadeIn.duration = duration
            fadeIn.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            fadeIn.fillMode = .forwards
            fadeIn.isRemovedOnCompletion = false
            
            // Old Layer Fade Out
            let fadeOut = CABasicAnimation(keyPath: "opacity")
            fadeOut.fromValue = 1.0
            fadeOut.toValue = 0.0
            fadeOut.duration = duration
            fadeOut.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            fadeOut.fillMode = .forwards
            fadeOut.isRemovedOnCompletion = false
            
            CATransaction.begin()
            CATransaction.setCompletionBlock {
                old.cleanup()
                new.layer.removeAllAnimations()
                new.layer.opacity = 1.0
            }
            
            new.layer.add(fadeIn, forKey: "fadeIn")
            old.layer.add(fadeOut, forKey: "fadeOut")
            
            CATransaction.commit()
        }
        
        // 비디오 레이어인 경우 렌더링 준비(readyForDisplay)가 끝난 순간 페이드 시작!
        if let playerLayer = newWrapper.playerLayer {
            if playerLayer.isReadyForDisplay {
                startAnimationBlock()
            } else {
                newWrapper.onReadyForDisplay = {
                    DispatchQueue.main.async {
                        startAnimationBlock()
                    }
                }
            }
        } else {
            // 이미지인 경우 즉시 페이드 시작
            startAnimationBlock()
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
final class MediaLayerWrapper: NSObject {
    let layer: CALayer
    let player: AVQueuePlayer?
    let looper: AVPlayerLooper?
    let playerLayer: AVPlayerLayer?
    var scalingMode: ScalingMode
    var onReadyForDisplay: (() -> Void)?
    private var observation: NSKeyValueObservation?
    
    init(layer: CALayer, player: AVQueuePlayer?, looper: AVPlayerLooper?, playerLayer: AVPlayerLayer?, scalingMode: ScalingMode) {
        self.layer = layer
        self.player = player
        self.looper = looper
        self.playerLayer = playerLayer
        self.scalingMode = scalingMode
        super.init()
        
        if let pl = playerLayer {
            observation = pl.observe(\.isReadyForDisplay, options: [.new]) { [weak self] pl, _ in
                if pl.isReadyForDisplay {
                    self?.onReadyForDisplay?()
                    self?.onReadyForDisplay = nil
                }
            }
        }
    }
    
    func updateScalingMode(_ mode: ScalingMode) {
        self.scalingMode = mode
        if let playerLayer = layer as? AVPlayerLayer {
            playerLayer.videoGravity = (mode == .fill) ? .resizeAspectFill : .resizeAspect
        } else {
            layer.contentsGravity = (mode == .fill) ? .resizeAspectFill : .resizeAspect
        }
    }
    
    func cleanup() {
        observation?.invalidate()
        observation = nil
        onReadyForDisplay = nil
        player?.pause()
        player?.removeAllItems()
        layer.removeFromSuperlayer()
    }
}
