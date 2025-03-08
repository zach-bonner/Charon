//
//  DirectoryTagScanner.swift
//  Charon
//
//  Created by Zachary Bonner on 3/3/25.
//

import Foundation

class DirectoryTagScanner {
    
    static func scanDirectoryForTags(path: String) -> [String: [String]] {
        var fileTagsMap: [String: [String]] = [:]
        
        // Get all files in the directory
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: URL(fileURLWithPath: path),
                                                                      includingPropertiesForKeys: nil)
            
            // Process each file
            for fileURL in fileURLs {
                let filePath = fileURL.path
                let tags = getTagsForFile(filePath: filePath)
                
                if !tags.isEmpty {
                    fileTagsMap[filePath] = tags
                }
            }
            
            print("✅ Scanned \(fileURLs.count) files, found \(fileTagsMap.count) files with tags")
        } catch {
            print("❌ Error scanning directory: \(error)")
        }
        
        return fileTagsMap
    }
    
    static func getTagsForFile(filePath: String) -> [String] {
        // Create a process to run xattr
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/xattr")
        process.arguments = ["-l", filePath]
        
        // Set up pipes for stdout and stderr
        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        
        let errorPipe = Pipe()
        process.standardError = errorPipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            if process.terminationStatus != 0 {
                let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                if let errorOutput = String(data: errorData, encoding: .utf8) {
                    print("⚠️ xattr error for \(filePath): \(errorOutput)")
                }
                return []
            }
            
            // Read the output
            let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            guard let output = String(data: outputData, encoding: .utf8) else {
                print("⚠️ Couldn't decode xattr output for \(filePath)")
                return []
            }
            
            // Parse the output to extract the tag information
            return parseXattrOutput(output)
            
        } catch {
            print("❌ Error running xattr: \(error)")
            return []
        }
    }
    
    static func parseXattrOutput(_ output: String) -> [String] {
        var tags: [String] = []
        
        // Look specifically for the com.apple.metadata:_kMDItemUserTags attribute
        let lines = output.split(separator: "\n")
        for line in lines {
            if line.contains("com.apple.metadata:_kMDItemUserTags:") {
                // Found the tags attribute, now extract the data
                // The format is usually a bplist, so we'd need to extract that binary data
                // and parse it, which is complex to do directly from the xattr output
                
                // For a more reliable approach, let's use a separate xattr call
                // to get just the tag data and parse it
                if let filePathLine = lines.first,
                   let filePath = filePathLine.split(separator: ":").first?.trimmingCharacters(in: .whitespaces) {
                    tags = getTagsWithSpecificXattr(filePath: String(filePath))
                    break
                }
            }
        }
        
        return tags
    }
    
    static func getTagsWithSpecificXattr(filePath: String) -> [String] {
        // Create a process to run xattr specifically for the tags
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/xattr")
        process.arguments = ["-p", "com.apple.metadata:_kMDItemUserTags", filePath]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            if process.terminationStatus != 0 {
                return []
            }
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            
            // The output is a binary plist, so we need to parse it
            return parseTagsPlistData(data)
            
        } catch {
            print("❌ Error getting tags with xattr: \(error)")
            return []
        }
    }
    
    static func parseTagsPlistData(_ data: Data) -> [String] {
        guard !data.isEmpty else { return [] }
        
        do {
            // Try to decode the binary plist data
            if let plist = try PropertyListSerialization.propertyList(from: data,
                                                                    options: [],
                                                                    format: nil) as? [String] {
                return plist
            }
        } catch {
            print("❌ Error decoding tag plist: \(error)")
        }
        
        return []
    }
}


