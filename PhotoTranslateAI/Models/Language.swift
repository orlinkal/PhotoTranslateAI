import Foundation

struct Language: Identifiable, Equatable {
    let id = UUID()
    let code: String
    let name: String
    
    static let autoDetect = Language(code: "auto", name: "Auto Detect")
    static let english = Language(code: "en", name: "English")
    static let german = Language(code: "de", name: "German")
    static let spanish = Language(code: "es", name: "Spanish")
    static let bulgarian = Language(code: "bg", name: "Bulgarian")
    
    static let allLanguages: [Language] = [
        autoDetect,
        english,
        german,
        spanish,
        bulgarian,
        Language(code: "fr", name: "French"),
        Language(code: "it", name: "Italian"),
        Language(code: "pt", name: "Portuguese"),
        Language(code: "ru", name: "Russian"),
        Language(code: "zh", name: "Chinese"),
        Language(code: "ja", name: "Japanese"),
        Language(code: "ko", name: "Korean")
    ]
} 