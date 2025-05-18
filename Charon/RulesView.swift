//
//  RulesView.swift
//  Charon
//
//  Created by Zachary Bonner on 3/8/25.
//

import SwiftUI

struct RulesView: View {
    @State private var rules: [TagRule] = RuleManager.loadRules()
    @State private var newTags: String = ""
    @State private var newMatchType: String = "any"
    @State private var newDestination: String = ""
    @State private var editingIndex: Int? = nil
    @State private var showingHelp = false // State to control help popup

    var body: some View {
        VStack {
            HStack {
                Text("📂 File Tag Rules").font(.title).padding()
                Spacer()
                Button(action: { showingHelp.toggle() }) {
                    Image(systemName: "questionmark.circle")
                        .font(.title2)
                        .help("Click for help configuring rules")
                }
                .padding()
                .popover(isPresented: $showingHelp) {
                    HelpView()
                        .frame(width: 300, height: 200)
                        .padding()
                }
            }

            List {
                ForEach(rules.indices, id: \.self) { index in
                    VStack(alignment: .leading) {
                        Text("Tags: \(rules[index].tags.joined(separator: ", "))")
                        Text("Match Type: \(rules[index].matchType)").font(.subheadline).foregroundColor(.gray)
                        Text("Destination: \(rules[index].destination)").font(.subheadline)

                        HStack {
                            Button("✏️ Edit") {
                                editRule(at: index)
                            }
                            .buttonStyle(BorderlessButtonStyle())

                            Button("🗑 Delete") {
                                deleteRule(at: index)
                            }
                            .buttonStyle(BorderlessButtonStyle())
                            .foregroundColor(.red)
                        }
                    }
                    .padding()
                }
            }
            Divider()
            ruleForm
        }
        .onAppear { loadRules() }
    }

    var ruleForm: some View {
        Form {
            Section(header: Text(editingIndex == nil ? "Add New Rule" : "Edit Rule")) {
                TextField("Tags (comma-separated)", text: $newTags)
                Picker("Match Type", selection: $newMatchType) {
                    Text("Any").tag("any")
                    Text("All").tag("all")
                    Text("Exclusive").tag("exclusive")
                }
                .pickerStyle(SegmentedPickerStyle())

                TextField("Destination Path", text: $newDestination)

                Button(editingIndex == nil ? "➕ Add Rule" : "💾 Save Changes") {
                    if let index = editingIndex {
                        updateRule(at: index)
                    } else {
                        addRule()
                    }
                }
                .disabled(newTags.isEmpty || newDestination.isEmpty)
            }
        }
        .padding()
    }
    
    private func loadRules() {
        rules = RuleManager.loadRules()
    }

    private func addRule() {
        let tagsArray = newTags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        let newRule = TagRule(tags: tagsArray, matchType: newMatchType, destination: newDestination)
        rules.append(newRule)
        saveRules()
        resetForm()
    }

    private func editRule(at index: Int) {
        let rule = rules[index]
        newTags = rule.tags.joined(separator: ", ")
        newMatchType = rule.matchType
        newDestination = rule.destination
        editingIndex = index
    }

    private func updateRule(at index: Int) {
        let tagsArray = newTags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        rules[index] = TagRule(tags: tagsArray, matchType: newMatchType, destination: newDestination)
        saveRules()
        resetForm()
    }

    private func deleteRule(at index: Int) {
        rules.remove(at: index)
        saveRules()
    }

    private func saveRules() {
        RuleEditor.saveRules(rules)
        loadRules()
    }

    private func resetForm() {
        newTags = ""
        newMatchType = "any"
        newDestination = ""
        editingIndex = nil
    }
}

struct HelpView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("📖 How to Configure Rules").font(.headline)
            Text("""
            **Any**: If any of the listed tags match, the file is moved.
            
            **All**: Only move the file if it contains ALL the specified tags.
            
            **Exclusive**: The file is moved ONLY if it has exactly these tags and no others.
            """).font(.body)
            Spacer()
        }
    }
}

#Preview {
    RulesView()
}
