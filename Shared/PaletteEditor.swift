//
//  PaletteEditor.swift
//  EmojiArt
//
//  Created by Marcos André Novaes de Lara on 18/04/22.
//

import SwiftUI

struct PaletteEditor: View {
  @Binding var palette: Palette
  
  var body: some View {
    Form {
      nameSection
      addEmojisSection
      removeEmojiSection
    }
    .navigationTitle("Editar \(palette.name)")
    .frame(minWidth: 300, minHeight: 350)
  }
  
  var nameSection: some View {
    Section(header: Text("Nome")) {
      TextField("Nome", text: $palette.name) // $ vincula a variavel
    }
  }
  
  @State private var emojisToAdd = ""
  
  var addEmojisSection: some View {
    Section(header: Text("Adicionar Emojis")) {
      TextField("", text: $emojisToAdd)
        .onChange(of: emojisToAdd) { emojis in
          addEmojis(emojis)
        }
    }
  }
  
  func addEmojis(_ emojis: String) {
    withAnimation {
      palette.emojis = (emojis + palette.emojis)
        .filter { $0.isEmoji }
        .removingDuplicateCharacters
    }
  }
  
  var removeEmojiSection: some View {
    Section(header: Text("Remover Emojis")) {
      let emojis = palette.emojis.removingDuplicateCharacters.map { String($0) }
      LazyVGrid(columns: [GridItem(.adaptive(minimum: 40))]) {
        ForEach(emojis, id: \.self) { emoji in
          Text(emoji)
            .onTapGesture {
              withAnimation {
                palette.emojis.removeAll(where: { String($0) == emoji })
              }
            }
        }
      }
      .font(.system(size: 40))
    }
  }
}

struct PaletteEditor_Previews: PreviewProvider {
  static var previews: some View {
    PaletteEditor(palette: .constant(PaletteStore(named: "Preview").palette(at: 4)))
      .previewLayout(.fixed(width: 300, height: 350))
    PaletteEditor(palette: .constant(PaletteStore(named: "Preview").palette(at: 2)))
      .previewLayout(.fixed(width: 300, height: 600))
  }
}
