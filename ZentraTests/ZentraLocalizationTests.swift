import XCTest
@testable import Zentra

final class ZentraLocalizationTests: XCTestCase {
    private let languageKey = "zentra.language"
    private var previousLanguage: String?

    override func setUp() {
        super.setUp()
        previousLanguage = UserDefaults.standard.string(forKey: languageKey)
    }

    override func tearDown() {
        if let previousLanguage {
            UserDefaults.standard.set(previousLanguage, forKey: languageKey)
        } else {
            UserDefaults.standard.removeObject(forKey: languageKey)
        }
        super.tearDown()
    }

    func testByteFormattingUsesSelectedLocaleWithoutSystemFormatterState() {
        UserDefaults.standard.set("en", forKey: languageKey)
        let english = ZentraLocalization.bytes(1_500_000)

        UserDefaults.standard.set("ar", forKey: languageKey)
        let arabic = ZentraLocalization.bytes(1_500_000)

        XCTAssertTrue(english.hasSuffix(" MB"))
        XCTAssertTrue(arabic.hasSuffix(" MB"))
        XCTAssertFalse(english.isEmpty)
        XCTAssertFalse(arabic.isEmpty)
    }

    func testMemoryFormattingUsesBinaryScale() {
        UserDefaults.standard.set("en", forKey: languageKey)
        XCTAssertEqual(ZentraLocalization.bytes(1024, style: .memory), "1 KB")
    }
}
