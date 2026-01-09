import PackagePlugin
import Foundation

@main
struct CircomBuildPlugin: BuildToolPlugin {

  func createBuildCommands(
    context: PluginContext,
    target: Target
  ) throws -> [Command] {

    // URL where plugin can write outputs
    let outputDir = context.pluginWorkDirectoryURL
    let packageDir = context.package.directoryURL
    
    // Example: just echo for now
    return [
      .prebuildCommand(
        displayName: "CircomSwift: prepare artifacts",
        executable: URL(fileURLWithPath: "/bin/bash"),
        arguments: [
          "-c",
          """
          set -e
          # Package directory passed from Swift context
          PACKAGE_DIR="\(packageDir.path)"
          PLUGIN_WORK_DIR="\(outputDir.path)"
          
          # Write to log file in plugin work directory (guaranteed to be writable)
          LOG_FILE="$PLUGIN_WORK_DIR/build.log"
          
          # Output messages - they will be visible in build output
          echo "=== CircomSwift Build Plugin ===" >&2
          echo "Building target: \(target.name)" >&2
          echo "Plugin work dir: $PLUGIN_WORK_DIR" >&2
          echo "Package directory: $PACKAGE_DIR" >&2
          echo "Timestamp: $(date)" >&2
          echo "=================================" >&2
          
          # Also save to log file
          {
            echo "=== CircomSwift Build Plugin ==="
            echo "Building target: \(target.name)"
            echo "Plugin work dir: $PLUGIN_WORK_DIR"
            echo "Package directory: $PACKAGE_DIR"
            echo "Timestamp: $(date)"
            echo "================================="
          } > "$LOG_FILE" 2>&1
          
          echo "📝 Detailed log saved to: $LOG_FILE" >&2
          """,
        ],
        outputFilesDirectory: outputDir
      )
    ]
  }
}
