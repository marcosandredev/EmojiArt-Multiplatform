//
//  EmojiArtApp.swift
//  Shared
//
//  Created by Marcos André Novaes de Lara on 23/04/22.
//

import SwiftUI

@main
struct EmojiArtApp: App {
    var body: some Scene {
        DocumentGroup(newDocument: EmojiArtDocument()) { file in
            ContentView(document: file.$document)
        }
    }
}
