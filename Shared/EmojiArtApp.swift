//
//  EmojiArtApp.swift
//  Shared
//
//  Created by Marcos André Novaes de Lara on 23/04/22.
//

import SwiftUI

@main
struct EmojiArtApp: App {
  @StateObject var paletteStore = PaletteStore(named: "Default")
  
  var body: some Scene {
    DocumentGroup(newDocument: {EmojiArtDocument()}) { config in
      EmojiArtDocumentView(document: config.document)
        .environmentObject(paletteStore) // Usar em todas as telas
    }
  }
}
