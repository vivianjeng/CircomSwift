import Foundation
import PackagePlugin

@main
struct CircomSwiftPlugin: BuildToolPlugin {

  func createBuildCommands(
    context: PluginContext,
    target: Target
  ) throws -> [Command] {

    let fileManager = FileManager.default

    // Plugin work directory (safe, sandboxed)
    let workDirectory = context.pluginWorkDirectoryURL
    
    // Get package directory and construct mopro binary path
    let packageDir = context.package.directoryURL
    let moproBinary = packageDir.appendingPathComponent("Plugins/CircomBuildPlugin/Tools/mopro")

    // Marker file to avoid reinstalling mopro-cli
    let markerFile = workDirectory.appendingPathComponent(".mopro_installed")
    let markerFilePath = markerFile.path

    // Script path
    let scriptPath = workDirectory.appendingPathComponent("install_mopro.sh")
    let scriptFilePath = scriptPath.path

    // Get user's home directory
    let homeDirectory = FileManager.default.homeDirectoryForCurrentUser.path

    // -----------------------------
    // Script content
    // -----------------------------
    let scriptContent = """
      #!/bin/bash
      set -euo pipefail

      echo "== CircomSwiftPlugin: mopro-cli check =="

      export PATH="/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:/opt/homebrew/bin:$PATH"

      if [ -n "${HOME:-}" ]; then
        export PATH="$HOME/.cargo/bin:$PATH"
      fi

      if ! command -v mopro >/dev/null 2>&1; then
        echo "❌ mopro not found"
        echo ""
        echo "Please install it manually:"
        echo "  cargo install mopro-cli"
        echo ""
        echo "Then re-run the build."
        exit 1
      fi

      echo "✓ Found mopro: $(command -v mopro)"
      """

    // -----------------------------
    // Write script
    // -----------------------------
    try scriptContent.write(
      to: scriptPath,
      atomically: true,
      encoding: .utf8
    )

    // chmod +x
    let chmod = Process()
    chmod.executableURL = URL(fileURLWithPath: "/bin/chmod")
    chmod.arguments = ["+x", scriptFilePath]
    try chmod.run()
    chmod.waitUntilExit()

    // -----------------------------
    // Optional: scan package for artifacts (diagnostics only)
    // -----------------------------

    var zkeyFiles: [URL] = []
    var wasmFiles: [URL] = []
    var circomFiles: [URL] = []

    if let enumerator = fileManager.enumerator(
      at: packageDir,
      includingPropertiesForKeys: [.isRegularFileKey],
      options: [.skipsHiddenFiles, .skipsPackageDescendants]
    ) {
      for case let fileURL as URL in enumerator {
        let path = fileURL.path
        if path.contains("/.build/") || path.contains("/.git/") {
          enumerator.skipDescendants()
          continue
        }

        switch fileURL.pathExtension.lowercased() {
        case "circom":
          circomFiles.append(fileURL)
        case "zkey":
          zkeyFiles.append(fileURL)
        case "wasm":
          wasmFiles.append(fileURL)
        default:
          break
        }
      }
    }

    for circomFile in circomFiles {
      let baseName = circomFile.deletingPathExtension().lastPathComponent
      let expectedZkey = baseName + "_final.zkey"

      let found = zkeyFiles.contains {
        $0.lastPathComponent == expectedZkey
      }

      if !found {
        Diagnostics.error(
          """
          Missing zkey for circuit: \(circomFile.lastPathComponent)
          Expected: \(expectedZkey)
          """
        )
      }
    }

    if !zkeyFiles.isEmpty {
      Diagnostics.remark(
        "Found zkey files: \(zkeyFiles.map { $0.lastPathComponent }.joined(separator: ", "))"
      )
    }

    if !wasmFiles.isEmpty {
      Diagnostics.remark(
        "Found wasm files: \(wasmFiles.map { $0.lastPathComponent }.joined(separator: ", "))"
      )
    }

    // -----------------------------
    // Return PREBUILD command
    // -----------------------------
    // Check if mopro binary exists, otherwise use the script
    if fileManager.fileExists(atPath: moproBinary.path) {
      let outputDir = context.pluginWorkDirectoryURL.appendingPathComponent("circom-project")
      return [
        .prebuildCommand(
          displayName: "Run mopro",
          executable: moproBinary,
          arguments: ["init", "--adapter", "circom", "--project-name", "circom-project", "--output-dir", outputDir.path],
          outputFilesDirectory: workDirectory
        )
      ]
    } else {
      // Fallback to script that checks for mopro in PATH
      return [
        .prebuildCommand(
          displayName: "Check mopro-cli",
          executable: scriptPath,
          arguments: [],
          outputFilesDirectory: workDirectory
        )
      ]
    }
  }
}
