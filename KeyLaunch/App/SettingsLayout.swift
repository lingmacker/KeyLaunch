import KeyboardShortcuts
import SwiftUI

extension KeyboardShortcuts.Name {
    static let row1 = Self("launch-row-1")
    static let row2 = Self("launch-row-2")
    static let row3 = Self("launch-row-3")
    static let row4 = Self("launch-row-4")
    static let row5 = Self("launch-row-5")
    static let row6 = Self("launch-row-6")
    static let row7 = Self("launch-row-7")
    static let row8 = Self("launch-row-8")
    static let row9 = Self("launch-row-9")
    static let row10 = Self("launch-row-10")
}

let shortcutNames: [KeyboardShortcuts.Name] = [
    .row1, .row2, .row3, .row4, .row5, .row6, .row7, .row8, .row9, .row10
]

enum SettingsLayout {
    static let shortcutColumnWidth: CGFloat = 176
    static let shortcutRecorderWidth: CGFloat = 140
    static let actionColumnWidth: CGFloat = 36
    static let rowHorizontalSpacing: CGFloat = 20
    static let panelCornerRadius: CGFloat = 12
    static let contentPadding: CGFloat = 20
    static let rowMinHeight: CGFloat = 52
}
