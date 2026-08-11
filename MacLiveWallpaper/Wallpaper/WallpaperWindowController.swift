import AppKit
import AVFoundation

public final class WallpaperWindowController {
    public let screen: NSScreen
    public let window: NSWindow
    public let playbackController: VideoPlaybackController
    
    private var containerView: WallpaperContainerView
    
    public init(screen: NSScreen) {
        self.screen = screen
        self.playbackController = VideoPlaybackController()
        
        let contentRect = screen.frame
        self.window = NSWindow(
            contentRect: contentRect,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false,
            screen: screen
        )
        
        self.containerView = WallpaperContainerView(playerLayer: playbackController.playerLayer)
        
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
    
    public func showImage(url: URL, scalingMode: ScalingMode) {
        playbackController.stop()
        containerView.setImage(url: url, scalingMode: scalingMode)
    }
    
    public func showVideo(url: URL, scalingMode: ScalingMode, isMuted: Bool, isStatic: Bool) {
        containerView.clearImage()
        playbackController.loadVideo(url: url, scalingMode: scalingMode, isMuted: isMuted, isStatic: isStatic)
    }
    
    public func updateScalingMode(_ mode: ScalingMode) {
        playbackController.setScalingMode(mode)
        containerView.updateImageScalingMode(mode)
    }
    
    public func updateScreen(_ newScreen: NSScreen) {
        window.setFrame(newScreen.frame, display: true)
        containerView.frame = NSRect(origin: .zero, size: newScreen.frame.size)
    }
    
    public func close() {
        playbackController.stop()
        containerView.clearImage()
        window.orderOut(nil)
        window.close()
    }
}

// CALayer를 호스팅하는 NSView 서브클래스
final class WallpaperContainerView: NSView {
    private let playerLayer: AVPlayerLayer
    private let imageLayer: CALayer = CALayer()
    
    init(playerLayer: AVPlayerLayer) {
        self.playerLayer = playerLayer
        super.init(frame: .zero)
        
        self.wantsLayer = true
        guard let layer = self.layer else { return }
        layer.backgroundColor = NSColor.black.cgColor
        layer.addSublayer(playerLayer)
        layer.addSublayer(imageLayer)
        
        imageLayer.isHidden = true
        imageLayer.contentsGravity = .resizeAspectFill
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func setImage(url: URL, scalingMode: ScalingMode) {
        _ = url.startAccessingSecurityScopedResource()
        if let image = NSImage(contentsOf: url) {
            imageLayer.contents = image
            updateImageScalingMode(scalingMode)
            imageLayer.isHidden = false
            playerLayer.isHidden = true
        }
    }
    
    public func clearImage() {
        imageLayer.contents = nil
        imageLayer.isHidden = true
        playerLayer.isHidden = false
    }
    
    public func updateImageScalingMode(_ scalingMode: ScalingMode) {
        switch scalingMode {
        case .fill:
            imageLayer.contentsGravity = .resizeAspectFill
        case .fit:
            imageLayer.contentsGravity = .resizeAspect
        }
    }
    
    override func layout() {
        super.layout()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        playerLayer.frame = self.bounds
        imageLayer.frame = self.bounds
        CATransaction.commit()
    }
}
