import SwiftUI

struct MainView: View {
    @ObservedObject var wallpaperManager = WallpaperManager.shared
    
    @State private var selectedURL: URL?
    @State private var metadata: VideoMetadata?
    @State private var scalingMode: ScalingMode = .fill
    @State private var isMuted: Bool = true
    @State private var isStatic: Bool = false
    @State private var showSettings: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "film.fill")
                        .foregroundColor(.blue)
                    Text("Mac Live Wallpaper")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                }
                
                Spacer()
                
                Button(action: { showSettings = true }) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .sheet(isPresented: $showSettings) {
                    VStack(alignment: .trailing, spacing: 12) {
                        SettingsView()
                        Button("Close") {
                            showSettings = false
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 16)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // Content Area
            if let mediaURL = currentMediaURL {
                VStack(spacing: 16) {
                    // Preview box (Image or Video)
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.black)
                        
                        MediaPreviewView(
                            url: mediaURL,
                            scalingMode: scalingMode,
                            isMuted: isMuted
                        )
                        .id(mediaURL)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .frame(height: 200)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                    
                    // Metadata & Controls
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 6) {
                                    Text(mediaURL.lastPathComponent)
                                        .font(.headline)
                                        .lineLimit(1)
                                    
                                    Text(isImageMedia ? "[Image]" : "[Video]")
                                        .font(.caption2)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(isImageMedia ? Color.purple.opacity(0.15) : Color.blue.opacity(0.15))
                                        .foregroundColor(isImageMedia ? .purple : .blue)
                                        .cornerRadius(4)
                                }
                                
                                if let meta = metadata {
                                    Text("\(meta.formattedResolution) • \(meta.formattedDuration) • \(meta.formattedFileSize)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                } else {
                                    Text("Loading metadata...")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            Button("Change Media") {
                                pickMedia()
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                        
                        Divider()
                        
                        // Options: Fill Mode, Mute & Static Frame Toggle
                        VStack(spacing: 10) {
                            HStack(spacing: 24) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Fill Mode")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Picker("", selection: $scalingMode) {
                                        ForEach(ScalingMode.allCases) { mode in
                                            Text(mode.displayName).tag(mode)
                                        }
                                    }
                                    .pickerStyle(.segmented)
                                    .frame(width: 160)
                                    .onChange(of: scalingMode) { newMode in
                                        if wallpaperManager.currentWallpaper != nil {
                                            wallpaperManager.updateScalingMode(newMode)
                                        }
                                    }
                                }
                                
                                Spacer()
                                
                                if !isImageMedia {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text("Audio & Playback")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        
                                        Toggle("Mute Audio", isOn: $isMuted)
                                            .onChange(of: isMuted) { newMuted in
                                                if wallpaperManager.currentWallpaper != nil {
                                                    wallpaperManager.updateMuted(newMuted)
                                                }
                                            }
                                    }
                                }
                            }
                            
                            if !isImageMedia {
                                Toggle("Freeze Motion (Use as Static Frame Wallpaper)", isOn: $isStatic)
                                    .font(.subheadline)
                                    .onChange(of: isStatic) { newStatic in
                                        if wallpaperManager.currentWallpaper != nil {
                                            wallpaperManager.updateIsStatic(newStatic)
                                        }
                                    }
                            }
                        }
                    }
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(NSColor.controlBackgroundColor)))
                    
                    Spacer(minLength: 0)
                    
                    // Action Buttons (Apply & Remove)
                    HStack(spacing: 12) {
                        if isLiveActive {
                            Button(action: removeWallpaper) {
                                HStack(spacing: 6) {
                                    Image(systemName: "trash.fill")
                                    Text("Remove Wallpaper")
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 11)
                                .background(Color.red.opacity(0.12))
                                .foregroundColor(.red)
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.red.opacity(0.4), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                        
                        Button(action: applyWallpaper) {
                            HStack(spacing: 8) {
                                Image(systemName: isLiveActive ? "checkmark.circle.fill" : "photo.fill")
                                Text(isLiveActive ? "Update Settings" : "Set as Desktop Wallpaper")
                                    .fontWeight(.bold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 11)
                            .background(isLiveActive ? Color.green : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(18)
                .onAppear {
                    loadMediaMetadata(url: mediaURL)
                }
            } else {
                EmptyStateView(
                    onSelectFile: { pickMedia() },
                    onDropFile: { url in handleSelectedURL(url) }
                )
            }
        }
        .frame(width: 480, height: 550)
        .onAppear {
            if let active = wallpaperManager.currentWallpaper {
                self.selectedURL = active.fileURL
                self.scalingMode = active.scalingMode
                self.isMuted = active.isMuted
                self.isStatic = active.isStatic
                loadMediaMetadata(url: active.fileURL)
            } else {
                wallpaperManager.loadSavedWallpaper()
                if let active = wallpaperManager.currentWallpaper {
                    self.selectedURL = active.fileURL
                    self.scalingMode = active.scalingMode
                    self.isMuted = active.isMuted
                    self.isStatic = active.isStatic
                    loadMediaMetadata(url: active.fileURL)
                }
            }
        }
    }
    
    private var currentMediaURL: URL? {
        selectedURL ?? wallpaperManager.currentWallpaper?.fileURL
    }
    
    private var isImageMedia: Bool {
        guard let url = currentMediaURL else { return false }
        return Wallpaper.detectMediaKind(for: url) == .image
    }
    
    private var isLiveActive: Bool {
        wallpaperManager.currentWallpaper != nil && wallpaperManager.currentWallpaper?.fileURL == currentMediaURL
    }
    
    private func pickMedia() {
        FileImportService.shared.selectMediaFile { url in
            if let url = url {
                handleSelectedURL(url)
            }
        }
    }
    
    private func handleSelectedURL(_ url: URL) {
        self.selectedURL = url
        loadMediaMetadata(url: url)
    }
    
    private func loadMediaMetadata(url: URL) {
        FileImportService.shared.loadMetadata(for: url) { meta in
            self.metadata = meta
        }
    }
    
    private func applyWallpaper() {
        guard let url = currentMediaURL else { return }
        
        let wallpaper = Wallpaper(
            name: url.lastPathComponent,
            fileURL: url,
            scalingMode: scalingMode,
            isMuted: isMuted,
            isStatic: isStatic
        )
        
        wallpaperManager.setWallpaper(wallpaper)
    }
    
    private func removeWallpaper() {
        wallpaperManager.removeWallpaper()
        self.selectedURL = nil
        self.metadata = nil
    }
}
