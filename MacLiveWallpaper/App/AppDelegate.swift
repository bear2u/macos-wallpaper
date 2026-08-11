import AppKit
import SwiftUI

public final class AppDelegate: NSObject, NSApplicationDelegate {
    public static var shared: AppDelegate?
    
    public var mainWindow: NSWindow?
    private var statusItem: NSStatusItem?
    
    public func applicationDidFinishLaunching(_ notification: Notification) {
        AppDelegate.shared = self
        
        // Setup Status Bar Menu Item
        setupStatusItem()
        
        // Auto-resume saved wallpaper if configured
        WallpaperManager.shared.loadSavedWallpaper()
        
        // Prevent app from quitting when all windows are closed
        NSApplication.shared.setActivationPolicy(.regular)
    }
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "film.stack", accessibilityDescription: "Mac Live Wallpaper")
            button.action = #selector(statusItemClicked)
            button.target = self
        }
        
        let menu = NSMenu()
        
        let statusTitleItem = NSMenuItem(title: "Mac Live Wallpaper", action: nil, keyEquivalent: "")
        statusTitleItem.isEnabled = false
        menu.addItem(statusTitleItem)
        menu.addItem(NSMenuItem.separator())
        
        let togglePlayItem = NSMenuItem(title: "Pause / Play", action: #selector(togglePlayback), keyEquivalent: "")
        togglePlayItem.target = self
        menu.addItem(togglePlayItem)
        
        let removeItem = NSMenuItem(title: "Remove Live Wallpaper", action: #selector(removeWallpaper), keyEquivalent: "r")
        removeItem.target = self
        menu.addItem(removeItem)
        
        let openAppItem = NSMenuItem(title: "Open Main Window", action: #selector(showMainWindow), keyEquivalent: "m")
        openAppItem.target = self
        menu.addItem(openAppItem)
        
        menu.addItem(NSMenuItem.separator())
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem?.menu = menu
    }
    
    @objc private func statusItemClicked() {
        // Menu item click action handled by NSMenu
    }
    
    @objc public func togglePlayback() {
        WallpaperManager.shared.togglePlayPause()
    }
    
    @objc public func removeWallpaper() {
        WallpaperManager.shared.removeWallpaper()
    }
    
    @objc public func showMainWindow() {
        if let window = mainWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
    
    @objc public func quitApp() {
        WallpaperManager.shared.stop()
        NSApplication.shared.terminate(nil)
    }
    
    public func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
}
