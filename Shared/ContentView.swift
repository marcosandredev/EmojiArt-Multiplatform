//
//  ContentView.swift
//  Shared
//
//  Created by Marcos André Novaes de Lara on 23/04/22.
//

import SwiftUI

struct ContentView: View {
    @Binding var document: EmojiArtDocument

    var body: some View {
        TextEditor(text: $document.text)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(document: .constant(EmojiArtDocument()))
    }
}
