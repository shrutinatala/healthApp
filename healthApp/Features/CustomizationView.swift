//
//  CustomizationView.swift
//  Health_BLOCKFEATURE
//
//  Full SwiftUI settings screen for user customizations:
//  keywords, app lists, and custom categories.
//

import SwiftUI

// MARK: - Palette

private let sagePrimary = Color(red: 0.40, green: 0.63, blue: 0.47)
private let sageDeep    = Color(red: 0.22, green: 0.45, blue: 0.33)
private let creamBG     = Color(red: 0.97, green: 0.96, blue: 0.93)

// MARK: - Color+Hex

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8)  & 0xFF) / 255
        let b = Double(int         & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Preset category colors

private let presetCategoryColors: [String] = [
    "007AFF", "34C759", "FF3B30", "FF9500", "FFCC00",
    "5856D6", "AF52DE", "FF2D55", "00C7BE", "30B0C7"
]

// MARK: - Built-in categories (excluding .unknown)

private let editableCategories: [IntentCategory] =
    IntentCategory.allCases.filter { $0 != .unknown }

// MARK: - CustomizationView

/// Top-level settings sheet for customizing keywords, app lists, and custom categories.
struct CustomizationView: View {
    @ObservedObject var customizations: UserCustomizations
    @Environment(\.dismiss) private var dismiss

    @State private var showingCategoryCreator = false

    var body: some View {
        NavigationStack {
            List {
                keywordsSection
                appListsSection
                customCategoriesSection
            }
            .scrollContentBackground(.hidden)
            .background(creamBG)
            .navigationTitle("Customize")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                        .foregroundStyle(sagePrimary)
                }
            }
            .sheet(isPresented: $showingCategoryCreator) {
                CategoryCreatorView(customizations: customizations)
            }
        }
    }

    // MARK: Keywords Section

    private var keywordsSection: some View {
        Section {
            ForEach(editableCategories, id: \.rawValue) { category in
                NavigationLink {
                    KeywordEditorView(category: category, customizations: customizations)
                } label: {
                    categoryRow(
                        category: category,
                        detail: keywordCountLabel(for: category)
                    )
                }
            }
        } header: {
            sectionHeader("Keywords")
        }
    }

    // MARK: App Lists Section

    private var appListsSection: some View {
        Section {
            ForEach(editableCategories, id: \.rawValue) { category in
                NavigationLink {
                    AppEditorView(category: category, customizations: customizations)
                } label: {
                    categoryRow(
                        category: category,
                        detail: appCountLabel(for: category)
                    )
                }
            }
        } header: {
            sectionHeader("App Lists")
        }
    }

    // MARK: Custom Categories Section

    private var customCategoriesSection: some View {
        Section {
            ForEach(customizations.customCategories) { cat in
                HStack {
                    Circle()
                        .fill(Color(hex: cat.colorHex))
                        .frame(width: 12, height: 12)
                    Text(cat.name)
                        .font(.body)
                    Spacer()
                    Text("\(cat.keywords.count) kw · \(cat.apps.count) apps")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .onDelete { indexSet in
                customizations.customCategories.remove(atOffsets: indexSet)
            }

            Button {
                showingCategoryCreator = true
            } label: {
                Label("New Category", systemImage: "plus.circle.fill")
                    .foregroundStyle(sagePrimary)
            }
        } header: {
            sectionHeader("Custom Categories")
        }
    }

    // MARK: Helpers

    private func categoryRow(category: IntentCategory, detail: String) -> some View {
        HStack {
            Circle()
                .fill(category.badgeColor)
                .frame(width: 10, height: 10)
            Text(category.displayName)
                .font(.body)
            Spacer()
            Text(detail)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(sageDeep)
            .textCase(nil)
    }

    private func keywordCountLabel(for category: IntentCategory) -> String {
        let count = customizations.keywords(for: category).count
        return count == 0 ? "No custom keywords" : "\(count) custom keyword\(count == 1 ? "" : "s")"
    }

    private func appCountLabel(for category: IntentCategory) -> String {
        let count = customizations.apps(for: category).count
        return count == 0 ? "No custom apps" : "\(count) custom app\(count == 1 ? "" : "s")"
    }
}

// MARK: - KeywordEditorView

/// Lets the user add and remove extra keywords for a single built-in category.
struct KeywordEditorView: View {
    let category: IntentCategory
    @ObservedObject var customizations: UserCustomizations

    @State private var newKeyword: String = ""

    private var keywords: [String] {
        customizations.keywords(for: category)
    }

    var body: some View {
        List {
            Section {
                HStack {
                    TextField("Add keyword…", text: $newKeyword)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.done)
                        .onSubmit(commitKeyword)

                    Button("Add", action: commitKeyword)
                        .buttonStyle(.borderedProminent)
                        .tint(sagePrimary)
                        .disabled(newKeyword.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            } header: {
                Text("New Keyword")
            }

            if !keywords.isEmpty {
                Section {
                    ForEach(keywords, id: \.self) { keyword in
                        HStack {
                            Image(systemName: "tag.fill")
                                .foregroundStyle(category.badgeColor)
                                .font(.caption)
                            Text(keyword)
                                .font(.body)
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            customizations.removeKeyword(keywords[index], from: category)
                        }
                    }
                } header: {
                    Text("Custom Keywords (\(keywords.count))")
                }
            } else {
                Section {
                    Text("No custom keywords yet.")
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(creamBG)
        .navigationTitle("\(category.displayName) Keywords")
        .navigationBarTitleDisplayMode(.large)
    }

    private func commitKeyword() {
        customizations.addKeyword(newKeyword, to: category)
        newKeyword = ""
    }
}

// MARK: - AppEditorView

/// Lets the user add and remove custom app entries for a single built-in category.
struct AppEditorView: View {
    let category: IntentCategory
    @ObservedObject var customizations: UserCustomizations

    @State private var showingAddSheet = false

    private var apps: [CustomAppEntry] {
        customizations.apps(for: category)
    }

    var body: some View {
        List {
            if apps.isEmpty {
                Section {
                    Text("No custom apps yet.")
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                }
            } else {
                Section {
                    ForEach(apps) { app in
                        appRow(app)
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            customizations.removeApp(id: apps[index].id, from: category)
                        }
                    }
                } header: {
                    Text("Custom Apps (\(apps.count))")
                }
            }

            Section {
                Button {
                    showingAddSheet = true
                } label: {
                    Label("Add App", systemImage: "plus.circle.fill")
                        .foregroundStyle(sagePrimary)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(creamBG)
        .navigationTitle("\(category.displayName) Apps")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showingAddSheet) {
            AddAppSheet(category: category, customizations: customizations, isPresented: $showingAddSheet)
        }
    }

    private func appRow(_ app: CustomAppEntry) -> some View {
        HStack(spacing: 12) {
            Image(systemName: app.symbolName)
                .foregroundStyle(Color(hex: app.colorHex))
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(app.name)
                    .font(.body)
                Text(app.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if app.isBlockedEntry {
                Image(systemName: "lock.fill")
                    .foregroundStyle(.red)
                    .font(.caption)
            }
        }
    }
}

// MARK: - AddAppSheet

/// Sheet form for creating a new CustomAppEntry and adding it to a category.
struct AddAppSheet: View {
    let category: IntentCategory
    @ObservedObject var customizations: UserCustomizations
    @Binding var isPresented: Bool

    @State private var name: String = ""
    @State private var subtitle: String = ""
    @State private var symbolName: String = "app.fill"
    @State private var colorHex: String = presetCategoryColors[0]
    @State private var isBlocked: Bool = false

    private var canAdd: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("App Info") {
                    TextField("App Name", text: $name)
                    TextField("Subtitle", text: $subtitle)
                }

                Section("Icon") {
                    HStack {
                        TextField("SF Symbol name", text: $symbolName)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()

                        Spacer()

                        // Live symbol preview
                        Image(systemName: symbolName.isEmpty ? "app.fill" : symbolName)
                            .font(.title2)
                            .foregroundStyle(Color(hex: colorHex))
                            .frame(width: 36, height: 36)
                            .background(Color(hex: colorHex).opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    colorPicker
                }

                Section("Behavior") {
                    Toggle("Mark as Blocked", isOn: $isBlocked)
                        .tint(.red)
                }
            }
            .navigationTitle("Add App")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let entry = CustomAppEntry(
                            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                            subtitle: subtitle.trimmingCharacters(in: .whitespacesAndNewlines),
                            symbolName: symbolName.isEmpty ? "app.fill" : symbolName,
                            colorHex: colorHex,
                            isBlockedEntry: isBlocked
                        )
                        customizations.addApp(entry, to: category)
                        isPresented = false
                    }
                    .fontWeight(.semibold)
                    .disabled(!canAdd)
                }
            }
        }
    }

    private var colorPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(presetCategoryColors, id: \.self) { hex in
                    Circle()
                        .fill(Color(hex: hex))
                        .frame(width: 28, height: 28)
                        .overlay(
                            Circle()
                                .stroke(Color.primary, lineWidth: colorHex == hex ? 2.5 : 0)
                                .padding(2)
                        )
                        .onTapGesture { colorHex = hex }
                }
            }
            .padding(.vertical, 4)
        }
    }
}

// MARK: - CategoryCreatorView

/// Sheet for creating a fully custom IntentCategory with name, color, keywords, and apps.
struct CategoryCreatorView: View {
    @ObservedObject var customizations: UserCustomizations
    @Environment(\.dismiss) private var dismiss

    @State private var categoryName: String = ""
    @State private var selectedColorHex: String = presetCategoryColors[0]
    @State private var keywords: [String] = []
    @State private var newKeyword: String = ""
    @State private var apps: [CustomAppEntry] = []
    @State private var showingAddApp = false
    @State private var nameError: Bool = false

    private var canSave: Bool {
        !categoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                // MARK: Identity
                Section("Category Name") {
                    TextField("e.g. Side Projects", text: $categoryName)
                        .onChange(of: categoryName) { _, _ in nameError = false }

                    if nameError {
                        Text("Name cannot be empty.")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }

                // MARK: Color
                Section("Color") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(presetCategoryColors, id: \.self) { hex in
                                Circle()
                                    .fill(Color(hex: hex))
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.primary, lineWidth: selectedColorHex == hex ? 3 : 0)
                                            .padding(2)
                                    )
                                    .onTapGesture { selectedColorHex = hex }
                            }
                        }
                        .padding(.vertical, 6)
                    }
                }

                // MARK: Keywords
                Section("Keywords") {
                    HStack {
                        TextField("Add keyword…", text: $newKeyword)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .submitLabel(.done)
                            .onSubmit(commitKeyword)

                        Button("Add", action: commitKeyword)
                            .buttonStyle(.borderedProminent)
                            .tint(sagePrimary)
                            .disabled(newKeyword.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }

                    if keywords.isEmpty {
                        Text("No keywords yet.")
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                    } else {
                        ForEach(keywords, id: \.self) { kw in
                            HStack {
                                Image(systemName: "tag.fill")
                                    .foregroundStyle(Color(hex: selectedColorHex))
                                    .font(.caption)
                                Text(kw)
                            }
                        }
                        .onDelete { indexSet in
                            keywords.remove(atOffsets: indexSet)
                        }
                    }
                }

                // MARK: Apps
                Section("Apps") {
                    if apps.isEmpty {
                        Text("No apps yet.")
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                    } else {
                        ForEach(apps) { app in
                            HStack(spacing: 12) {
                                Image(systemName: app.symbolName)
                                    .foregroundStyle(Color(hex: app.colorHex))
                                    .frame(width: 24)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(app.name).font(.body)
                                    Text(app.subtitle).font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                if app.isBlockedEntry {
                                    Image(systemName: "lock.fill")
                                        .foregroundStyle(.red)
                                        .font(.caption)
                                }
                            }
                        }
                        .onDelete { indexSet in
                            apps.remove(atOffsets: indexSet)
                        }
                    }

                    Button {
                        showingAddApp = true
                    } label: {
                        Label("Add App", systemImage: "plus.circle.fill")
                            .foregroundStyle(sagePrimary)
                    }
                }
            }
            .navigationTitle("New Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveCategory() }
                        .fontWeight(.semibold)
                        .disabled(!canSave)
                }
            }
            .sheet(isPresented: $showingAddApp) {
                InlineAddAppSheet(apps: $apps, isPresented: $showingAddApp)
            }
        }
    }

    private func commitKeyword() {
        let trimmed = newKeyword.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty, !keywords.contains(trimmed) else {
            newKeyword = ""
            return
        }
        keywords.append(trimmed)
        newKeyword = ""
    }

    private func saveCategory() {
        let trimmedName = categoryName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            nameError = true
            return
        }
        let category = CustomCategory(
            name: trimmedName,
            colorHex: selectedColorHex,
            keywords: keywords,
            apps: apps
        )
        customizations.customCategories.append(category)
        dismiss()
    }
}

