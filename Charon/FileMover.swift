//
//  FileMover.swift
//  Charon
//
//  Created by Zachary Bonner on 3/3/25.
//

import Foundation

class FileMover {
    static let tagRules: [String: String] = [
        "Invoices": "~/Documents/Invoices",
        "Work": "~/Documents/Work",
        "Personal": "~/Documents/Personal"
    ]

    static func moveFileIfTagged(filePath: String) {
        let tags = TagManager.getTags(for: filePath)
        
        for tag in tags {
            if let destinationPath = tagRules[tag] {
                moveFile(filePath: filePath, to: destinationPath)
                return // Move only once per tag
            }
            print("Tags detected for \(filePath): \(tags)")
            print("Checking tag rules for \(filePath)")
        }
        print("Tags detected for \(filePath): \(tags)")
        print("Checking tag rules for \(filePath)")
    }

    private static func moveFile(filePath: String, to destinationPath: String) {
        let expandedDestination = (destinationPath as NSString).expandingTildeInPath
        let destinationURL = URL(fileURLWithPath: expandedDestination)
        
        print("Attempting to move file: \(filePath) to \(destinationURL.path)")

        do {
            try FileManager.default.createDirectory(at: destinationURL, withIntermediateDirectories: true, attributes: nil)
            print("✅ Destination directory exists: \(destinationURL.path)")
        } catch {
            print("❌ Error creating destination directory: \(error)")
            return
        }

        let fileURL = URL(fileURLWithPath: filePath)
        let destinationFileURL = destinationURL.appendingPathComponent(fileURL.lastPathComponent)

        // Check if file already exists at destination
        if FileManager.default.fileExists(atPath: destinationFileURL.path) {
            print("⚠️ File already exists at destination. Skipping move.")
            return
        }

        do {
            try FileManager.default.moveItem(at: fileURL, to: destinationFileURL)
            print("✅ File successfully moved to \(destinationFileURL.path)")
        } catch {
            print("❌ Error moving file: \(error)")
        }
    }
}
