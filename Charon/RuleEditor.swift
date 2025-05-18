//
//  RuleEditor.swift
//  Charon
//
//  Created by Zachary Bonner on 3/8/25.
//

import Foundation

class RuleEditor {
    static let rulesFilePath = RuleManager.rulesFilePath

    static func loadRules() -> [TagRule] {
        return RuleManager.loadRules()
    }

    static func saveRules(_ rules: [TagRule]) {
        let rulesFile = RulesFile(rules: rules)
        let fileURL = URL(fileURLWithPath: rulesFilePath)

        do {
            let data = try JSONEncoder().encode(rulesFile)
            try data.write(to: fileURL)
            print("Rules successfully saved.")
        } catch {
            print("Error saving rules: \(error)")
        }
    }

    static func addRule(tags: [String], matchType: String, destination: String) {
        var rules = loadRules()
        let newRule = TagRule(tags: tags, matchType: matchType, destination: destination)
        rules.append(newRule)
        saveRules(rules)
    }

    static func modifyRule(index: Int, newTags: [String]?, newMatchType: String?, newDestination: String?) {
        var rules = loadRules()
        guard index >= 0 && index < rules.count else {
            print("Invalid rule index.")
            return
        }

        if let newTags = newTags { rules[index].tags = newTags }
        if let newMatchType = newMatchType { rules[index].matchType = newMatchType }
        if let newDestination = newDestination { rules[index].destination = newDestination }

        saveRules(rules)
    }

    static func deleteRule(index: Int) {
        var rules = loadRules()
        guard index >= 0 && index < rules.count else {
            print("Invalid rule index.")
            return
        }

        rules.remove(at: index)
        saveRules(rules)
    }

    static func displayRules() {
        let rules = loadRules()
        print("Current Rules:")
        for (index, rule) in rules.enumerated() {
            print("\(index): \(rule.tags) [\(rule.matchType)] → \(rule.destination)")
        }
    }
}
