import AppKit
import Combine

public final class ScreenManager: ObservableObject {
    public static let shared = ScreenManager()
    
    @Published public private(set) var screens: [NSScreen] = []
    public var onScreenConfigurationChanged: (([NSScreen]) -> Void)?
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        self.screens = NSScreen.screens
        setupObservers()
    }
    
    private func setupObservers() {
        NotificationCenter.default.publisher(for: NSApplication.didChangeScreenParametersNotification)
            .sink { [weak self] _ in
                self?.handleScreenChange()
            }
            .store(in: &cancellables)
    }
    
    private func handleScreenChange() {
        let currentScreens = NSScreen.screens
        print("[ScreenManager] Display configuration changed. Active screens: \(currentScreens.count)")
        self.screens = currentScreens
        onScreenConfigurationChanged?(currentScreens)
    }
}
