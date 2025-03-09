//
//  AppDelegate.swift
//  Charon
//
//  Created by Zachary Bonner on 3/8/25.
//

import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var rulesWindowController: NSWindowController?
    var fileMonitor: FileMonitor?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        NSApplication.shared.setActivationPolicy(.accessory)
        setupMenuBar() // ✅ Restored status bar icon creation
        requestFileAccessPermission()

        if let savedPath = UserDefaults.standard.string(forKey: "monitoredDirectory") {
            startMonitoringDirectory(savedPath)
        } else {
            print("⚠️ No directory set for monitoring.")
        }
    }

    private func setupMenuBar() {
        if statusItem == nil {
            print("📌 Creating menu bar icon...")
            statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

            if let button = statusItem?.button {
                button.image = NSImage(systemSymbolName: "tag.fill", accessibilityDescription: "Tag Monitor")
            }

            let menu = NSMenu()
            menu.addItem(NSMenuItem(title: "Manage Rules", action: #selector(openRulesWindow), keyEquivalent: "r"))
            menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q"))
            statusItem?.menu = menu
        } else {
            print("✅ Menu bar icon already exists.")
        }
    }

    func startMonitoringDirectory(_ path: String) {
        print("📂 Monitoring directory: \(path)")
        fileMonitor = FileMonitor(path: path) { changedFile in
            DispatchQueue.main.async {
                print("📂 File changed: \(changedFile)")
                FileMover.moveFileIfTagged(filePath: changedFile)
            }
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        if let statusItem = statusItem {
            NSStatusBar.system.removeStatusItem(statusItem)
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
                print("✅ Access granted to: \(openPanel.urls)")
                UserDefaults.standard.set(openPanel.urls.first?.path, forKey: "monitoredDirectory")
            } else {
                print("⚠️ Access denied. File monitoring may not work properly.")
            }
        }
    }
    

    @objc private func openRulesWindow() {
        if rulesWindowController == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 400, height: 500),
                styleMask: [.titled, .closable, .resizable],
                backing: .buffered,
                defer: false)
            window.center()
            window.setFrameAutosaveName("Rules Manager")
            window.contentView = NSHostingView(rootView: RulesView())

            rulesWindowController = NSWindowController(window: window)
        }
        rulesWindowController?.showWindow(nil)
    }
    

    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
