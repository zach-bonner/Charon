//
//  CharonApp.swift
//  Charon
//
//  Created by Zachary Bonner on 3/3/25.
//

import SwiftUI

@main
struct CharonApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView() // No main window, just menu bar
        }
    }
}
