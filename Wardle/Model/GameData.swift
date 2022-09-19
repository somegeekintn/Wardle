//
//  GameData.swift
//  Wardle
//
//  Created by Casey Fleser on 9/12/22.
//

import SwiftUI

extension String {
    func containsAll(_ chars: Set<Character>) -> Bool {
        for ch in chars {
            guard self.contains(ch) else { return false }
        }

        return true
    }
}

struct CharWeight: Comparable, Identifiable {
    let char    : String
    var weight  : Double
    let column  : Int
    
    var id      : String { "\(column)_\(char)" }

    init(_ char: String, freq: Int, total: Int, column: Int = 999) {
        self.char = char
        self.weight = Double(freq) / Double(total) * 100
        self.column = column
    }
    
    init(_ char: Character, freq: Int, total: Int, column: Int = 999) {
        self.char = String(char)
        self.weight = Double(freq) / Double(total) * 100
        self.column = column
    }
    
    static func < (lhs: CharWeight, rhs: CharWeight) -> Bool {
        lhs.weight > rhs.weight
    }
}

struct WordScore: Comparable, Identifiable {
    let word        : String
    let posScore    : Double
    let freqScore   : Double
    let commonScore : Int

    var id      : String { "score_\(word)" }
    
    static func < (lhs: WordScore, rhs: WordScore) -> Bool {
        lhs.commonScore == rhs.commonScore ? lhs.freqScore == rhs.freqScore ? lhs.posScore > rhs.posScore : lhs.freqScore > rhs.freqScore : lhs.commonScore > rhs.commonScore
    }
}

struct Word {
    let word    : String
    let chars   : [Character]
    let uChars  : Set<Character>
    
    init(_ word: String) {
        let uWord   = word.uppercased()
        let chars   = uWord.map({ $0 })
        
        self.word = uWord.uppercased()
        self.chars = chars
        self.uChars = Set<Character>(chars)
    }
    
    func matches(absent: Set<Character>, present: Set<Character>) -> Bool {
        !absent.contains(where: { uChars.contains($0) }) && present.isSubset(of: uChars)
    }
    
    func containsByColumn(colChars: [Set<Character>]) -> Bool {
        return zip(colChars, chars).contains { absent, colChar in absent.contains(colChar) }
    }
}

class GameData: ObservableObject {
    @Published var letterRows       : [LetterRow]
    @Published var matchingWords    = [Word]()
    @Published var posWeights       = [[CharWeight]]()
    @Published var allWeights       = [CharWeight]()
    @Published @MainActor var scores  = [WordScore]()
    
    var rowCount            : Int { letterRows.count }
    var activeRowIndex      : Int? { letterRows.firstIndex(where: { !$0.locked }) }

    var wordList            = [Word]()
    var posFreq             = [[Character : Int]](repeating: [:], count: charCount)
    var anyFreq             = [Character : Int]()
    var absentChars         = Set<Character>()
    var presentChars        = Set<Character>()
    var absentByCol         = [Set<Character>](repeating: Set<Character>(), count: 5)
    var regex               = try? NSRegularExpression(pattern: ".....")
    
    static let letters      = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    static let charCount    = 5
    static let rowCount     = 6
    
    init() {
        self.letterRows = (0..<GameData.rowCount).map({ LetterRow(id: "row_\($0)") })
        self.resetFrequencies()

        if let listURL = Bundle.main.url(forResource: "word_list", withExtension: "txt") {
            do {
                let list = try String(contentsOf: listURL)
                
                wordList = list.components(separatedBy: .whitespacesAndNewlines).filter({ !$0.isEmpty }).sorted().map({ Word($0) })
            }
            catch {
                print("failed to load list @ \(listURL)")
            }
        }
        
        evaluate()
    }
    
    func reset() {
        letterRows = (0..<GameData.rowCount).map({ LetterRow(id: "row_\($0)") })
        resetFrequencies()

        evaluate()
    }
    
    func addNextLetter(_ letter: Letter) {
        guard let rowIndex = activeRowIndex else { return }
        
        letterRows[rowIndex].addNextLetter(letter)
    }

    func removeLastLetter() {
        guard let rowIndex = activeRowIndex else { return }

        letterRows[rowIndex].removeLastLetter()
    }
    
    func resetFrequencies() {
        for ch in GameData.letters {
            anyFreq[ch] = 0
        }
        
        for idx in 0..<GameData.charCount {
            for ch in GameData.letters {
                posFreq[idx][ch] = 0
            }
            
            absentByCol[idx].removeAll()
        }
    }
    
