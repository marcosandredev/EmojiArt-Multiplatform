//
//  EmojiArtDocumentView.swift
//  EmojiArt
//
//  Created by Marcos André Novaes de Lara on 16/04/22.
//

import SwiftUI

struct EmojiArtDocumentView: View {
  @ObservedObject var document: EmojiArtDocument
  
  @Environment(\.undoManager) var undoManager
  
  @ScaledMetric var defaultEmojiFontSize: CGFloat = 40 // Permite a alteração de um tamanho que antes era fixo com let, para aumentar com acessibilidade, por exemplo
  
  var body: some View {
    VStack(spacing:0) {
      documentBody
      PaletteChooser(emojiFontSize: defaultEmojiFontSize)
    }
  }
  
  var documentBody: some View {
    GeometryReader{
      geometry in
      ZStack {
        Color.white
        OptionalImage(uiImage: document.backgroundImage)
          .scaleEffect(zoomScale)
          .position(convertFromEmojiCoordinates((0,0), in: geometry))
          .gesture(doubleTapToZoom(in: geometry.size))
        
        if document.backgroundImageFetchStatus == .fetching {
          ProgressView().scaleEffect(3)
        } else {
          ForEach(document.emojis) {
            emoji in Text(emoji.text)
              .font(.system(size: fontSize(for: emoji)))
              .scaleEffect(zoomScale)
              .position(position(for: emoji, in: geometry))
          }
        }
      }
      .clipped()
      .onDrop(of: [.utf8PlainText, .url, .image], isTargeted: nil) {
        providers, location in drop(providers: providers, at: location, in: geometry)
      }
      .gesture(panGesture().simultaneously(with: zoomGesture())) // Utilizar simultaneously quando for usar mais de um gesto na mesma View e quer eles simultaneamente
      .alert(item: $alertToShow) { alertToShow in
          // return Alert
        alertToShow.alert()
      }
        // Status de busca alerta o usuário se a busca falhar
      .onChange(of: document.backgroundImageFetchStatus) { status in
        switch status {
          case .failed(let url):
            showBackgroundImageFetchFailedAlert(url)
          default:
            break
        }
      }
      .onReceive(document.$backgroundImage) { image in
        if autozoom {
          zoomToFit(image, in: geometry.size)
        }
      }
      .compactableToolbar {
        AnimatedActionButton(title: "Colar", systemImage: "doc.on.clipboard") {
          pasteBackground()
        }
        if Camera.isAvailable {
          AnimatedActionButton(title: "Camera", systemImage: "camera") {
            backgroundPicker = .camera
          }
        }
        if PhotoLibrary.isAvailable {
          AnimatedActionButton(title: "Buscar Foto", systemImage: "photo") {
            backgroundPicker = .library
          }
        }
        #if os(iOS)
        if let undoManager = undoManager {
          if undoManager.canUndo {
            AnimatedActionButton(title: undoManager.undoActionName, systemImage:"arrow.uturn.backward") {
              undoManager.undo()
            }
          }
          if undoManager.canRedo {
            AnimatedActionButton(title: undoManager.redoActionName, systemImage:"arrow.uturn.forward") {
              undoManager.redo()
            }
          }
        }
        #endif
      }
      .sheet(item: $backgroundPicker) {
        pickerType in
        switch pickerType {
          case .camera: Camera(handlePickedImage: {image in handlePickedBackgroundImage(image)})
          case .library: PhotoLibrary(handlePickedImage: {image in handlePickedBackgroundImage(image)})
        }
      }
    }
  }
  
  private func handlePickedBackgroundImage(_ image: UIImage?) {
    autozoom = true
    if let imageData = image?.imageData {
      document.setBackground(.imageData(imageData), undoManager: undoManager)
    }
    backgroundPicker = nil
  }
  
  @State private var backgroundPicker: BackgroundPickerType?
  
  enum BackgroundPickerType: String, Identifiable {
    case camera
    case library
    var id: String {rawValue}
  }
  
  private func pasteBackground() {
    autozoom = true
    if let imageData = Pasteboard.imageData {
      document.setBackground(.imageData(imageData), undoManager: undoManager)
    } else if let url = Pasteboard.imageURL {
      document.setBackground(.url(url), undoManager: undoManager)
    } else {
      alertToShow = IdentifiableAlert(
        title: "Colar",
        message: "Não há imagem no pasteboard"
      )
    }
  }
  
  @State private var autozoom = false
  
  // Estado que diz se um determinado alerta identificável deve ser exibido
  @State private var alertToShow: IdentifiableAlert?
  
  // Define alertToShow para um Alerta Identificável explicando uma falha de busca de URL
  private func showBackgroundImageFetchFailedAlert(_ url: URL) {
    alertToShow = IdentifiableAlert(id: "fetch failed: " + url.absoluteString, alert: {
      Alert(
        title: Text("Background Image Fetch"),
        message: Text("Couldn't load image from \(url)."),
        dismissButton: .default(Text("OK"))
      )
    })
  }
  
