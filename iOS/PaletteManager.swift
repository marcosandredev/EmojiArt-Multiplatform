//
//  PaletteManager.swift
//  EmojiArt
//
//  Created by Marcos André Novaes de Lara on 18/04/22.
//

import SwiftUI

struct PaletteManager: View {
  @EnvironmentObject var store: PaletteStore
  
  // @Environment(\.colorScheme) var colorSchemme //Ex: .font(colorScheme == .dark ? .largeTitle : .caption) - Alterar a exibição conforme o tema
  
  // Ligação ao PresentationMode
  // o que nos permite descartar() se estivermos isPresented
  @Environment(\.presentationMode) var presentationMode
  
  // injetamos uma Ligação a isso no ambiente para a Lista e EditButton
  // Usar o \.editMode em EnvironmentValues
  @State private var editMode: EditMode = .inactive
  
  var body: some View {
    NavigationView {
      List {
        ForEach(store.palettes) { palette in
          // Tocar nesta linha na Lista navegará até um PaletteEditor
          // (Não subscrito pelo Identifiable)
          // (Veja o subscrito adicionado a RangeReplaceableCollection em UtilityExtensiosn)
          NavigationLink(destination: PaletteEditor(palette: $store.palettes[palette])) {
            VStack(alignment: .leading) {
              Text(palette.name)
              Text(palette.emojis)
            }
            // tocar quando NÃO estiver no editMode seguirá o NavigationLink
            // (é por isso que o gesto é definido como nulo nesse caso)
            .gesture(editMode == .active ? tap : nil)
          }
        }
        // ensine o ForEach a excluir itens
        // nos índices em indexSet a partir de sua matriz
        .onDelete { indexSet in
          store.palettes.remove(atOffsets: indexSet)
        }
        // ensine o ForEach a mover itens
        // nos índices em indexSet para um newOffset em sua matriz
        .onMove { indexSet, newOffset in
          store.palettes.move(fromOffsets: indexSet, toOffset: newOffset)
        }
      }
      .navigationTitle("Configurar Palettes")
      .navigationBarTitleDisplayMode(.inline)
      // adicione um EditButton no lado direito do nosso NavigationView
      // e um botão Fechar no lado da frente
      // observe que estamos adicionando este .toolbar à Lista
      // (não para o NavigationView)
      // (NavigationView analisa a visualização que está mostrando atualmente para obter informações da barra de ferramentas)
      // (o mesmo nome e titledisplaymode acima)
      .dismissable { presentationMode.wrappedValue.dismiss() }
      .toolbar {
        ToolbarItem { EditButton() }
      }
      .environment(\.editMode, $editMode)
    }
  }
  
  var tap: some Gesture {
    TapGesture().onEnded { }
  }
}

struct PaletteManager_Previews: PreviewProvider {
  static var previews: some View {
    PaletteManager()
      .previewDevice("iPhone 8")
      .environmentObject(PaletteStore(named: "Preview"))
      .preferredColorScheme(.light)
  }
}

