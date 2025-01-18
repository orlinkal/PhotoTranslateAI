import Foundation

struct Language: Identifiable, Hashable, Codable {
    var id: UUID
    let name: String
    let code: String
    
    init(id: UUID = UUID(), name: String, code: String) {
        self.id = id
        self.name = name
        self.code = code
    }
    
    static let autoDetect = Language(name: "Auto Detect", code: "auto")
    static let english = Language(name: "English", code: "en")
    static let german = Language(name: "German", code: "de")
    static let spanish = Language(name: "Spanish", code: "es")
    static let bulgarian = Language(name: "Bulgarian", code: "bg")
    static let french = Language(name: "French", code: "fr")
    static let italian = Language(name: "Italian", code: "it")
    static let portuguese = Language(name: "Portuguese", code: "pt")
    static let russian = Language(name: "Russian", code: "ru")
    static let chinese = Language(name: "Chinese", code: "zh")
    static let japanese = Language(name: "Japanese", code: "ja")
    static let korean = Language(name: "Korean", code: "ko")
    // Add more languages as needed
    
    static let allLanguages: [Language] = [
        autoDetect, english, german, spanish, bulgarian, french, italian,
        portuguese, russian, chinese, japanese, korean
    ]
} 