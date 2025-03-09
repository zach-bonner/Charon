//
//  DirectoryTagScanner.swift
//  Charon
//
//  Created by Zachary Bonner on 3/8/25.
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
        print("Running xattr on: \(filePath)")
        return getTagsWithSpecificXattr(filePath: filePath)
    }
    
    static func getTagsWithSpecificXattr(filePath: String) -> [String] {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/xattr")
        process.arguments = ["-p", "com.apple.metadata:_kMDItemUserTags", filePath]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            if process.terminationStatus != 0 {
                print("⚠️ xattr failed to retrieve tags for \(filePath)")
                return []
            }
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if data.isEmpty {
                print("⚠️ No tag data found for \(filePath)")
                return []
            }
            
            // Convert the xattr output to hex representation for debugging
            let hexString = data.map { String(format: "%02x", $0) }.joined()
            print("🔍 Raw xattr data (hex): \(hexString)")
            
            // Try to decode the binary plist directly
            return parseTagsBinaryData(data, filePath: filePath)
            
        } catch {
            print("❌ Error running xattr: \(error)")
            return []
        }
    }

    static func parseTagsBinaryData(_ data: Data, filePath: String) -> [String] {
        // Check if the data begins with "bplist" as text (not binary)
        if let dataString = String(data: data, encoding: .utf8),
           dataString.hasPrefix("bplist") {
            
            print("🔄 Detected textual representation of binary plist")
            
            // Setup pipes and process for plutil conversion
            let plistProcess = Process()
            plistProcess.executableURL = URL(fileURLWithPath: "/usr/bin/plutil")
            plistProcess.arguments = ["-convert", "xml1", "-o", "-", "-"]
            
            let inputPipe = Pipe()
            let outputPipe = Pipe()
            
            plistProcess.standardInput = inputPipe
            plistProcess.standardOutput = outputPipe
            
            do {
                try plistProcess.run()
                
                // Write the binary plist data to the process
                try inputPipe.fileHandleForWriting.write(contentsOf: data)
                inputPipe.fileHandleForWriting.closeFile()
                
                // Read the XML output
                let xmlData = outputPipe.fileHandleForReading.readDataToEndOfFile()
                plistProcess.waitUntilExit()
                
                if plistProcess.terminationStatus == 0 && !xmlData.isEmpty {
                    if let xmlString = String(data: xmlData, encoding: .utf8) {
                        print("✅ Converted to XML: \(xmlString)")
                        
                        // Extract tag values from XML using regex
                        let pattern = "<string>([^<]+)</string>"
                        do {
                            let regex = try NSRegularExpression(pattern: pattern)
                            let matches = regex.matches(in: xmlString, range: NSRange(xmlString.startIndex..., in: xmlString))
                            
                            let tags = matches.compactMap { match -> String? in
                                if let range = Range(match.range(at: 1), in: xmlString) {
                                    return String(xmlString[range])
                                }
                                return nil
                            }
                            
                            if !tags.isEmpty {
                                print("✅ Extracted tags: \(tags)")
                                return tags
                            }
                        } catch {
                            print("⚠️ Regex failed: \(error)")
                        }
                    }
                } else {
                    print("⚠️ plutil conversion failed")
                }
            } catch {
                print("❌ Error processing with plutil: \(error)")
            }
        }
        
        // Alternative approach using mdls command to get tags
        do {
            let mdlsProcess = Process()
            mdlsProcess.executableURL = URL(fileURLWithPath: "/usr/bin/mdls")
            mdlsProcess.arguments = ["-raw", "-name", "kMDItemUserTags", filePath]
            
            let mdlsPipe = Pipe()
            mdlsProcess.standardOutput = mdlsPipe
            
            try mdlsProcess.run()
            mdlsProcess.waitUntilExit()
            
            let outputData = mdlsPipe.fileHandleForReading.readDataToEndOfFile()
            if let outputString = String(data: outputData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
               outputString != "(null)" {
                
                // Parse the mdls output which is usually in the format: (tag1, tag2, tag3)
                let cleanedString = outputString
                    .trimmingCharacters(in: CharacterSet(charactersIn: "()"))
                    .replacingOccurrences(of: "\"", with: "")
                
                let tags = cleanedString
                    .components(separatedBy: ",")
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
                
                if !tags.isEmpty {
                    print("✅ Got tags using mdls: \(tags)")
                    return tags
                }
            }
        } catch {
            print("❌ Error using mdls fallback: \(error)")
        }
        
        // Finally, try manual parsing for the specific bplist format in the example
        if let dataString = String(data: data, encoding: .utf8) {
            print("🔍 Attempting manual parsing of: \(dataString)")
            
            // Extract strings between visible characters
            let components = dataString.components(separatedBy: CharacterSet.alphanumerics.inverted)
            let possibleTags = components.filter { !$0.isEmpty && $0 != "bplist" && $0.count > 1 }
            
            if !possibleTags.isEmpty {
                print("✅ Manually extracted possible tags: \(possibleTags)")
                return possibleTags
            }
        }
        
        print("⚠️ No valid tags found using any method")
        return []
    }
}


