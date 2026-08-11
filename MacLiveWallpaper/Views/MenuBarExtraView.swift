import SwiftUI

struct MenuBarExtraView: View {
    @ObservedObject var wallpaperManager = WallpaperManager.shared
    let openMainWindowAction: () -> Void
    let openSettingsAction: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Status Header
            HStack {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                
                Text(statusText)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 8)
            .padding(.top, 4)
            
            if let wallpaper = wallpaperManager.currentWallpaper {
                Text(wallpaper.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .padding(.horizontal, 8)
            } else {
                Text("No Wallpaper Set")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
            }
            
            Divider()
            
            if wallpaperManager.currentWallpaper != nil {
                if let wp = wallpaperManager.currentWallpaper, !wp.isStatic && wp.mediaKind == .video {
                    Button(action: {
                        wallpaperManager.togglePlayPause()
                    }) {
                        Label(
                            wallpaperManager.isPlaying ? "Pause Wallpaper" : "Resume Wallpaper",
                            systemImage: wallpaperManager.isPlaying ? "pause.fill" : "play.fill"
                        )
                    }
                }
                
                if wallpaperManager.playlist.count > 1 {
                    Button(action: {
                        wallpaperManager.playNextWallpaper()
                    }) {
                        Label("Next Wallpaper", systemImage: "forward.fill")
                    }
                }
                
                Button(action: {
                    wallpaperManager.removeWallpaper()
                }) {
                    Label("Remove Wallpaper", systemImage: "trash")
                }
            }
            
            // Open App
            Button(action: openMainWindowAction) {
                Label("Open Mac Live Wallpaper", systemImage: "macwindow")
            }
            
            // Open Settings
            Button(action: openSettingsAction) {
                Label("Settings...", systemImage: "gearshape")
            }
            
            Divider()
            
            // Quit
            Button(action: {
                NSApplication.shared.terminate(nil)
            }) {
                Label("Quit App", systemImage: "power")
            }
        }
        .padding(4)
    }
    
    private var statusColor: Color {
        guard let wallpaper = wallpaperManager.currentWallpaper else { return .gray }
        if wallpaper.mediaKind == .image || wallpaper.isStatic { return .blue }
        return wallpaperManager.isPlaying ? .green : .orange
    }
    
    private var statusText: String {
        guard let wallpaper = wallpaperManager.currentWallpaper else { return "No Wallpaper Set" }
        if wallpaper.mediaKind == .image { return "Image Wallpaper Active" }
        if wallpaper.isStatic { return "Static Video Frame Active" }
        return wallpaperManager.isPlaying ? "Live Wallpaper Playing" : "Wallpaper Paused"
    }
}
