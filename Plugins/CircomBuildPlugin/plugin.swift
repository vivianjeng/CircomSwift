import PackagePlugin
import Foundation

@main
struct CircomSwiftPlugin: BuildToolPlugin {

  func createBuildCommands(
    context: PluginContext,
    target: Target
  ) throws -> [Command] {

    // Get package directory
    let packageDir = context.package.directoryURL
    let fileManager = FileManager.default
    
    // Search for .circom, .zkey, and .wasm files in the package directory
    var circomFiles: [URL] = []
    var zkeyFiles: [URL] = []
    var wasmFiles: [URL] = []
    
    // Recursively search for files
    if let enumerator = fileManager.enumerator(
      at: packageDir,
      includingPropertiesForKeys: [.isRegularFileKey, .nameKey],
      options: [.skipsHiddenFiles, .skipsPackageDescendants]
    ) {
      for case let fileURL as URL in enumerator {
        // Skip .build and .git directories
        let path = fileURL.path
        if path.contains("/.build/") || path.contains("/.git/") {
          enumerator.skipDescendants()
          continue
        }
        
        let fileExtension = fileURL.pathExtension.lowercased()
        if fileExtension == "circom" {
          circomFiles.append(fileURL)
        } else if fileExtension == "zkey" {
          zkeyFiles.append(fileURL)
        } else if fileExtension == "wasm" {
          wasmFiles.append(fileURL)
        }
      }
    }
    
    // Validate matching pairs for circom files
    for circomFile in circomFiles {
      let fileName = circomFile.deletingPathExtension().lastPathComponent
      let expectedZkeyName = fileName + "_final.zkey"
      
      let hasMatchingZkey = zkeyFiles.contains { zkeyFile in
        zkeyFile.lastPathComponent == expectedZkeyName
      }
      
      if !hasMatchingZkey {
        Diagnostics.error(
          """
          Missing zkey for circuit \(circomFile.lastPathComponent).
          Expected: \(expectedZkeyName)
          Searched in: \(packageDir.path)
          """)
      }
    }
    
    // Log found files for debugging (useful for tests)
    if !zkeyFiles.isEmpty {
      Diagnostics.remark("Found \(zkeyFiles.count) zkey file(s): \(zkeyFiles.map { $0.lastPathComponent }.joined(separator: ", "))")
    }
    if !wasmFiles.isEmpty {
      Diagnostics.remark("Found \(wasmFiles.count) wasm file(s): \(wasmFiles.map { $0.lastPathComponent }.joined(separator: ", "))")
    }
    
    // Return empty commands if validation passes (or if no source target)
    return []
  }
}
