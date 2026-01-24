//
// main.swift
//

import Benchmark
import MimeFoundation

let benchmarks: @Sendable () -> Void = {
    let benchmarks = MimeParserBenchmarks()

    // MimeParser
    Benchmark("MimeParser_StarTrekMessage") { benchmark in
        for _ in benchmark.scaledIterations {
            benchmarks.mimeParser_StarTrekMessage()
        }
    }

    Benchmark("MimeParser_StarTrekMessagePersistent") { benchmark in
        for _ in benchmark.scaledIterations {
            benchmarks.mimeParser_StarTrekMessagePersistent()
        }
    }

    Benchmark("MimeParser_ContentLengthMbox") { benchmark in
        for _ in benchmark.scaledIterations {
            benchmarks.mimeParser_ContentLengthMbox()
        }
    }

    Benchmark("MimeParser_ContentLengthMboxPersistent") { benchmark in
        for _ in benchmark.scaledIterations {
            benchmarks.mimeParser_ContentLengthMboxPersistent()
        }
    }

    Benchmark("MimeParser_JwzMbox") { benchmark in
        for _ in benchmark.scaledIterations {
            benchmarks.mimeParser_JwzMbox()
        }
    }

    Benchmark("MimeParser_JwzMboxPersistent") { benchmark in
        for _ in benchmark.scaledIterations {
            benchmarks.mimeParser_JwzMboxPersistent()
        }
    }

    Benchmark("MimeParser_HeaderStressTest") { benchmark in
        for _ in benchmark.scaledIterations {
            benchmarks.mimeParser_HeaderStressTest()
        }
    }

    // ExperimentalMimeParser
    Benchmark("ExperimentalMimeParser_StarTrekMessage") { benchmark in
        for _ in benchmark.scaledIterations {
            benchmarks.experimentalMimeParser_StarTrekMessage()
        }
    }

    Benchmark("ExperimentalMimeParser_StarTrekMessagePersistent") { benchmark in
        for _ in benchmark.scaledIterations {
            benchmarks.experimentalMimeParser_StarTrekMessagePersistent()
        }
    }

    Benchmark("ExperimentalMimeParser_ContentLengthMbox") { benchmark in
        for _ in benchmark.scaledIterations {
            benchmarks.experimentalMimeParser_ContentLengthMbox()
        }
    }

    Benchmark("ExperimentalMimeParser_ContentLengthMboxPersistent") { benchmark in
        for _ in benchmark.scaledIterations {
            benchmarks.experimentalMimeParser_ContentLengthMboxPersistent()
        }
    }

    Benchmark("ExperimentalMimeParser_JwzMbox") { benchmark in
        for _ in benchmark.scaledIterations {
            benchmarks.experimentalMimeParser_JwzMbox()
        }
    }

    Benchmark("ExperimentalMimeParser_JwzMboxPersistent") { benchmark in
        for _ in benchmark.scaledIterations {
            benchmarks.experimentalMimeParser_JwzMboxPersistent()
        }
    }

    Benchmark("ExperimentalMimeParser_HeaderStressTest") { benchmark in
        for _ in benchmark.scaledIterations {
            benchmarks.experimentalMimeParser_HeaderStressTest()
        }
    }

    // MimeReader
    Benchmark("MimeReader_StarTrekMessage") { benchmark in
        for _ in benchmark.scaledIterations {
            benchmarks.mimeReader_StarTrekMessage()
        }
    }

    Benchmark("MimeReader_ContentLengthMbox") { benchmark in
        for _ in benchmark.scaledIterations {
            benchmarks.mimeReader_ContentLengthMbox()
        }
    }

    Benchmark("MimeReader_JwzMbox") { benchmark in
        for _ in benchmark.scaledIterations {
            benchmarks.mimeReader_JwzMbox()
        }
    }

    Benchmark("MimeReader_HeaderStressTest") { benchmark in
        for _ in benchmark.scaledIterations {
            benchmarks.mimeReader_HeaderStressTest()
        }
    }
}