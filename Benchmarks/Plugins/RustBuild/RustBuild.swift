//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2025 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

import Foundation
import PackagePlugin

@main
struct RustBuild: BuildToolPlugin {
  func findRustCompiler() throws -> URL {
    let which = Process()
    which.executableURL = URL(filePath: "/usr/bin/which")
    which.arguments = ["rustc"]

    let whichOutput = Pipe()
    which.standardOutput = whichOutput

    try which.run()
    which.waitUntilExit()

    let output = whichOutput.fileHandleForReading.readDataToEndOfFile()
    var pathString = String(decoding: output, as: UTF8.self)
    pathString.removeLast()
    return URL(filePath: pathString)
  }

  func createBuildCommands(
    context: PluginContext,
    target: Target
  ) throws -> [Command] {
    guard let sourceFiles = target.sourceModule?.sourceFiles else { return [] }

    // Filter the dummy Swift source file out.
    let rustSources = sourceFiles.filter {
      $0.url.pathExtension == "rs"
    }

    let rustCompiler = try findRustCompiler()

    let inputs = rustSources.map {
      $0.url
    }
    let inputPaths = inputs.map {
      $0.path
    }
    let lib = "lib\(target.name).a"
    let output = context.pluginWorkDirectoryURL.appendingPathComponent(lib)
    let args = inputPaths + ["-o", output.path, "-O", "--crate-type", "staticlib"]

    return [
      .buildCommand(
        displayName: "Compiling Rust Sources in Target \(target.name)",
        executable: rustCompiler,
        arguments: args,
        inputFiles: inputs,
        outputFiles: [output]
      )
    ]
  }
}
