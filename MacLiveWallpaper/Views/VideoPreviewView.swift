import SwiftUI
import AVKit
import AVFoundation

struct MediaPreviewView: View {
    let url: URL
    let scalingMode: ScalingMode
    let isMuted: Bool
    
    private var isImage: Bool {
        return Wallpaper.detectMediaKind(for: url) == .image
    }
    
    var body: some View {
        if isImage {
            ImagePreviewView(url: url, scalingMode: scalingMode)
        } else {
            VideoPreviewView(url: url, scalingMode: scalingMode, isMuted: isMuted)
        }
    }
}

struct ImagePreviewView: View {
    let url: URL
    let scalingMode: ScalingMode
    @State private var nsImage: NSImage?
    
    var body: some View {
        GeometryReader { geo in
            if let image = nsImage {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: scalingMode == .fill ? .fill : .fit)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
            } else {
                Color.black
                    .onAppear {
                        loadImage()
                    }
            }
        }
        .onChange(of: url) { _ in
            loadImage()
        }
    }
    
    private func loadImage() {
        _ = url.startAccessingSecurityScopedResource()
        if let loaded = NSImage(contentsOf: url) {
            self.nsImage = loaded
        }
    }
}

struct VideoPreviewView: NSViewRepresentable {
    let url: URL
    let scalingMode: ScalingMode
    let isMuted: Bool
    
    class Coordinator {
        var player: AVQueuePlayer?
        var playerLooper: AVPlayerLooper?
        var currentURL: URL?
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator()
    }
    
    func makeNSView(context: Context) -> AVPlayerView {
        let playerView = AVPlayerView()
        playerView.controlsStyle = .inline
        playerView.showsFrameSteppingButtons = false
        playerView.showsSharingServiceButton = false
        playerView.showsFullScreenToggleButton = false
        playerView.videoGravity = (scalingMode == .fill) ? .resizeAspectFill : .resizeAspect
        
        let player = AVQueuePlayer()
        player.isMuted = isMuted
        playerView.player = player
        
        context.coordinator.player = player
        
        setupPlayback(url: url, coordinator: context.coordinator, playerView: playerView)
        
        return playerView
    }
    
    func updateNSView(_ nsView: AVPlayerView, context: Context) {
        nsView.videoGravity = (scalingMode == .fill) ? .resizeAspectFill : .resizeAspect
        nsView.player?.isMuted = isMuted
        
        if context.coordinator.currentURL != url {
            setupPlayback(url: url, coordinator: context.coordinator, playerView: nsView)
        }
    }
    
    private func setupPlayback(url: URL, coordinator: Coordinator, playerView: AVPlayerView) {
        guard let player = coordinator.player else { return }
        
        _ = url.startAccessingSecurityScopedResource()
        
        player.pause()
        player.removeAllItems()
        coordinator.playerLooper = nil
        
        let asset = AVURLAsset(url: url)
        let item = AVPlayerItem(asset: asset)
        
        coordinator.playerLooper = AVPlayerLooper(player: player, templateItem: item)
        coordinator.currentURL = url
        
        player.play()
    }
}
