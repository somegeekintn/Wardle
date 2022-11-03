//
//  GameData.swift
//  Wardle
//
//  Created by Casey Fleser on 9/12/22.
//

import SwiftUI

class GameData: ObservableObject {
    enum Strategy {
        case commonality
        case probability
        case blend
    }
    
    @Published var isTesting        = false
    @Published var letterRows       : [LetterRow]
    @Published var matchingWords    = [Word]()
    @Published var posWeights       = Array<[CharWeight]>(repeating: [], count: 5)
    @Published var allWeights       = [CharWeight]()
    @Published var pattern          = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"  // had thought to display this
    @Published var solutionFreq     = Array<Int>(repeating: 0, count: 7)
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
    var scoreTask           : Task<(), Never>?
    var testTask            : Task<(), Never>?
    
    // okay wow: https://auction-upload-files.s3.amazonaws.com/Wordle_Paper_Final.pdf

// BOXER took 7. 258 words: 3.5155 avg
// FOYER took 7. 800 words: 3.5362 avg
// HASTE took 7. 957 words: 3.5831 avg
// HATCH took 7. 959 words: 3.5871 avg
// HILLY took 7. 979 words: 3.5975 avg
// HOUND took 7. 996 words: 3.6124 avg
// JAUNT took 7. 1050 words: 3.6219 avg
// JOKER took 7. 1059 words: 3.6327 avg
// MOUND took 7. 1264 words: 3.6234 avg
// NIGHT took 7. 1303 words: 3.6309 avg
// RATTY took 7. 1547 words: 3.6419 avg
// SHAVE took 7. 1715 words: 3.6490 avg
// WATCH took 7. 2233 words: 3.6090 avg

    // SLATE / blend = 3.6164 avg (13)
    // SALET / blend = 3.6246 avg (14)
    // SLATE / prob = 3.6346 avg (13)
    // SALET / prob = 3.6454 avg
    // SALET / common = 3.6553 avg
    // SLATE / common = 3.6661 avg
    // STARE / common = 3.6790 avg (17)
    // CRANE / prob = 3.6812 avg
    // IRATE / common = 3.6881 avg
    // CRANE / common = 3.6894 avg
    // ROATE / prob = 3.6898 avg
    // IRATE / prob = 3.7002 avg
    // STARE / prob = 3.7076 avg
    // SANER / common = 3.7214 avg
    // SAINT / prob = 3.7266 avg
    // ARISE / prob = 3.7425 avg
    // SANER / prob = 3.7456 avg
    // ARISE / common = 3.7482 avg
    // AUDIO / prob = 3.8972 avg
    // AUDIO / common = 3.9145 avg

    static let firstGuess   = "SALET"
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
    
    func toggleTesting() {
        isTesting.toggle()
        
        if isTesting {
            testStrategy(.blend)
        }
        else {
            testTask?.cancel()
        }
    }
    
    func testStrategy(_ strategy: Strategy) {
        print("Testing using \(strategy) with: \(Self.firstGuess) as staring word")
        
        testTask = Task {
            var wordCount       = 0
            var totalGuesses    = 0
            var workFreq        = Array<Int>(repeating: 0, count: 7)
            var updateTime      = Date()
            
            for word in wordList {
                let guessCount = await solve(word.word, strategy: strategy).value
                
                wordCount += 1
                totalGuesses += guessCount
                
                print("\(word.word) took \(guessCount). \(wordCount) words: \((Double(totalGuesses) / Double(wordCount)).formatted(.number.precision(.fractionLength(4)))) avg")
                
                workFreq [guessCount - 1] += 1
                if Date().timeIntervalSince(updateTime) > 0.05 {    // no need to hammer the UI
                    let uiFreq = workFreq
                    
                    await MainActor.run { solutionFreq = uiFreq }
                    updateTime = Date()
                }
            }
            
            let uiFreq = workFreq
            await MainActor.run { solutionFreq = uiFreq }
        }
    }
    
