import Foundation

class LanguageManager: ObservableObject {
    @Published var recentSourceLanguages: [Language]
    @Published var recentTargetLanguages: [Language]
    
    private let sourceKey = "recentSourceLanguages"
    private let targetKey = "recentTargetLanguages"
    
    init() {
        // Initialize with default languages
        self.recentSourceLanguages = [Language.english, Language.german, Language.spanish]
        self.recentTargetLanguages = [Language.english, Language.german, Language.spanish]
        
        // Load saved recent languages if they exist
        if let savedSource = UserDefaults.standard.data(forKey: sourceKey),
           let decodedSource = try? JSONDecoder().decode([Language].self, from: savedSource) {
            self.recentSourceLanguages = decodedSource
        }
        
        if let savedTarget = UserDefaults.standard.data(forKey: targetKey),
           let decodedTarget = try? JSONDecoder().decode([Language].self, from: savedTarget) {
            self.recentTargetLanguages = decodedTarget
        }
    }
    
    func updateRecentSource(_ language: Language) {
        if language.code == "auto" { return }
        recentSourceLanguages.removeAll { $0 == language }
        recentSourceLanguages.insert(language, at: 0)
        while recentSourceLanguages.count > 3 {
            recentSourceLanguages.removeLast()
        }
        saveRecents()
    }
    
    func updateRecentTarget(_ language: Language) {
        recentTargetLanguages.removeAll { $0 == language }
        recentTargetLanguages.insert(language, at: 0)
        while recentTargetLanguages.count > 3 {
            recentTargetLanguages.removeLast()
        }
        saveRecents()
    }
    
    private func saveRecents() {
        if let encoded = try? JSONEncoder().encode(recentSourceLanguages) {
            UserDefaults.standard.set(encoded, forKey: sourceKey)
        }
        if let encoded = try? JSONEncoder().encode(recentTargetLanguages) {
            UserDefaults.standard.set(encoded, forKey: targetKey)
        }
    }
} 