import AppKit
import AVFoundation
import UniformTypeIdentifiers

public final class FileImportService {
    public static let shared = FileImportService()
    
    private init() {}
    
    public func selectMediaFile(completion: @escaping (URL?) -> Void) {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [
            .mpeg4Movie,
            .quickTimeMovie,
            .movie,
            .png,
            .jpeg,
            .heic,
            .image,
            UTType(filenameExtension: "webp") ?? .image,
            UTType(filenameExtension: "gif") ?? .image
        ]
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.title = "Select Wallpaper (Video or Image)"
        panel.prompt = "Choose"
        
        panel.begin { response in
            if response == .OK, let selectedURL = panel.url {
                completion(selectedURL)
            } else {
                completion(nil)
            }
        }
    }
    
    public func loadMetadata(for url: URL, completion: @escaping (VideoMetadata?) -> Void) {
        let kind = Wallpaper.detectMediaKind(for: url)
        
        _ = url.startAccessingSecurityScopedResource()
        
        if kind == .image {
            Task {
                var resolution: CGSize = .zero
                if let image = NSImage(contentsOf: url) {
                    if let rep = image.representations.first {
                        resolution = CGSize(width: rep.pixelsWide > 0 ? rep.pixelsWide : Int(image.size.width),
                                            height: rep.pixelsHigh > 0 ? rep.pixelsHigh : Int(image.size.height))
                    } else {
                        resolution = image.size
                    }
                }
                
                var fileSize: Int64 = 0
                if let resources = try? url.resourceValues(forKeys: [.fileSizeKey]), let size = resources.fileSize {
                    fileSize = Int64(size)
                }
                
                let meta = VideoMetadata(
                    duration: 0,
                    resolution: resolution,
                    fileSize: fileSize,
                    isImage: true
                )
                
                DispatchQueue.main.async {
                    completion(meta)
                }
            }
            return
        }
        
        // Video Asset Metadata
        let asset = AVURLAsset(url: url)
        Task {
            do {
                let duration = try await asset.load(.duration)
                let tracks = try await asset.loadTracks(withMediaType: .video)
                
                var resolution: CGSize = .zero
                if let firstTrack = tracks.first {
                    let size = try await firstTrack.load(.naturalSize)
                    let transform = try await firstTrack.load(.preferredTransform)
                    let rect = CGRect(origin: .zero, size: size).applying(transform)
                    resolution = CGSize(width: abs(rect.width), height: abs(rect.height))
                }
                
                var fileSize: Int64 = 0
                if let resources = try? url.resourceValues(forKeys: [.fileSizeKey]), let size = resources.fileSize {
                    fileSize = Int64(size)
                }
                
                let metadata = VideoMetadata(
                    duration: CMTimeGetSeconds(duration),
                    resolution: resolution,
                    fileSize: fileSize,
                    isImage: false
                )
                
                DispatchQueue.main.async {
                    completion(metadata)
                }
            } catch {
                print("[FileImportService] Failed to load asset metadata: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }
    }
}
