//
// Trie.swift
//
// Ported from MimeKit (C#) to Swift.
//

final class Trie {
    final class TrieState {
        var next: TrieState?
        var fail: TrieState?
        var match: TrieMatch?
        var pattern: String?
        var depth: Int = 0

        init(fail: TrieState?) {
            self.fail = fail
        }
    }

    final class TrieMatch {
        var next: TrieMatch?
        let state: TrieState
        let value: Character

        init(value: Character, next: TrieMatch?, state: TrieState) {
            self.value = value
            self.next = next
            self.state = state
        }
    }

    private var failStates: [TrieState?] = []
    private let root: TrieState
    private let ignoreCase: Bool

    init(ignoreCase: Bool = false) {
        self.ignoreCase = ignoreCase
        self.root = TrieState(fail: nil)
    }

    private static func findMatch(_ state: TrieState, _ value: Character) -> TrieMatch? {
        var match = state.match
        while let current = match, current.value != value {
            match = current.next
        }
        return match
    }

    private func insert(_ state: TrieState, depth: Int, value: Character) -> TrieState {
        let inserted = TrieState(fail: root)
        let match = TrieMatch(value: value, next: state.match, state: inserted)
        state.match = match

        if failStates.count < depth + 1 {
            failStates.append(nil)
        }

        inserted.next = failStates[depth]
        failStates[depth] = inserted

        return inserted
    }

    func add(_ pattern: String) {
        guard !pattern.isEmpty else {
            return
        }

        var state: TrieState? = root
        var depth = 0

        for ch in pattern {
            let c = ignoreCase ? Character(String(ch).lowercased()) : ch
            let match = Trie.findMatch(state!, c)
            if let match {
                state = match.state
            } else {
                state = insert(state!, depth: depth, value: c)
            }
            depth += 1
        }

        state?.pattern = pattern
        state?.depth = depth

        for i in 0..<failStates.count {
            var current = failStates[i]

            while let state = current {
                var match = state.match
                while let currentMatch = match {
                    let matchedState = currentMatch.state
                    var failState = state.fail
                    var nextMatch: TrieMatch? = nil

                    let c = currentMatch.value

                    while let fail = failState {
                        if let found = Trie.findMatch(fail, c) {
                            nextMatch = found
                            break
                        }
                        failState = fail.fail
                    }

                    if let nextMatch {
                        matchedState.fail = nextMatch.state
                        if let failDepth = matchedState.fail?.depth, failDepth > matchedState.depth {
                            matchedState.depth = failDepth
                        }
                    } else {
                        if let rootMatch = Trie.findMatch(root, c) {
                            matchedState.fail = rootMatch.state
                        } else {
                            matchedState.fail = root
                        }
                    }

                    match = currentMatch.next
                }

                current = state.next
            }
        }
    }

    func search(_ text: [Character], startIndex: Int, count: Int) -> (Int, String?) {
        guard startIndex >= 0, count >= 0, startIndex <= text.count else {
            return (-1, nil)
        }

        let endIndex = min(text.count, startIndex + count)
        var state: TrieState? = root
        var match: TrieMatch? = nil
        var matched = 0
        var offset = -1
        var pattern: String? = nil

        var i = startIndex
        while i < endIndex {
            let ch = ignoreCase ? Character(String(text[i]).lowercased()) : text[i]
            match = state.flatMap { Trie.findMatch($0, ch) }
            while let current = state, match == nil && matched == 0 {
                state = current.fail
                if let state = state {
                    match = Trie.findMatch(state, ch)
                }
            }

            if state === root {
                if matched > 0 {
                    return (offset, pattern)
                }
                offset = i
            }

            if state == nil {
                if matched > 0 {
                    return (offset, pattern)
                }
                state = root
                offset = i
            } else if let match {
                state = match.state
                if let currentState = state, showingDepthGreater(currentState, matched) {
                    pattern = currentState.pattern
                    matched = currentState.depth
                }
            } else if matched > 0 {
                return (offset, pattern)
            }

            i += 1
        }

        return matched > 0 ? (offset, pattern) : (-1, nil)
    }

    private func showingDepthGreater(_ state: TrieState, _ matched: Int) -> Bool {
        state.depth > matched
    }
}
