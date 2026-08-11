import SwiftUI

struct SettingsView: View {
    @ObservedObject var preferenceStore = PreferenceStore.shared
    @ObservedObject var loginItemManager = LoginItemManager.shared
    
    var body: some View {
        Form {
            Section(header: Text("General Settings").fontWeight(.semibold)) {
                Toggle("Launch at Login", isOn: Binding(
                    get: { loginItemManager.isEnabled },
                    set: { newValue in
                        loginItemManager.setLaunchAtLogin(newValue)
                    }
                ))
                .help("Automatically open Mac Live Wallpaper when you log into your Mac.")
                
                Toggle("Resume last wallpaper on launch", isOn: $preferenceStore.settings.resumeLastWallpaper)
                    .help("Automatically set the previous video wallpaper when the app launches.")
                
                Toggle("Pause video when display sleeps", isOn: $preferenceStore.settings.pauseOnSleep)
                    .help("Pause playback during display sleep or lock screen to conserve battery and CPU.")
            }
            
            Section(header: Text("Default Video Playback").fontWeight(.semibold)) {
                Picker("Fill Mode", selection: $preferenceStore.settings.defaultScalingMode) {
                    ForEach(ScalingMode.allCases) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                
                Toggle("Mute Audio by default", isOn: $preferenceStore.settings.defaultIsMuted)
            }
            
            Section {
                HStack {
                    Spacer()
                    Button("Remove Current Wallpaper") {
                        WallpaperManager.shared.stop()
                        PreferenceStore.shared.clearLastWallpaper()
                    }
                    .foregroundColor(.red)
                }
            }
        }
        .padding(20)
        .frame(width: 440, height: 320)
    }
}
