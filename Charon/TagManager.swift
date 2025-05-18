//
//  TagManager.swift
//  Charon
//
//  Created by Zachary Bonner on 3/8/25.
//

import Foundation
import CoreServices

import Foundation

class TagManager {
    static func getTags(for filePath: String) -> [String] {
        let tags = DirectoryTagScanner.getTagsForFile(filePath: filePath)
        
        if !tags.isEmpty {
            print("✅ Tags retrieved for \(filePath): \(tags)")
            return tags
        }
        
        print("⚠️ No valid tags found for \(filePath)")
        return []
    }
}
