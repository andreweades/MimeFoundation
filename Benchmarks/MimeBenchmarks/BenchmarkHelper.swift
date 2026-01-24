//
// BenchmarkHelper.swift
//

import Foundation

class BenchmarkHelper {
    static let projectDir: String = {
        let fileManager = FileManager.default
        let currentDir = fileManager.currentDirectoryPath
        // Assume running from MimeFoundation root
        return currentDir + "/Benchmarks"
    }()

    static let unitTestsDir: String = {
        let fileManager = FileManager.default
        let currentDir = fileManager.currentDirectoryPath
        return currentDir + "/Benchmarks"
    }()
}
