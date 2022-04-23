//
//  EmojiArtModel.swift
//  EmojiArt
//
//  Created by Marcos André Novaes de Lara on 16/04/22.
//
//  Model

import Foundation

struct EmojiArtModel: Codable {
  var background = Background.blank
  var emojis = [Emoji]()
  
  struct Emoji: Identifiable, Hashable, Codable {
    let text: String
    var x: Int // deslocados do centro
    var y: Int // deslocados do centro
    var size: Int
    var id: Int
    
    fileprivate init(text: String, x: Int, y: Int, size: Int, id: Int) { //Fileprivate significa que qualquer pessoa neste arquivo pode usar isso, e ninguém mais
      self.text = text
      self.x = x
      self.y = y
      self.size = size
      self.id = id
    }
  }
  
  func json() throws -> Data {
    return try JSONEncoder().encode(self)
  }
  
  init(json: Data) throws {
    self = try JSONDecoder().decode(EmojiArtModel.self, from: json)
  }
  
  init(url: URL) throws {
    let data = try Data(contentsOf: url)
    self = try EmojiArtModel(json: data)
  }
  
  init() {}
  
  private var uniqueEmojiId = 0
  
  mutating func addEmoji(_ text: String, at location: (x: Int, y: Int), size: Int)  {
    uniqueEmojiId += 1
    emojis.append(Emoji(text: text, x: location.x, y: location.y, size: size, id: uniqueEmojiId))
  }
}
