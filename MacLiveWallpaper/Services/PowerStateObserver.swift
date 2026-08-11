import AppKit
import Combine

public final class PowerStateObserver: ObservableObject {
    public static let shared = PowerStateObserver()
    
    public var onSleep: (() -> Void)?
    public var onWake: (() -> Void)?
    
    private var cancellables = Set<AnyCancellable>()
    private var isSleeping = false
    
    private init() {
        setupObservers()
    }
    
    private func setupObservers() {
        let wsNC = NSWorkspace.shared.notificationCenter
        
        // System Sleep & Wake
        wsNC.publisher(for: NSWorkspace.willSleepNotification)
            .sink { [weak self] _ in
                self?.handleSleep(reason: "System Sleep")
            }
            .store(in: &cancellables)
        
        wsNC.publisher(for: NSWorkspace.didWakeNotification)
            .sink { [weak self] _ in
                self?.handleWake(reason: "System Wake")
            }
            .store(in: &cancellables)
        
        // Display Sleep & Wake
        wsNC.publisher(for: NSWorkspace.screensDidSleepNotification)
            .sink { [weak self] _ in
                self?.handleSleep(reason: "Screens Sleep")
            }
            .store(in: &cancellables)
        
        wsNC.publisher(for: NSWorkspace.screensDidWakeNotification)
            .sink { [weak self] _ in
                self?.handleWake(reason: "Screens Wake")
            }
            .store(in: &cancellables)
        
        // User Session
        wsNC.publisher(for: NSWorkspace.sessionDidResignActiveNotification)
            .sink { [weak self] _ in
                self?.handleSleep(reason: "Session Inactive")
            }
            .store(in: &cancellables)
        
        wsNC.publisher(for: NSWorkspace.sessionDidBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.handleWake(reason: "Session Active")
            }
            .store(in: &cancellables)
    }
    
    private func handleSleep(reason: String) {
        guard !isSleeping else { return }
        print("[PowerStateObserver] Sleep triggered (\(reason))")
        isSleeping = true
        onSleep?()
    }
    
    private func handleWake(reason: String) {
        guard isSleeping else { return }
        print("[PowerStateObserver] Wake triggered (\(reason))")
        isSleeping = false
        onWake?()
    }
}
