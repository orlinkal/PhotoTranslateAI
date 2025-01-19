import SwiftUI

struct MenuView: View {
    @State private var sourceLanguage = "Auto"
    @State private var targetLanguage = "English"
    @State private var showingSourceLanguages = false
    @State private var showingTargetLanguages = false
    @State private var recentSourceLanguages = ["English", "German", "Spanish"]  // Default recent sources
    @State private var recentTargetLanguages = ["English", "German", "Spanish"]  // Default recent targets
    
    let allLanguages = [
        "English", "Spanish", "French", "German", "Italian", 
        "Portuguese", "Russian", "Chinese", "Japanese", "Korean",
        "Arabic", "Hindi", "Bengali", "Dutch", "Greek",
        "Turkish", "Vietnamese", "Thai", "Indonesian"
    ]
    
    var sourceMenuItems: [String] {
        var items = ["Auto"]
        items.append(contentsOf: recentSourceLanguages)
        return items
    }
    
    private func updateRecentSources(with language: String) {
        if language == "Auto" { return }
        if !recentSourceLanguages.contains(language) {
            // Remove first item and add new language at the end
            recentSourceLanguages.removeFirst()
            recentSourceLanguages.append(language)
        }
    }
    
    private func updateRecentTargets(with language: String) {
        if !recentTargetLanguages.contains(language) {
            // Remove first item and add new language at the end
            recentTargetLanguages.removeFirst()
            recentTargetLanguages.append(language)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Source Language Section
            VStack(alignment: .leading, spacing: 0) {
                Text("From")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.horizontal)
                    .padding(.top)
                
                ForEach(sourceMenuItems, id: \.self) { language in
                    Button(action: { 
                        sourceLanguage = language
                        updateRecentSources(with: language)
                    }) {
                        HStack {
                            Text(language)
                                .foregroundColor(sourceLanguage == language ? .blue : .primary)
                            Spacer()
                            if sourceLanguage == language {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .padding(.horizontal)
                        .padding(.vertical, 12)
                    }
                }
                
                Button(action: { showingSourceLanguages = true }) {
                    HStack {
                        Text("More Languages...")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                }
            }
            .sheet(isPresented: $showingSourceLanguages) {
                NavigationView {
                    List {
                        ForEach(allLanguages.filter { !recentSourceLanguages.contains($0) }, id: \.self) { language in
                            Button(action: { 
                                sourceLanguage = language
                                updateRecentSources(with: language)
                                showingSourceLanguages = false
                            }) {
                                LanguageRow(language: language, isSelected: sourceLanguage == language)
                            }
                        }
                    }
                    .navigationTitle("Select Language")
                    .navigationBarItems(trailing: Button("Done") {
                        showingSourceLanguages = false
                    })
                }
            }
            
            Divider()
                .padding(.vertical, 8)
            
            // Target Language Section
            VStack(alignment: .leading, spacing: 0) {
                Text("To")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.horizontal)
                
                ForEach(recentTargetLanguages, id: \.self) { language in
                    Button(action: { 
                        targetLanguage = language
                        updateRecentTargets(with: language)
                    }) {
                        HStack {
                            Text(language)
                                .foregroundColor(targetLanguage == language ? .blue : .primary)
                            Spacer()
                            if targetLanguage == language {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .padding(.horizontal)
                        .padding(.vertical, 12)
                    }
                }
                
                Button(action: { showingTargetLanguages = true }) {
                    HStack {
                        Text("More Languages...")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                }
            }
            .sheet(isPresented: $showingTargetLanguages) {
                NavigationView {
                    List {
                        ForEach(allLanguages.filter { !recentTargetLanguages.contains($0) }, id: \.self) { language in
                            Button(action: { 
                                targetLanguage = language
                                updateRecentTargets(with: language)
                                showingTargetLanguages = false
                            }) {
                                LanguageRow(language: language, isSelected: targetLanguage == language)
                            }
                        }
                    }
                    .navigationTitle("Select Language")
                    .navigationBarItems(trailing: Button("Done") {
                        showingTargetLanguages = false
                    })
                }
            }
            
            Spacer()
        }
        .background(Color(.systemBackground))
    }
}

struct LanguageRow: View {
    let language: String
    let isSelected: Bool
    
    var body: some View {
        HStack {
            Text(language)
                .foregroundColor(isSelected ? .blue : .primary)
            Spacer()
            if isSelected {
                Image(systemName: "checkmark")
                    .foregroundColor(.blue)
            }
        }
    }
}

struct MenuView_Previews: PreviewProvider {
    static var previews: some View {
        MenuView()
    }
} 