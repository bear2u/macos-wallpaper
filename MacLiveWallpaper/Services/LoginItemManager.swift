import Foundation
import ServiceManagement

public final class LoginItemManager: ObservableObject {
    public static let shared = LoginItemManager()
    
    @Published public private(set) var isEnabled: Bool = false
    
    private init() {
        checkStatus()
    }
    
    public func checkStatus() {
        if #available(macOS 13.0, *) {
            self.isEnabled = (SMAppService.mainApp.status == .enabled)
        } else {
            self.isEnabled = false
        }
    }
    
    public func setLaunchAtLogin(_ enable: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enable {
                    if SMAppService.mainApp.status != .enabled {
                        try SMAppService.mainApp.register()
                    }
                } else {
                    if SMAppService.mainApp.status == .enabled {
                        try SMAppService.mainApp.unregister()
                    }
                }
                checkStatus()
            } catch {
                print("[LoginItemManager] Failed to update launch at login status: \(error.localizedDescription)")
            }
        }
    }
}
