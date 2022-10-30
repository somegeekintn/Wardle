//
//  GameData.swift
//  Wardle
//
//  Created by Casey Fleser on 9/12/22.
//

import SwiftUI

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

struct WordScore: Identifiable {
    let word        : String
    let probability : Double
    let masterProb  : Double
    let weighted    : Double
    let commonality : Int

    var id      : String { "score_\(word)" }
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
}

class GameData: ObservableObject {
    @Published var letterRows       : [LetterRow]
    @Published var matchingWords    = [Word]()
    @Published var posWeights       = Array<[CharWeight]>(repeating: [], count: 5)
    @Published var allWeights       = [CharWeight]()
    @Published var pattern         = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"  // had thought to display this
    @Published @MainActor var scores = [WordScore]()
    
    var rowCount            : Int { letterRows.count }
    var activeRowIndex      : Int? { letterRows.firstIndex(where: { !$0.locked }) }

    var wordList            = [Word]()
    var masterPosFreq       = [[Character : Int]](repeating: [:], count: charCount)
    var posFreq             = [[Character : Int]](repeating: [:], count: charCount)
    var anyFreq             = [Character : Int]()
    var presentChars        = Set<Character>()
    var matchByCol          = [Character](repeating: ".", count: 5)
    var heisenChars         = Set<Character>()  // characters that are both matched and present elsewhere
    var regex               = try? NSRegularExpression(pattern: ".....")
    
    static let letters      = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    static let charCount    = 5
    static let rowCount     = 6
    
    init() {
        self.letterRows = (0..<GameData.rowCount).map({ LetterRow(id: "row_\($0)") })

        if let listURL = Bundle.main.url(forResource: "word_list", withExtension: "txt") {
            do {
                let list = try String(contentsOf: listURL)
                
                wordList = list.components(separatedBy: .whitespacesAndNewlines).filter({ !$0.isEmpty }).sorted().map({ Word($0) })
            }
            catch {
                print("failed to load list @ \(listURL)")
            }
        }
        
        resetMasterFrequencies()
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
        }
    }
    
    func resetMasterFrequencies() {
        for idx in 0..<GameData.charCount {
            for ch in GameData.letters {
                masterPosFreq[idx][ch] = 0
            }
        }
        
        for word in wordList {
            for (pos, ch) in word.word.enumerated() {
                let cnt = masterPosFreq[pos][ch] ?? 0
                
                masterPosFreq[pos][ch] = cnt + 1
            }
        }
    }
    
    func evaluate() {
        var filtered    = [Word]()
        var regexPass   = [Word]()
        
        resetFrequencies()
        gatherPatternInfo()
        
        if let regex = regex {
            let range = NSRange(location: 0, length: 5)

            regexPass = wordList.filter { regex.numberOfMatches(in: $0.word, range: range) != 0 }
        }

        for word in regexPass {
            if !heisenChars.isEmpty {
                let unmatched = Set(zip(matchByCol, word.chars).filter({ $0 != $1 }).map({ $1 }))
                
                if !heisenChars.isSubset(of: unmatched) {
                    print("heisenChars: \(heisenChars) not found in \(unmatched)")
                    continue
                }
            }
            
            if presentChars.isSubset(of: word.uChars) {
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

        matchingWords = filtered
        allWeights = anyFreq.filter({ $0.value > 0}).map({ (char, freq) in CharWeight(char, freq: freq, total: matchingWords.count) }).sorted()
        posWeights = posFreq.enumerated().map { (col, freq) in
            freq.filter({ $0.value > 0}).map({ (char, freq) in CharWeight(char, freq: freq, total: matchingWords.count, column: col) }).sorted()
        }
        updateScores()
    }
    
    func gatherPatternInfo() {
        var colPatterns     = Array(repeating: Self.letters, count: 5)
        
        presentChars = .init("")
        heisenChars = .init("")
        matchByCol = [Character](repeating: ".", count: 5)
        
        for letterRow in letterRows {
            guard letterRow.locked else { break }
            var rowPresent  = Set<Character>()
            var rowMatched  = Set<Character>()
            
            for (idx, letter) in letterRow.letters.enumerated() {
                guard let char  = letter.value?.first else { break }
                
                switch letter.state {
                    case .absent:
                        colPatterns = colPatterns.map({ $0.filter({ $0 != char }) })
                        
                    case .present:
                        presentChars.insert(char)
                        rowPresent.insert(char)
                        colPatterns[idx] = colPatterns[idx].filter({ $0 != char })
                        
                    case .correct:
                        presentChars.insert(char)
                        rowMatched.insert(char)
                        // if this was matched in an earlier guess then subsequent guesses
                        // containing this but not the heisenChar should not be eliminated
                        if colPatterns[idx] != String(char) {
                            heisenChars.remove(char)
                            matchByCol[idx] = char
                            colPatterns[idx] = String(char)
                        }
                        
                    case .unknown:
                        break
                }
            }
            
            // fix items clobbered by absent matches
            colPatterns = zip(matchByCol, colPatterns).map({ $0 != "." ? String($0) : $1 })
            
            // detect heisen characters
            rowPresent.formIntersection(rowMatched)
            if !rowPresent.isEmpty {
                heisenChars.formUnion(rowPresent)
            }
        }
        
        pattern = colPatterns.map({ "[\($0)]" }).joined()
        regex = try? NSRegularExpression(pattern: pattern)
        
        if !heisenChars.isEmpty {
            print("heisenChars: \(heisenChars)")
        }
        print("pattern: \(pattern)")
    }
    

    func updateScores() {
        Task {
            let testWords       = matchingWords
            let testPresent     = presentChars
            let testMasterFreq  = masterPosFreq
            let testPosFreq     = posFreq
            let testAnyFreq     = anyFreq
            let allWordCount    = wordList.count
            
            let newScores = await withTaskGroup(of: WordScore.self, returning: [WordScore].self) { group in
                var results = [WordScore]()

                for guess in testWords {
                    group.addTask {
                        let guessChars  = guess.uChars.filter({ !testPresent.contains($0) })
                        var common      = 0
                        var used        = [Character]()
                        var probability = Double(1.0)
                        var masterProb  = Double(1.0)
                        var weighted    = Double(1.0)
                        
                        for (pos, ch) in guess.word.enumerated() {
                            if let count = testMasterFreq[pos][ch] {
                                masterProb *= (Double(count) / Double(allWordCount))
                            }
                            if let count = testPosFreq[pos][ch] {
                                probability *= (Double(count) / Double(testWords.count))
                            }

                            if !used.contains(ch), let count = testAnyFreq[ch] {
                                weighted += (Double(count) / Double(testWords.count))
                                used.append(ch)
                            }
                        }
                        
                        probability *= 100
                        masterProb *= 100 * 1000

                        for other in testWords {
                            if guess.word != other.word {
                                if other.uChars.contains(where: { guessChars.contains($0) }) {
                                    common += 1
                                }
                            }
                        }
                        
                        return WordScore(word: guess.word, probability: probability, masterProb: masterProb, weighted: weighted, commonality: common)
                    }
                }
                
                for await result in group {
                    results.append(result)
                }
                
                return results
            }

            // only if these changes are made in separate steps will the UI not flip out
            await MainActor.run { scores = scores.filter({ oldScore in newScores.contains(where: { $0.word == oldScore.word }) }) }
            await MainActor.run { scores = newScores }//.sorted() }
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