    @discardableResult
    func solve(_ answer: String, strategy: Strategy) -> Task<Int, Never> {
        return Task {
            var solution    = (complete: false, count: 0)
            let adjAnswer   = answer.uppercased()
            
            await MainActor.run {
                letterRows = (0..<GameData.rowCount).map({ LetterRow(id: "row_\($0)") })
                resetFrequencies()
            }
            // No need to reset() if first guess is supplied
            
            while !solution.complete {
                if let _ = await scoreTask?.value {
                    solution = await MainActor.run {
                        if let guessIndex = activeRowIndex, guessIndex < 6 {
                            let guess   = guessIndex == 0 ? Self.firstGuess : bestGuess(at: guessIndex, strategy: strategy)
                            
                            if !guess.isEmpty {
                                let missed  = zip(guess, adjAnswer).filter({ $0 != $1 }).map({ $0.1 })
                                let letters = zip(zip(letterRows[guessIndex].letters, guess), adjAnswer).map { item in
                                    let oldLetter   = item.0.0
                                    let guessChar   = item.0.1
                                    let correctChar = item.1
                                    
                                    return Letter(String(guessChar), state: guessChar == correctChar ? .correct : (missed.contains(guessChar) ? .present : .absent), id: oldLetter.id)
                                }
                                let solved  = !letters.contains(where: { $0.state != .correct })
//                                let desc = letters.map {
//                                    switch $0.state {
//                                        case .absent: return "⬛️"
//                                        case .present: return "🟨"
//                                        case .correct: return "🟩"
//                                        case .unknown: return "?"
//                                    }
//                                }
//                                print("\(guess): \(solved): \(desc.joined())")
                                
                                letterRows[guessIndex].letters = letters
                                letterRows[guessIndex].locked = true

                                if !solved {
                                    evaluate()
                                }

                                return (solved, guessIndex + 1)
                            }
                            else {
                                print("something broke")
                            
                                return (true, 7)
                            }
                        }
                        else {
                            print("something broke")
                            
                            return (true, 7)
                        }
                    }
                }
            }
//
//            print("Solved \(adjAnswer) in \(solution.count)")
            
            return solution.count
        }
    }
    
    @MainActor
    func bestGuess(at guessCount: Int, strategy: Strategy) -> String {
        guard guessCount > 0 else { return Self.firstGuess }
        let sortOrder   : [KeyPathComparator<WordScore>]
        let sorted      : [WordScore]
        
        switch strategy {
            case .commonality:  sortOrder = [.init(\.commonality, order: .reverse), .init(\.probability, order: .reverse), .init(\.masterProb, order: .reverse)]
            case .probability:  sortOrder = [.init(\.probability, order: .reverse), .init(\.commonality, order: .reverse), .init(\.masterProb, order: .reverse)]
            case .blend:        sortOrder = [.init(\.blend, order: .reverse), .init(\.probability, order: .reverse), .init(\.commonality, order: .reverse), .init(\.masterProb, order: .reverse)]
        }
        sorted = scores.sorted(using: sortOrder)
        
        return sorted.first?.word ?? ""
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
        let presentMap  : BitChar
       
        resetFrequencies()
        gatherPatternInfo()
        presentMap = BitChar(set: presentChars)
        
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
            
            if presentMap.isSubset(of: word.bitChars) {
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
        
//        if !heisenChars.isEmpty {
//            print("heisenChars: \(heisenChars)")
//        }
//        print("pattern: \(pattern)")
    }
    
    func updateScores() {
        scoreTask = Task {
            let testWords       = matchingWords
            let testMasterFreq  = masterPosFreq
            let testPosFreq     = posFreq
            let allWordCount    = wordList.count
            let presentMap      = BitChar(set: presentChars)
            
            let newScores = await withTaskGroup(of: WordScore.self, returning: [WordScore].self) { group in
                var results = [WordScore]()

                for guess in testWords {
                    group.addTask {
                        var common      = 0
                        var probability = Double(1.0)
                        var masterProb  = Double(1.0)
                        let mask        = guess.bitChars.subtracting(presentMap)
                        
                        for (pos, ch) in guess.word.enumerated() {
                            if let count = testMasterFreq[pos][ch] {
                                masterProb *= (Double(count) / Double(allWordCount))
                            }
                            if let count = testPosFreq[pos][ch] {
                                probability *= (Double(count) / Double(testWords.count))
                            }
                        }
                        
                        probability *= 100
                        masterProb *= 100 * 1000

                        for other in testWords {    // too slow
                            if guess.word != other.word {
                                if !mask.isDisjoint(with: other.bitChars) {
                                    common += 1
                                }
                            }
                        }
                        
                        return WordScore(word: guess.word, probability: probability, masterProb: masterProb, commonality: common)
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
}
