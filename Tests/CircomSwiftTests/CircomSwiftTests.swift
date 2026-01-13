import Testing
import Foundation
@testable import CircomSwift

@Test func detectZkeyAndWasmFiles() async throws {
    // This test verifies that the plugin can detect zkey and wasm files
    // The plugin runs during build, so we verify the files exist in the expected location
    
    // Get the test file's directory and navigate to Circuits
    let testFileURL = URL(fileURLWithPath: #file)
    let testTargetDirectory = testFileURL.deletingLastPathComponent()
    let circuitsDirectory = testTargetDirectory.appendingPathComponent("Circuits")
    
    // Check for zkey file
    let zkeyFile = circuitsDirectory.appendingPathComponent("multiplier2_final.zkey")
    let zkeyExists = FileManager.default.fileExists(atPath: zkeyFile.path)
    #expect(zkeyExists, "Expected zkey file at: \(zkeyFile.path)")
    
    // Check for wasm file
    let wasmFile = circuitsDirectory.appendingPathComponent("multiplier2.wasm")
    let wasmExists = FileManager.default.fileExists(atPath: wasmFile.path)
    #expect(wasmExists, "Expected wasm file at: \(wasmFile.path)")
    
    // Verify files are not empty
    if zkeyExists {
        let zkeyAttributes = try? FileManager.default.attributesOfItem(atPath: zkeyFile.path)
        let zkeySize = zkeyAttributes?[.size] as? Int64 ?? 0
        #expect(zkeySize > 0, "Zkey file should not be empty")
    }
    
    if wasmExists {
        let wasmAttributes = try? FileManager.default.attributesOfItem(atPath: wasmFile.path)
        let wasmSize = wasmAttributes?[.size] as? Int64 ?? 0
        #expect(wasmSize > 0, "Wasm file should not be empty")
    }
}
