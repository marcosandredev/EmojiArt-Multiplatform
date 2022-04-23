//
//  File.swift
//  EmojiArt (iOS)
//
//  Created by Marcos André Novaes de Lara on 23/04/22.
//

import SwiftUI

extension UIImage {
  var imageData: Data? {jpegData(compressionQuality: 1.0)}
}

struct Pasteboard {
  static var imageData: Data? {
    UIPasteboard.general.image?.imageData
  }
  static var imageURL: URL? {
    UIPasteboard.general.url?.imageURL
  }
}

extension View {
  @ViewBuilder // Sempre que tiver alguma função que retorna alguma view que pode ser de dois tipos diferentes, ela tem que ser ViewBuilder
  func wrappedInNavigationViewToMakeDismissable(_ dismiss: (() -> Void)?) -> some View {
    if UIDevice.current.userInterfaceIdiom != .pad, let dismiss = dismiss { // Verificar o dispostivo, nesse caso, tem que ser diferente de ipad
      NavigationView {
        self
          .navigationBarTitleDisplayMode(.inline)
          .dismissable(dismiss)
      }
      .navigationViewStyle(StackNavigationViewStyle()) // Empilhar as visualizações umas sobre as outras, nunca fazer uma apresentação lado a lado
    } else {
      self
    }
  }
  
  @ViewBuilder
  func dismissable(_ dismiss: (() -> Void)?) -> some View {
    if UIDevice.current.userInterfaceIdiom != .pad, let dismiss = dismiss {
      self.toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Fechar"){
            dismiss()
          }
        }
      }
    } else {
      self
    }
  }
  
  func paletteControlButtonStyle() -> some View {
    self
  }
  
  func popoverPadding() -> some View {
    self
  }
}
