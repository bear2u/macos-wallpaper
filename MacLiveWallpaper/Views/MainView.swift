import SwiftUI

struct MainView: View {
    @ObservedObject var wallpaperManager = WallpaperManager.shared
    
    @State private var selectedURL: URL?
    @State private var metadata: VideoMetadata?
    @State private var scalingMode: ScalingMode = .fill
    @State private var isMuted: Bool = true
    @State private var isStatic: Bool = false
    @State private var showSettings: Bool = false
    @State private var activeTab: Int = 0 // 0: Player & Options, 1: Playlist
    
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
                
                Picker("", selection: $activeTab) {
                    Text("Single").tag(0)
                    Text("Playlist (\(wallpaperManager.playlist.count))").tag(1)
                }
                .pickerStyle(.segmented)
                .frame(width: 170)
                
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
            .padding(.vertical, 12)
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // Content Area
            if activeTab == 1 {
                // Playlist & Auto Switch Options Tab
                playlistView
            } else if let mediaURL = currentMediaURL {
                // Single Player & Preview Tab
                singlePlayerView(mediaURL: mediaURL)
            } else {
                EmptyStateView(
                    onSelectFile: { pickMultipleMedia() },
                    onDropFile: { url in handleSelectedURL(url) }
                )
            }
        }
        .frame(width: 500, height: 570)
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
    
    // MARK: - Single Player View
    @ViewBuilder
    private func singlePlayerView(mediaURL: URL) -> some View {
        VStack(spacing: 14) {
            // Preview Box
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
                    
                    Button("Add to Playlist") {
                        wallpaperManager.addToPlaylist(urls: [mediaURL])
                        activeTab = 1
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
            
            // Action Buttons
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
    }
    
    // MARK: - Playlist View
    private var playlistView: some View {
        VStack(spacing: 14) {
            // Options: Sequential/Random & Switch Interval
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Playlist Settings")
                        .font(.headline)
                    Spacer()
                    Button(action: pickMultipleMedia) {
                        HStack(spacing: 4) {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Media Files")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
                
                Divider()
                
                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Playback Order")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Picker("", selection: $wallpaperManager.playbackOrder) {
                            ForEach(PlaybackOrder.allCases) { order in
                                Text(order.displayName).tag(order)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Switch Interval")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Picker("", selection: $wallpaperManager.switchInterval) {
                            ForEach(SwitchInterval.allCases) { interval in
                                Text(interval.displayName).tag(interval)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color(NSColor.controlBackgroundColor)))
            
            // Playlist List
            if wallpaperManager.playlist.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "square.stack.3d.up.slash")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("No wallpapers in playlist yet")
                        .foregroundColor(.secondary)
                    Button("Add Media Files") {
                        pickMultipleMedia()
                    }
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(Array(wallpaperManager.playlist.enumerated()), id: \.element.id) { index, wp in
                        HStack(spacing: 12) {
                            Circle()
                                .fill(index == wallpaperManager.currentIndex ? Color.green : Color.clear)
                                .frame(width: 8, height: 8)
                            
                            Image(systemName: wp.mediaKind == .image ? "photo.fill" : "film.fill")
                                .foregroundColor(wp.mediaKind == .image ? .purple : .blue)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(wp.name)
                                    .fontWeight(index == wallpaperManager.currentIndex ? .semibold : .regular)
                                    .lineLimit(1)
                                Text(wp.mediaKind.rawValue.capitalized)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if index == wallpaperManager.currentIndex {
                                Text("Active")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.green.opacity(0.15))
                                    .foregroundColor(.green)
                                    .cornerRadius(4)
                            }
                            
                            Button(action: {
                                wallpaperManager.setWallpaper(wp)
                                self.selectedURL = wp.fileURL
                            }) {
                                Image(systemName: "play.circle.fill")
                                    .foregroundColor(.blue)
                            }
                            .buttonStyle(.plain)
                            
                            Button(action: {
                                wallpaperManager.removeFromPlaylist(id: wp.id)
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.gray)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, 2)
                    }
                }
                .listStyle(.inset)
                .cornerRadius(8)
            }
            
            // Bottom Controls (Previous / Next / Clear)
            HStack {
                Button(action: { wallpaperManager.playPreviousWallpaper() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "backward.fill")
                        Text("Previous")
                    }
                }
                .disabled(wallpaperManager.playlist.isEmpty)
                
                Button(action: { wallpaperManager.playNextWallpaper() }) {
                    HStack(spacing: 4) {
                        Text("Next")
                        Image(systemName: "forward.fill")
                    }
                }
                .disabled(wallpaperManager.playlist.isEmpty)
                
                Spacer()
                
                if !wallpaperManager.playlist.isEmpty {
                    Button("Clear Playlist") {
                        wallpaperManager.clearPlaylist()
                        self.selectedURL = nil
                    }
                    .foregroundColor(.red)
                }
            }
        }
        .padding(18)
    }
    
    // MARK: - Helpers
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
    
    private func pickMultipleMedia() {
        FileImportService.shared.selectMultipleMediaFiles { urls in
            if !urls.isEmpty {
                wallpaperManager.addToPlaylist(urls: urls)
                if let first = urls.first {
                    handleSelectedURL(first)
                }
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
