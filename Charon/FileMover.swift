//
//  FileMover.swift
//  Charon
//
//  Created by Zachary Bonner on 3/8/25.
//

import Foundation

struct TagRule: Codable {
    var tags: [String]
    var matchType: String
    var destination: String

    enum CodingKeys: String, CodingKey {
        case tags, matchType, destination
    }

    init(tags: [String], matchType: String = "any", destination: String) {
        self.tags = tags
        self.matchType = matchType
        self.destination = destination
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        tags = try container.decode([String].self, forKey: .tags)
        destination = try container.decode(String.self, forKey: .destination)
        matchType = try container.decodeIfPresent(String.self, forKey: .matchType) ?? "any"
    }
}

struct RulesFile: Codable {
    let rules: [TagRule]
}

class RuleManager {
    static let rulesFilePath = ("~/Library/Application Support/Charon/rules.json" as NSString).expandingTildeInPath
    
    static func loadRules() -> [TagRule] {
        let fileURL = URL(fileURLWithPath: rulesFilePath)

        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            print("No rules file found, using default rules.")
            return []
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let rulesFile = try JSONDecoder().decode(RulesFile.self, from: data)
            print("Loaded \(rulesFile.rules.count) user-defined rules.")
            return rulesFile.rules
        } catch {
            print("Failed to load rules: \(error)")
            return []
        }
    }
}

class FileMover {
    static func moveFileIfTagged(filePath: String) {
        let tags = TagManager.getTags(for: filePath)
        print("Tags detected for \(filePath): \(tags)")

        let rules = RuleManager.loadRules()

        for rule in rules {
            if matchesRule(tags: tags, rule: rule) {
                print("Rule matched! Moving file to \(rule.destination)")
                moveFile(filePath: filePath, to: rule.destination)
                return
            }
        }
        print("No matching rule found for \(filePath)")
    }

    private static func matchesRule(tags: [String], rule: TagRule) -> Bool {
        let fileTagSet = Set(tags)
        let ruleTagSet = Set(rule.tags)

        switch rule.matchType {
        case "any":
            return !fileTagSet.isDisjoint(with: ruleTagSet)
        case "all":
            return ruleTagSet.isSubset(of: fileTagSet)
        case "exclusive":
            return fileTagSet == ruleTagSet
        default:
            print("Unknown match type: \(rule.matchType)")
            return false
        }
    }

    private static func moveFile(filePath: String, to destinationPath: String) {
        let expandedDestination = (destinationPath as NSString).expandingTildeInPath
        let destinationURL = URL(fileURLWithPath: expandedDestination)
        let fileURL = URL(fileURLWithPath: filePath)

        print("Attempting to move file: \(filePath) to \(destinationURL.path)")

        do {
            try FileManager.default.createDirectory(at: destinationURL, withIntermediateDirectories: true, attributes: nil)
            let destinationFileURL = destinationURL.appendingPathComponent(fileURL.lastPathComponent)

            if FileManager.default.fileExists(atPath: destinationFileURL.path) {
                print("File already exists at destination. Skipping move.")
                return
            }

            try FileManager.default.moveItem(at: fileURL, to: destinationFileURL)
            print("File successfully moved to \(destinationFileURL.path)")
        } catch {
            print("Error moving file: \(error)")
        }
    }
}
