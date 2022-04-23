//
//  UtilityExtensions.swift
//  EmojiArt
//
//  Created by CS193p Instructor on 4/26/21.
//  Copyright © 2021 Stanford University. All rights reserved.
//

import SwiftUI

// em uma Coleção de Identificáveis
// muitas vezes podemos querer encontrar o elemento que tenha o mesmo ID
// como identificável que já temos em mãos
// nomeamos este índice(correspondência:) em vez de firstIndex(correspondência:)
// porque assumimos que alguém está criando uma Coleção de Identificáveis
// geralmente terá apenas uma de cada coisa identificável lá dentro
// (embora não haja nada que os impeça de fazê-lo; é apenas uma escolha de nomeação)

extension Collection where Element: Identifiable {
    func index(matching element: Element) -> Self.Index? {
        firstIndex(where: { $0.id == element.id })
    }
}

// poderíamos fazer a mesma coisa quando se trata de remover um elemento
// mas temos que adicionar isso a um protocolo diferente
// porque a Coleção funciona para coleções imutáveis de coisas
// o "mutável" é RangeReplaceableCollection
// não só poderíamos adicionar remover
// mas poderíamos adicionar um subscrito que tira uma cópia de um dos elementos
// e usa sua identidade para se inscrever na Coleção
// esta é uma maneira incrível de criar Ligações em uma Matriz em um ViewModel
// (já que qualquer var publicado em um ObservableObject pode ser vinculado a via $)
// (mesmo vars nessa var publicada ou subscritos nessa var)
// (ou subscritos em vars nesse var, etc.)

extension RangeReplaceableCollection where Element: Identifiable {
    mutating func remove(_ element: Element) {
        if let index = index(matching: element) {
            remove(at: index)
        }
    }

    subscript(_ element: Element) -> Element {
        get {
            if let index = index(matching: element) {
                return self[index]
            } else {
                return element
            }
        }
        set {
            if let index = index(matching: element) {
                replaceSubrange(index...index, with: [newValue])
            }
        }
    }
}

// se você usar um Conjunto para representar a seleção de emoji em HW5
// então você pode achar que essa função de açúcar sintático é útil

extension Set where Element: Identifiable {
    mutating func toggleMembership(of element: Element) {
        if let index = index(matching: element) {
            remove(at: index)
        } else {
            insert(element)
        }
    }
}

// algumas extensões para String e Character
// para nos ajudar a gerenciar nossas Cadeias de emojis
// queremos que eles sejam "somente emoji"
// (assim é Emoji abaixo)
// e não queremos que eles tenham emojis repetidos
// (assim, com NoRepeatedCharacters abaixo)

extension String {
  var removingDuplicateCharacters: String {
    reduce(into: "") { sofar, element in
      if !sofar.contains(element) {
        sofar.append(element)
      }
    }
  }
}

extension Character {
    var isEmoji: Bool {
        // Swift não tem como perguntar se um personagem é Emoji
        // mas nos permite verificar se nossos escalares de componentes são Emoji
        // infelizmente unicode permite certos escalares (como 1)
        // para ser modificado por outro escalar para se tornar emoji (ex. 1️⃣)
        // então o escalar "1" relatará isEmoji = true
        // então não podemos simplesmente verificar se o primeiro escalar é Emoji
        // o rápido e sujo aqui é ver se o escalar é pelo menos o primeiro emoji verdadeiro que conhecemos
        // (o início da seção "itens diversos")
        // ou verifique se esta é uma sequência unicode escalar múltipla
        // (por exemplo, um 1 com um modificador unicode para forçá-lo a ser apresentado como emoji 1️⃣)
      
        if let firstScalar = unicodeScalars.first, firstScalar.properties.isEmoji {
            return (firstScalar.value >= 0x238d || unicodeScalars.count > 1)
        } else {
            return false
        }
    }
}

// extraindo a URL real para uma imagem de uma URL que pode conter outras informações
// (essencialmente procurando a chave imgurl)
// imgurl é uma chave "bem conhecida" que pode ser incorporada em uma URL que diz qual é a URL real da imagem

extension URL {
    var imageURL: URL {
        for query in query?.components(separatedBy: "&") ?? [] {
            let queryComponents = query.components(separatedBy: "=")
            if queryComponents.count == 2 {
                if queryComponents[0] == "imgurl", let url = URL(string: queryComponents[1].removingPercentEncoding ?? "") {
                    return url
                }
            }
        }
        return baseURL ?? self
    }
}

// funções de conveniência para adicionar/subtrair CGPoints e CGSizes
// pode ser útil ao lidar com gestos
// porque fazemos muita conversão entre sistemas de coordenadas e tal
// observe que os tipos de tipo dos argumentos lhs e rhs variam abaixo
// assim, você pode deslocar um CGPoint pela largura e altura de um CGSize, por exemplo

extension DragGesture.Value {
    var distance: CGSize { location - startLocation }
}

extension CGRect {
    var center: CGPoint {
        CGPoint(x: midX, y: midY)
    }
}