  // MARK: - Drag and Drop
  
  private func drop(providers: [NSItemProvider], at location: CGPoint, in geometry: GeometryProxy) -> Bool {
    var found = providers.loadObjects(ofType: URL.self) {url in
      autozoom = true
      document.setBackground(.url(url.imageURL), undoManager: undoManager)
    }
    #if os(iOS)
    if !found {
      found = providers.loadObjects(ofType: UIImage.self) {
        image in if let data = image.jpegData(compressionQuality: 1.0) { // Imagem sem perda
          autozoom = true
          document.setBackground(.imageData(data), undoManager: undoManager)
        }
      }
    }
    #endif
    if !found {
      found = providers.loadObjects(ofType: String.self) {
        string in
        if let emoji = string.first, emoji.isEmoji {
          document.addEmoji(
            String(emoji),
            at: convertToEmojiCoordinates(location, in: geometry),
            size: defaultEmojiFontSize / zoomScale, undoManager: undoManager)
        }
      }
    }
    return found
  }
  
  // MARK: - Positioning/Sizing Emoji
  
  private func position(for emoji: EmojiArtModel.Emoji, in geometry: GeometryProxy) -> CGPoint {
    convertFromEmojiCoordinates((emoji.x, emoji.y), in: geometry)
  }
  
  private func fontSize(for emoji: EmojiArtModel.Emoji) -> CGFloat {
    CGFloat(emoji.size)
  }
  
  private func convertToEmojiCoordinates(_ location: CGPoint, in geometry: GeometryProxy) -> (x: Int, y: Int) {
    let center = geometry.frame(in: .local).center
    let location = CGPoint(
      x: (location.x - panOffset.width - center.x) / zoomScale
     ,y: (location.y - panOffset.height - center.y)) / zoomScale
    return(Int(location.x), Int(location.y))
  }
  
  private func convertFromEmojiCoordinates(_ location: (x: Int, y: Int), in geometry: GeometryProxy) -> CGPoint {
    let center = geometry.frame(in: .local).center
    
    return CGPoint(
      x: center.x + CGFloat(location.x) * zoomScale + panOffset.width
     ,y: center.y + CGFloat(location.y) * zoomScale + panOffset.height
    )
  }
  
  // MARK: - Zooming
  
  @SceneStorage("EmojiArtDocumentView.steadyStateZoomScale")
  private var steadyStateZoomScale: CGFloat = 1
  @GestureState private var gestureZoomScale: CGFloat = 1 // Apenas enquanto o gesto estiver acontecendo
  
  private var zoomScale: CGFloat {
    steadyStateZoomScale * gestureZoomScale
  }
  
  private func zoomGesture() -> some Gesture {
    MagnificationGesture()
      .updating($gestureZoomScale) {
        latestGestureScale, gestureZoomScale, _ in
        gestureZoomScale = latestGestureScale
      }
      .onEnded {
        gestureScaleAtEnd in steadyStateZoomScale *= gestureScaleAtEnd
      }
  }
  
  private func doubleTapToZoom(in size: CGSize) -> some Gesture {
    TapGesture(count: 2)
      .onEnded {
        withAnimation {
          zoomToFit(document.backgroundImage, in: size)
        }
      }
  }
  
  private func zoomToFit(_ image: UIImage?, in size: CGSize) {
    if let image = image, image.size.width > 0, image.size.height > 0, size.width > 0, size.height > 0 {
      let hZoom = size.width / image.size.width
      let vZoom = size.height / image.size.height
      steadyStatePanOffset = .zero
      steadyStateZoomScale = min(hZoom, vZoom)
    }
  }
  
  // MARK: - Panning
  
  @SceneStorage("EmojiArtDocumentView.steadyStatePanOffset")
  private var steadyStatePanOffset: CGSize = CGSize.zero
  @GestureState private var gesturePanOffset: CGSize = CGSize.zero // Apenas enquanto o gesto estiver acontecendo
  
  private var panOffset: CGSize {
    (steadyStatePanOffset + gesturePanOffset) * zoomScale
  }
  
  private func panGesture() -> some Gesture {
    DragGesture()
      .updating($gesturePanOffset) {
        latestDragGestureValue, gesturePanOffset, _ in
        gesturePanOffset = latestDragGestureValue.translation / zoomScale
      }
      .onEnded {
        finalDragGestureValue in
        steadyStatePanOffset = steadyStatePanOffset + (finalDragGestureValue.translation / zoomScale)
      }
  }
  
}















struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        EmojiArtDocumentView(document: EmojiArtDocument())
    }
}
