//
//  FileMoverTests.swift
//  Charon
//
//  Created by Zachary Bonner on 3/8/25.
//

import XCTest

@testable import Charon

class FileMoverTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Set up mock rule configurations
        let testRules: [TagRule] = [
            TagRule(tags: ["Invoices"], matchType: "any", destination: "/mock/Documents/Invoices"),
            TagRule(tags: ["Invoices", "ClientA"], matchType: "all", destination: "/mock/Documents/Invoices/ClientA"),
            TagRule(tags: ["Personal"], matchType: "exclusive", destination: "/mock/Documents/Personal")
        ]

        // Simulate writing the rules to a mock JSON file
        let rulesFile = RulesFile(rules: testRules)
        let jsonData = try! JSONEncoder().encode(rulesFile)
        let testFilePath = RuleManager.rulesFilePath
        try! jsonData.write(to: URL(fileURLWithPath: testFilePath))
    }

    override func tearDown() {
        super.tearDown()
        // Clean up the mock rules file
        try? FileManager.default.removeItem(atPath: RuleManager.rulesFilePath)
    }

    func testMoveFileIfTagged_anyRule() {
        let testFilePath = "/mock/Desktop/test_invoice.pdf"
        let mockTags = ["Invoices"] // Should trigger "any" rule

        let rule = TagRule(tags: ["Invoices"], matchType: "any", destination: "/mock/Documents/Invoices")
        XCTAssertTrue(FileMover.matchesRule(tags: mockTags, rule: rule))
    }

    func testMoveFileIfTagged_allRule() {
        let testFilePath = "/mock/Desktop/clientA_invoice.pdf"
        let mockTags = ["Invoices", "ClientA"] // Should trigger "all" rule

        let rule = TagRule(tags: ["Invoices", "ClientA"], matchType: "all", destination: "/mock/Documents/Invoices/ClientA")
        XCTAssertTrue(FileMover.matchesRule(tags: mockTags, rule: rule))

        // Adding an extra tag should NOT affect this rule
        let extraTagRule = TagRule(tags: ["Invoices", "ClientA"], matchType: "all", destination: "/mock/Documents/Invoices/ClientA")
        XCTAssertTrue(FileMover.matchesRule(tags: ["Invoices", "ClientA", "Urgent"], rule: extraTagRule))
    }

    func testMoveFileIfTagged_exclusiveRule() {
        let testFilePath = "/mock/Desktop/personal_notes.txt"
        let mockTags = ["Personal"] // Should trigger "exclusive" rule

        let rule = TagRule(tags: ["Personal"], matchType: "exclusive", destination: "/mock/Documents/Personal")
        XCTAssertTrue(FileMover.matchesRule(tags: mockTags, rule: rule))

        // If another tag is present, the exclusive rule should NOT match
        let extraTagRule = TagRule(tags: ["Personal"], matchType: "exclusive", destination: "/mock/Documents/Personal")
        XCTAssertFalse(FileMover.matchesRule(tags: ["Personal", "Work"], rule: extraTagRule))
    }

    func testMoveFileIfTagged_noMatchingRule() {
        let testFilePath = "/mock/Desktop/random_file.txt"
        let mockTags = ["RandomTag"] // No matching rule

        let rule = TagRule(tags: ["Invoices"], matchType: "any", destination: "/mock/Documents/Invoices")
        XCTAssertFalse(FileMover.matchesRule(tags: mockTags, rule: rule))
    }

    func testMoveFile_skipIfAlreadyExists() {
        let tempDir = FileManager.default.temporaryDirectory
        let testFilePath = tempDir.appendingPathComponent("invoice.pdf").path
        let mockDestination = tempDir.appendingPathComponent("Invoices/invoice.pdf").path

        // Ensure the test directory exists
        try? FileManager.default.createDirectory(atPath: tempDir.appendingPathComponent("Invoices").path,
                                                 withIntermediateDirectories: true, attributes: nil)

        // Ensure the test file exists before moving
        FileManager.default.createFile(atPath: testFilePath, contents: Data("Test content".utf8), attributes: nil)

        // Create a dummy file at the destination to simulate existing file
        FileManager.default.createFile(atPath: mockDestination, contents: Data("Existing file".utf8), attributes: nil)

        // Try moving the file (should detect existing file and skip)
        FileMover.moveFile(filePath: testFilePath, to: tempDir.appendingPathComponent("Invoices").path)

        // Verify that the source file still exists (move should be skipped)
        XCTAssertTrue(FileManager.default.fileExists(atPath: testFilePath), "Original file should still exist if move was skipped.")

        // Clean up mock files
        try? FileManager.default.removeItem(atPath: testFilePath)
        try? FileManager.default.removeItem(atPath: mockDestination)
    }
}
