import Foundation

class LanguageManager: ObservableObject {
    @Published var recentSourceLanguages: [Language] = []
    @Published var recentTargetLanguages: [Language] = []
    
    private let defaultLanguages = [
        Language.english,
        Language.german,
        Language.spanish
    ]
    
    init() {
        // Initialize with default languages
        recentSourceLanguages = [
            Language.autoDetect
        ] + defaultLanguages
        
        recentTargetLanguages = defaultLanguages
    }
    
    func updateRecentSource(_ language: Language) {
        guard language != .autoDetect else { return }
        
        // If the language is already in the recent list, just update selection
        if recentSourceLanguages.contains(language) {
            return
        }
        
        // Keep Auto Detect at index 0
        var updatedList = recentSourceLanguages
        
        // Remove the last language (keeping Auto Detect)
        if updatedList.count > 1 {
            updatedList.removeLast()
        }
        
        // Add the new language after Auto Detect
        updatedList.insert(language, at: 1)
        
        recentSourceLanguages = updatedList
    }
    
    func updateRecentTarget(_ language: Language) {
        // If the language is already in the recent list, just update selection
        if recentTargetLanguages.contains(language) {
            return
        }
        
        // Remove the last language
        if recentTargetLanguages.count >= 3 {
            recentTargetLanguages.removeLast()
        }
        
        // Add the new language at the beginning
        recentTargetLanguages.insert(language, at: 0)
    }
    
    // Get remaining languages for "More options"
    func getRemainingSourceLanguages() -> [Language] {
        let allLanguages = Language.allLanguages.filter { $0 != .autoDetect }
        return allLanguages.filter { language in
            !recentSourceLanguages.contains(language)
        }
    }
    
    func getRemainingTargetLanguages() -> [Language] {
        return Language.allLanguages
            .filter { $0 != .autoDetect }
            .filter { language in
                !recentTargetLanguages.contains(language)
            }
    }
} 