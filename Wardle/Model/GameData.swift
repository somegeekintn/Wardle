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
    @Published var startingWord     = "SLATE"
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

    // SLATE / blend = 3.6009 avg (1) commonality x 2.5 minus present
    // SLATE / blend = 3.6017 avg (0) commonality x 2.0 minus present
    // SLATE / blend = 3.6052 avg (0) commonality x 2.0 minus present aggressive no-common 13 vs 24 6 guess words yet worse overall
    // SLATE / blend = 3.6026 avg (0) commonality x 2.4 minus present
    // SLATE / blend = 3.6065 avg (2) commonality == 0

    // STALE / blend = 3.6410 avg (0) commonality x 2.0 minus present

    // SLATE / blend = 3.6060 avg (1) commonality x 2.5
    // SLATE / blend = 3.6065 avg (2) commonality x 3
    // SLATE / blend = 3.6078 avg (2) commonality == 0
    // SLATE / blend = 3.6078 avg (0) commonality x 2.4
    // SLATE / blend = 3.6091 avg (0) commonality x 2
// really blend is not great, see YIELD where more than half would be eliminated
    // SALET / blend = 3.6130 avg (0) commonality < 1
    // SLATE / blend = 3.6164 avg (13)
    // SALET / blend = 3.6246 avg (14)
    // ROATE / blend = 3.6700 avg (5) commonality < 1
    // CRANE / blend = 3.6734 avg (16)
    // SLANT / blend = 3.6739 avg (13)
    // IRATE / blend = 3.6760 avg (14)
    // STARE / blend = 3.6769 avg (14)
    // ROATE / blend = 3.6786 avg (17)
    // SHALE / blend = 3.6924 avg (11)
    // SLICE / blend = 3.6942 avg (13)
    // SHARE / blend = 3.7136 avg (16)
    // SUITE / blend = 3.7171 avg (19)
    // SAINT / blend = 3.7127 avg (20)
    // SAUTE / blend = 3.7136 avg (20)
    // SANER / blend = 3.7244 avg (16)
    // ARISE / blend = 3.7317 avg (20)
    // SAUCE / blend = 3.7365 avg (18)
    // ADIEU / blend = 3.8721 avg (27)
    // AUDIO / blend = 3.8911 avg (28)
    // FUZZY / blend = 4.2147 avg (28)
    // AFFIX / blend = 4.2553 avg (40)

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
        print("Testing using \(strategy) with: \(startingWord) as staring word")
        
        testTask = Task {
            var wordCount       = 0
            var totalGuesses    = 0
            var workFreq        = Array<Int>(repeating: 0, count: 7)
            var updateTime      = Date()
            
            for word in wordList {
                guard !Task.isCancelled else { break }
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
                            let guess = bestGuess(at: guessIndex, strategy: strategy)
                            
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
        guard guessCount > 0 else { return startingWord }
        let sortOrder   : [KeyPathComparator<WordScore>]
        let sorted      : [WordScore]
        var selection   : WordScore?
        var guess       : String?
        
        switch strategy {
            case .commonality:  sortOrder = [.init(\.commonality, order: .reverse), .init(\.probability, order: .reverse), .init(\.masterProb, order: .reverse)]
            case .probability:  sortOrder = [.init(\.probability, order: .reverse), .init(\.commonality, order: .reverse), .init(\.masterProb, order: .reverse)]
            case .blend:        sortOrder = [.init(\.blend, order: .reverse), .init(\.probability, order: .reverse), .init(\.commonality, order: .reverse), .init(\.masterProb, order: .reverse)]
        }
        sorted = scores.sorted(using: sortOrder)
        selection = sorted.first
        guess = selection?.word
        
        if let commonality = selection?.commonality {
            let guessesLeft = (6 - guessCount)
            let makesSense  = sorted.count > guessesLeft// || (sorted.count > 2 && commonality == 0)
            
            if sorted.count > Int(Double(commonality) * 2.0) && guessCount < 5 && makesSense {
print("common: \(commonality) for \(sorted.count)")
                let unmatchedIdx    = matchByCol.enumerated().compactMap({ item in item.element == "." ? item.offset : nil })
//                let matched         = matchByCol.enumerated().compactMap({ item in item.element != "." ? item.element : nil })
                var chars           = Set<Character>()
                
                print("\(sorted.count) remain for \(6 - guessCount) guesses")

                for idx in unmatchedIdx {
                    chars.formUnion(sorted.map({ $0.word[$0.word.index($0.word.startIndex, offsetBy: idx)] }))
                }
//                chars.subtract(matched)
                chars.subtract(presentChars)
print("find: \(chars)")
                
                if chars.count > 12 {
                    selection = scores.sorted(using: [KeyPathComparator<WordScore>(\.commonality, order: .reverse)]).first
                    guess = selection?.word
print("too many, most in common: \(selection?.word ?? "- n/a -")")
                }
                else {
                    if let better = wordList.sorted(by: { lhs, rhs in
                        let lhs_c = chars.intersection(lhs.unique).count
                        let rhs_c = chars.intersection(rhs.unique).count

                        return lhs_c > rhs_c
                    }).first(where: { word in !letterRows.contains(where: { $0.string == word.word }) }) {
                        let cnt = chars.intersection(better.chars).count
                        
                        print("try: \(better.word) [\(cnt)]")
                        
                        guess = better.word
                    }
                }
            }
        }

        return guess ?? ""
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
