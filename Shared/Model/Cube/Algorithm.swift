//
//  Algorithm.swift
//  Cubing Timer
//
//  Created by Cameron Delong on 8/13/21.
//

import OrderedCollections
import Foundation

/// A series of `Moves` forming an `Algorithm` that can be performed on a `Cube`.
struct Algorithm: Codable {
    // MARK: Properties
    static var algorithms: [Algorithm] = [""]
    
    /// The `Move`s making up the `Algorithm`.
    var moves: [Move] = []
    
    /// The locations of "triggers" in the `Algorithm`.
    var triggerIndices: [Int] = []
    
    /// The reverse of the algorithm.
    var reversed: Algorithm {
        return Algorithm(moves.reversed().map { $0.reversed })
    }

    // MARK: Initializers
    /// Creates an `Algorithm` from a series of `Move`s.
    init(_ moves: Move...) {
        self.moves = moves
    }
    
    /// Creates an `Algorithm` from an array of `Move`s.
    init(_ moves: [Move]) {
        self.moves = moves
    }
    
    // MARK: Methods
    /// Returns an `Algorithm` to scramble a `Puzzle`.
    static func scramble(puzzle: Puzzle) -> Self? {
        switch puzzle {
        case let .cube(size):
            var scramble = Algorithm()
            
            for _ in 1...size * 12 - 15 {
                let face: Cube.Tile
                let direction = Move.Direction.allCases.randomElement()!
                let layers = 0...Int.random(in: 0...size / 2)
                
                if layers == scramble.moves.last?.layers {
                    face = Cube.Tile.allCases.filter { $0 != scramble.moves.last?.face }.randomElement()!
                } else {
                    face = Cube.Tile.allCases.randomElement()!
                }
                
                scramble.moves.append(
                    Move(
                        face: face,
                        direction: direction,
                        layers: layers
                    )!
                )
            }
            
            return scramble
            
        default:
            return nil
        }
    }
}

extension Algorithm: LosslessStringConvertible {
    // MARK: Properties
    /// A `String` describing of the `Algorithm`.
    var description: String {
        var elements: [String] = []
        
        var triggerCharacter = "("
        
        for (index, move) in moves.enumerated() {
            if triggerIndices.contains(index) {
                elements.append(triggerCharacter)
                
                triggerCharacter = triggerCharacter == "(" ? ")" : "("
            }
            
            elements.append(String(move))
        }
        
        var description = ""
        
        for (index, element) in elements.enumerated() {
            description.append(element)
            
            if index != elements.endIndex - 1 && element != "(" && elements[safe: index + 1] != ")" {
                description.append(" ")
            }
            
            
        }
        
        return description
    }
    
    // MARK: Initializers
    /// Creates an `Algorithm` from a `String`.
    init(_ description: String) {
        let moves = description.split(separator: " ")
        
        var index = 0
        
        for move in moves {
            if move.first == "(" || move.first == ")" {
                triggerIndices.append(index)
            } else if move.last == "(" || move.last == ")" {
                triggerIndices.append(index + 1)
            }
            
            guard let toAppend = Move(String(move.filter { $0 != "(" && $0 != ")" })) else {
                continue
            }
            
            self.moves.append(toAppend)
            
            index += 1
        }
    }
}

extension Algorithm: ExpressibleByStringLiteral {
    // MARK: Initializers
    init(stringLiteral value: String) {
        self.init(value)
    }
}

extension Algorithm: ExpressibleByArrayLiteral {
    // MARK: Initializers
    init(arrayLiteral: Move...) {
        self.init(arrayLiteral)
    }
}

extension Algorithm: Hashable {
    // MARK: Methods
    func hash(into hasher: inout Hasher) {
        hasher.combine(moves)
    }
}

extension Algorithm: RawRepresentable {
    // MARK: Initializers
    public init?(rawValue: String) {
        guard let data = rawValue.data(using: .utf8),
              let result = try? JSONDecoder().decode(Self.self, from: data)
        else {
            return nil
        }
        
        self = result
    }
    
    // MARK: Properties
    public var rawValue: String {
        guard let data = try? JSONEncoder().encode(self),
              let result = String(data: data, encoding: .utf8)
        else {
            return ""
        }
        
        return result
    }
}