extension CGPoint {
    static func -(lhs: Self, rhs: Self) -> CGSize {
        CGSize(width: lhs.x - rhs.x, height: lhs.y - rhs.y)
    }
    static func +(lhs: Self, rhs: CGSize) -> CGPoint {
        CGPoint(x: lhs.x + rhs.width, y: lhs.y + rhs.height)
    }
    static func -(lhs: Self, rhs: CGSize) -> CGPoint {
        CGPoint(x: lhs.x - rhs.width, y: lhs.y - rhs.height)
    }
    static func *(lhs: Self, rhs: CGFloat) -> CGPoint {
        CGPoint(x: lhs.x * rhs, y: lhs.y * rhs)
    }
    static func /(lhs: Self, rhs: CGFloat) -> CGPoint {
        CGPoint(x: lhs.x / rhs, y: lhs.y / rhs)
    }
}

extension CGSize {
    // o ponto central de uma área que é do nosso tamanho
    var center: CGPoint {
        CGPoint(x: width/2, y: height/2)
    }
    static func +(lhs: Self, rhs: Self) -> CGSize {
        CGSize(width: lhs.width + rhs.width, height: lhs.height + rhs.height)
    }
    static func -(lhs: Self, rhs: Self) -> CGSize {
        CGSize(width: lhs.width - rhs.width, height: lhs.height - rhs.height)
    }
    static func *(lhs: Self, rhs: CGFloat) -> CGSize {
        CGSize(width: lhs.width * rhs, height: lhs.height * rhs)
    }
    static func /(lhs: Self, rhs: CGFloat) -> CGSize {
        CGSize(width: lhs.width/rhs, height: lhs.height/rhs)
    }
}

// adicione conformidade com o protocolo RawRepresentable ao CGSize e ao CGFloat
// para que eles possam ser usados com @SceneStorage
// fazemos isso primeiro fornecendo implementações padrão de rawValue e init(rawValue:)
// em RawRepresentable quando a coisa em questão é Codable (que são CGFloat e CGSize)
// então tudo o que é preciso para fazer algo que seja Codable seja RawRepresentable é declarar que é assim
// (em seguida, obterá as implementações padrão necessárias para ser um RawRepresentable)

extension RawRepresentable where Self: Codable {
    public var rawValue: String {
        if let json = try? JSONEncoder().encode(self), let string = String(data: json, encoding: .utf8) {
            return string
        } else {
            return ""
        }
    }
    public init?(rawValue: String) {
        if let value = try? JSONDecoder().decode(Self.self, from: Data(rawValue.utf8)) {
            self = value
        } else {
            return nil
        }
    }
}

extension CGSize: RawRepresentable { }
extension CGFloat: RawRepresentable { }

// funções de conveniência para [NSItemProvider] (ou seja, matriz de NSItemProvider)
// torna o código para carregar objetos dos provedores um pouco mais simples
// NSItemProvider é um resquício do mundo Objective-C (ou seja, pré-Swift)
// você pode dizer pelo próprio nome (começa com NS)
// então, infelizmente, lidar com esta API é um pouco ruim
// portanto, eu recomendo que você aceite que essas funções loadObjects funcionem e sigam em frente
// é um caso raro em que tentar mergulhar e entender o que está acontecendo aqui
// provavelmente não seria um uso muito eficiente do seu tempo
// (embora eu certamente não vá dizer que você não deveria!)
// (apenas tentando ajudá-lo a otimizar seu valioso tempo neste trimestre)

extension Array where Element == NSItemProvider {
    func loadObjects<T>(ofType theType: T.Type, firstOnly: Bool = false, using load: @escaping (T) -> Void) -> Bool where T: NSItemProviderReading {
        if let provider = first(where: { $0.canLoadObject(ofClass: theType) }) {
            provider.loadObject(ofClass: theType) { object, error in
                if let value = object as? T {
                    DispatchQueue.main.async {
                        load(value)
                    }
                }
            }
            return true
        }
        return false
    }
    func loadObjects<T>(ofType theType: T.Type, firstOnly: Bool = false, using load: @escaping (T) -> Void) -> Bool where T: _ObjectiveCBridgeable, T._ObjectiveCType: NSItemProviderReading {
        if let provider = first(where: { $0.canLoadObject(ofClass: theType) }) {
            let _ = provider.loadObject(ofClass: theType) { object, error in
                if let value = object {
                    DispatchQueue.main.async {
                        load(value)
                    }
                }
            }
            return true
        }
        return false
    }
    func loadFirstObject<T>(ofType theType: T.Type, using load: @escaping (T) -> Void) -> Bool where T: NSItemProviderReading {
        loadObjects(ofType: theType, firstOnly: true, using: load)
    }
    func loadFirstObject<T>(ofType theType: T.Type, using load: @escaping (T) -> Void) -> Bool where T: _ObjectiveCBridgeable, T._ObjectiveCType: NSItemProviderReading {
        loadObjects(ofType: theType, firstOnly: true, using: load)
    }
}
