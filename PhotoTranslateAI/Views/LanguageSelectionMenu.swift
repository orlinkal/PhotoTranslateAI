import SwiftUI

struct LanguageSelectionMenu: View {
    @Binding var isShowing: Bool
    @Binding var sourceLanguage: Language
    @Binding var targetLanguage: Language
    @StateObject private var languageManager = LanguageManager()
    @State private var showingAllSourceLanguages = false
    @State private var showingAllTargetLanguages = false
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Languages")
                        .font(.title)
                        .bold()
                        .padding(.top, 40)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("From:")
                            .font(.headline)
                        
                        ScrollView {
                            VStack(spacing: 0) {
                                // Auto-detect is always first
                                LanguageButton(
                                    language: .autoDetect,
                                    isSelected: sourceLanguage == .autoDetect
                                ) {
                                    sourceLanguage = .autoDetect
                                }
                                
                                // Recent languages
                                ForEach(languageManager.recentSourceLanguages) { language in
                                    LanguageButton(
                                        language: language,
                                        isSelected: sourceLanguage == language
                                    ) {
                                        sourceLanguage = language
                                        languageManager.updateRecentSource(language)
                                    }
                                }
                                
                                // More button
                                Button(action: {
                                    showingAllSourceLanguages.toggle()
                                }) {
                                    HStack {
                                        Text("More Languages...")
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                    }
                                    .padding(.vertical, 8)
                                }
                                .foregroundColor(.blue)
                            }
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("To:")
                            .font(.headline)
                        
                        ScrollView {
                            VStack(spacing: 0) {
                                // Recent target languages
                                ForEach(languageManager.recentTargetLanguages) { language in
                                    LanguageButton(
                                        language: language,
                                        isSelected: targetLanguage == language
                                    ) {
                                        targetLanguage = language
                                        languageManager.updateRecentTarget(language)
                                    }
                                }
                                
                                // More button
                                Button(action: {
                                    showingAllTargetLanguages.toggle()
                                }) {
                                    HStack {
                                        Text("More Languages...")
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                    }
                                    .padding(.vertical, 8)
                                }
                                .foregroundColor(.blue)
                            }
                        }
                    }
                    
                    Spacer()
                }
                .padding()
                .frame(width: min(geometry.size.width * 0.85, 300))
                .background(Color(.systemBackground))
                .offset(x: isShowing ? 0 : -geometry.size.width)
                .animation(.default, value: isShowing)
                
                Spacer()
            }
            .background(
                Color.black.opacity(isShowing ? 0.5 : 0)
                    .ignoresSafeArea()
                    .onTapGesture {
                        isShowing = false
                    }
            )
        }
        .ignoresSafeArea()
        .sheet(isPresented: $showingAllSourceLanguages) {
            AllLanguagesView(
                selectedLanguage: $sourceLanguage,
                languages: Language.allLanguages,
                onSelect: { language in
                    languageManager.updateRecentSource(language)
                    showingAllSourceLanguages = false
                }
            )
        }
        .sheet(isPresented: $showingAllTargetLanguages) {
            AllLanguagesView(
                selectedLanguage: $targetLanguage,
                languages: Language.allLanguages.filter { $0.code != "auto" },
                onSelect: { language in
                    languageManager.updateRecentTarget(language)
                    showingAllTargetLanguages = false
                }
            )
        }
    }
}

struct LanguageButton: View {
    let language: Language
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(language.name)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.blue)
                }
            }
            .padding(.vertical, 8)
        }
        .foregroundColor(.primary)
    }
}

struct AllLanguagesView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedLanguage: Language
    let languages: [Language]
    let onSelect: (Language) -> Void
    
    var body: some View {
        NavigationView {
            List(languages) { language in
                Button(action: {
                    selectedLanguage = language
                    onSelect(language)
                }) {
                    HStack {
                        Text(language.name)
                        Spacer()
                        if selectedLanguage == language {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
                .foregroundColor(.primary)
            }
            .navigationTitle("All Languages")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
} 