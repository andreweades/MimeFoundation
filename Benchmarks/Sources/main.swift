//
// main.swift
//

import Foundation
import MimeFoundation

// Simple benchmark runner
func runBenchmark(_ name: String, _ block: () -> Void) {
    print("Running \(name)...")
    // Warmup
    for _ in 0..<5 { block() }
    
    let iterations = 100
    let start = Date()
    for _ in 0..<iterations {
        block()
    }
    let end = Date()
    let elapsed = end.timeIntervalSince(start)
    let avg = (elapsed / Double(iterations)) * 1000.0 // ms
    print("Result: \(name): \(String(format: "%.4f", avg)) ms/op")
}

let benchmarks = MimeParserBenchmarks()

print("Starting Benchmarks...")

// MimeParser
runBenchmark("MimeParser_StarTrekMessage") { benchmarks.mimeParser_StarTrekMessage() }
runBenchmark("MimeParser_StarTrekMessagePersistent") { benchmarks.mimeParser_StarTrekMessagePersistent() }
runBenchmark("MimeParser_ContentLengthMbox") { benchmarks.mimeParser_ContentLengthMbox() }
runBenchmark("MimeParser_ContentLengthMboxPersistent") { benchmarks.mimeParser_ContentLengthMboxPersistent() }
runBenchmark("MimeParser_JwzMbox") { benchmarks.mimeParser_JwzMbox() }
runBenchmark("MimeParser_JwzMboxPersistent") { benchmarks.mimeParser_JwzMboxPersistent() }
runBenchmark("MimeParser_HeaderStressTest") { benchmarks.mimeParser_HeaderStressTest() }

// ExperimentalMimeParser
runBenchmark("ExperimentalMimeParser_StarTrekMessage") { benchmarks.experimentalMimeParser_StarTrekMessage() }
runBenchmark("ExperimentalMimeParser_StarTrekMessagePersistent") { benchmarks.experimentalMimeParser_StarTrekMessagePersistent() }
runBenchmark("ExperimentalMimeParser_ContentLengthMbox") { benchmarks.experimentalMimeParser_ContentLengthMbox() }
runBenchmark("ExperimentalMimeParser_ContentLengthMboxPersistent") { benchmarks.experimentalMimeParser_ContentLengthMboxPersistent() }
runBenchmark("ExperimentalMimeParser_JwzMbox") { benchmarks.experimentalMimeParser_JwzMbox() }
runBenchmark("ExperimentalMimeParser_JwzMboxPersistent") { benchmarks.experimentalMimeParser_JwzMboxPersistent() }
runBenchmark("ExperimentalMimeParser_HeaderStressTest") { benchmarks.experimentalMimeParser_HeaderStressTest() }

// MimeReader
runBenchmark("MimeReader_StarTrekMessage") { benchmarks.mimeReader_StarTrekMessage() }
runBenchmark("MimeReader_ContentLengthMbox") { benchmarks.mimeReader_ContentLengthMbox() }
runBenchmark("MimeReader_JwzMbox") { benchmarks.mimeReader_JwzMbox() }
runBenchmark("MimeReader_HeaderStressTest") { benchmarks.mimeReader_HeaderStressTest() }

print("Done.")