    func evaluate() {
        var filtered    = [Word]()
        var regexPass   = [Word]()
        
        resetFrequencies()
        gatherPatternInfo()
        
        if let regex = regex, regex.pattern != "....." {
            for word in wordList {
                if regex.numberOfMatches(in: word.word, range: NSRange(location: 0, length: 5)) > 0 {
                    regexPass.append(word)
                }
            }
        }
        else {
            regexPass = wordList
        }
        
        for word in regexPass {
            if word.matches(absent: absentChars, present: presentChars) {
                if !word.containsByColumn(colChars: absentByCol) {
                    var matched = [Character]()
                    
                    for (pos, ch) in word.word.enumerated() {
                        let cnt = posFreq[pos][ch] ?? 0
                        
                        posFreq[pos][ch] = cnt + 1
                        if !matched.contains(ch) {
                            anyFreq[ch] = (anyFreq[ch] ?? 0) + 1
                            matched.append(ch)
                        }
                    }
                    
                    filtered.append(word)
                }
            }
        }

        matchingWords = filtered
        allWeights = anyFreq.filter({ $0.value > 0}).map({ (char, freq) in CharWeight(char, freq: freq, total: matchingWords.count) }).sorted()
        posWeights = posFreq.enumerated().map { (col, freq) in
            freq.filter({ $0.value > 0}).map({ (char, freq) in CharWeight(char, freq: freq, total: matchingWords.count, column: col) }).sorted()
        }
        updateScores()
    }
    
    func gatherPatternInfo() {
        var colMatch    : [Character] = Array(repeating: ".", count: 5)
        
        absentChars = .init("")
        presentChars = .init("")
        
        for letterRow in letterRows {
            guard letterRow.locked else { break }
            
            for (idx, letter) in letterRow.letters.enumerated() {
                guard let char = letter.value?.first else { break }
                
                switch letter.state {
                    case .absent:
                        absentChars.insert(char)
                        
                    case .present:
                        presentChars.insert(char)
                        absentByCol[idx].insert(char)
                        
                    case .correct:
                        presentChars.insert(char)
                        colMatch[idx] = char
                        
                    case .unknown:
                        break
                }
            }
        }
        
        // Special case where we might have a character both present and absent
        // Not sure this is right.
        for char in colMatch {
            if absentChars.contains(char) {
                absentChars.remove(char)
            }
        }
        
        regex = try? NSRegularExpression(pattern: colMatch.map({ String($0) }).joined())
    }
    
    func updateScores() {
        Task {
            let testWords   = matchingWords
            let testPresent = presentChars
            let testPosFreq = posFreq
            let testAnyFreq = anyFreq
            let start       = Date()

            let newScores = await withTaskGroup(of: WordScore.self, returning: [WordScore].self) { group in
                var results = [WordScore]()

                for guess in testWords {
                    group.addTask {
                        let guessChars  = guess.uChars.filter({ !testPresent.contains($0) })
                        var common      = 0
                        var used        = [Character]()
                        var posScore    = Double(1.0)
                        var freqScore   = Double(1.0)
                        
                        for (pos, ch) in guess.word.enumerated() {
                            if let count = testPosFreq[pos][ch] {
                                posScore *= (Double(count) / Double(testWords.count))
                            }

                            if !used.contains(ch), let count = testAnyFreq[ch] {
                                freqScore += (Double(count) / Double(testWords.count))
                                used.append(ch)
                            }
                        }
                        
                        posScore *= 100 * 100

                        for other in testWords {
                            if guess.word != other.word {
                                if other.uChars.contains(where: { guessChars.contains($0) }) {
                                    common += 1
                                }
                            }
                        }
                        
                        return WordScore(word: guess.word, posScore: posScore, freqScore: freqScore, commonScore: common)
                    }
                }
                
                for await result in group {
                    results.append(result)
                }
                
                return results
            }

            await MainActor.run { scores = newScores.sorted() }
        }
    }

    func updateScores2() {
        Task {
            let divisor     = Double(matchingWords.count)
            let testWords   = matchingWords
            
            var scores = await withTaskGroup(of: (String, Double, Double).self, returning: [(String, Double, Double)].self) { group in
                var results = [(String, Double, Double)]()
                
                for guess in testWords {
                    group.addTask {
                        var present = 0
                        var correct = 0
                        
                        for answer in testWords {
                            let minusMatches = zip(answer.word, guess.word).filter({ $0 != $1 })
                            var rAnswer      = minusMatches.map({ String($0.0) })
                            let rGuess       = minusMatches.map({ String($0.1) })
                            
                            correct += answer.word.count - minusMatches.count
                            for char in rGuess {
                                if let presentIdx = rAnswer.firstIndex(of: char) {
                                    present += 1
                                    rAnswer.remove(at: presentIdx)
                                }
                            }
                        }
                        
                        return (guess.word, Double(present) / divisor, Double(correct) / divisor)
                    }
                }
                
                for await result in group {
                    results.append(result)
                }
                
                return results
            }

            scores.sort { lhs, rhs in
                (lhs.1 + lhs.2 * 1.2) > (rhs.1 + rhs.2 * 1.2)
            }
            
            for score in scores {
                print(score)
            }
        }
    }
}
