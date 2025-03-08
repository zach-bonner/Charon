//
//  AppDelegate.swift
//  Charon
//
//  Created by Zachary Bonner on 3/3/25.
//

import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var fileMonitor: FileMonitor?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        setupMenuBar()
        requestFileAccessPermission()
        
        let desktopPath = ("~/Desktop" as NSString).expandingTildeInPath
        fileMonitor = FileMonitor(path: desktopPath) { changedFile in
            DispatchQueue.main.async {
                print("File changed: \(changedFile)")
                FileMover.moveFileIfTagged(filePath: changedFile)
            }
        }
    }
    
    func requestFileAccessPermission() {
        let openPanel = NSOpenPanel()
        openPanel.message = "Charon needs access to your files to monitor tags"
        openPanel.prompt = "Grant Access"
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = true
        openPanel.canCreateDirectories = false
        openPanel.canChooseFiles = false
        openPanel.directoryURL = URL(fileURLWithPath: ("~/Desktop" as NSString).expandingTildeInPath)
        
        openPanel.begin { response in
            if response == .OK {
                print("Access granted to: \(openPanel.urls)")
            }
        }
    }
    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "tag.fill", accessibilityDescription: "Tag Monitor")
        }

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q"))
        statusItem?.menu = menu
    }

    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