// MARK: - InlineAddAppSheet

/// A lightweight version of AddAppSheet used within CategoryCreatorView,
/// appending directly to the local apps binding rather than calling UserCustomizations.
struct InlineAddAppSheet: View {
    @Binding var apps: [CustomAppEntry]
    @Binding var isPresented: Bool

    @State private var name: String = ""
    @State private var subtitle: String = ""
    @State private var symbolName: String = "app.fill"
    @State private var colorHex: String = presetCategoryColors[0]
    @State private var isBlocked: Bool = false

    private var canAdd: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("App Info") {
                    TextField("App Name", text: $name)
                    TextField("Subtitle", text: $subtitle)
                }

                Section("Icon") {
                    HStack {
                        TextField("SF Symbol name", text: $symbolName)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()

                        Spacer()

                        Image(systemName: symbolName.isEmpty ? "app.fill" : symbolName)
                            .font(.title2)
                            .foregroundStyle(Color(hex: colorHex))
                            .frame(width: 36, height: 36)
                            .background(Color(hex: colorHex).opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(presetCategoryColors, id: \.self) { hex in
                                Circle()
                                    .fill(Color(hex: hex))
                                    .frame(width: 28, height: 28)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.primary, lineWidth: colorHex == hex ? 2.5 : 0)
                                            .padding(2)
                                    )
                                    .onTapGesture { colorHex = hex }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section("Behavior") {
                    Toggle("Mark as Blocked", isOn: $isBlocked)
                        .tint(.red)
                }
            }
            .navigationTitle("Add App")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let entry = CustomAppEntry(
                            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                            subtitle: subtitle.trimmingCharacters(in: .whitespacesAndNewlines),
                            symbolName: symbolName.isEmpty ? "app.fill" : symbolName,
                            colorHex: colorHex,
                            isBlockedEntry: isBlocked
                        )
                        apps.append(entry)
                        isPresented = false
                    }
                    .fontWeight(.semibold)
                    .disabled(!canAdd)
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("CustomizationView") {
    CustomizationView(customizations: UserCustomizations())
}

#Preview("KeywordEditorView") {
    NavigationStack {
        KeywordEditorView(category: .health, customizations: {
            let uc = UserCustomizations()
            uc.addKeyword("yoga", to: .health)
            uc.addKeyword("pilates", to: .health)
            return uc
        }())
    }
}

#Preview("AppEditorView") {
    NavigationStack {
        AppEditorView(category: .productivity, customizations: {
            let uc = UserCustomizations()
            uc.addApp(
                CustomAppEntry(
                    name: "Notion",
                    subtitle: "Notes & Docs",
                    symbolName: "square.and.pencil",
                    colorHex: "007AFF",
                    isBlockedEntry: false
                ),
                to: .productivity
            )
            return uc
        }())
    }
}

#Preview("CategoryCreatorView") {
    CategoryCreatorView(customizations: UserCustomizations())
}
