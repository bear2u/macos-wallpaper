import SwiftUI
import UniformTypeIdentifiers

struct EmptyStateView: View {
    let onSelectFile: () -> Void
    let onDropFile: (URL) -> Void
    @State private var isTargeted: Bool = false
    
    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "photo.on.rectangle.angled")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 40, height: 40)
                    .foregroundColor(.blue)
            }
            
            VStack(spacing: 8) {
                Text("Mac Live Wallpaper")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                
                Text("Turn your videos or images into desktop wallpapers.")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 16) {
                Button(action: onSelectFile) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                        Text("Choose Video or Image")
                            .fontWeight(.semibold)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .buttonStyle(.plain)
                
                Text("Supported: MP4, MOV, PNG, JPG, HEIC, WEBP")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(isTargeted ? Color.blue : Color.gray.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [8]))
                .background(isTargeted ? Color.blue.opacity(0.05) : Color.clear)
        )
        .padding(24)
        .onDrop(of: [.movie, .quickTimeMovie, .mpeg4Movie, .image, .png, .jpeg, .heic], isTargeted: $isTargeted) { providers in
            guard let provider = providers.first else { return false }
            
            _ = provider.loadObject(ofClass: URL.self) { url, _ in
                let validExtensions = ["mp4", "mov", "png", "jpg", "jpeg", "heic", "heif", "webp", "gif"]
                if let url = url, validExtensions.contains(url.pathExtension.lowercased()) {
                    DispatchQueue.main.async {
                        onDropFile(url)
                    }
                }
            }
            return true
        }
    }
}
