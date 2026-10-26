import Foundation
import Testing
@testable import LogicProMCP

// Fork js-blueprint: song-build MIDI staging for import_file.

@Test func songBuildStagingRejectsPathsOutsideRoots() {
    #expect(SMFWriter.stageSongBuildMIDIFile("/private/tmp/LogicProMCP/acid.mid") == nil)
    #expect(SMFWriter.stageSongBuildMIDIFile("/etc/passwd") == nil)
}

@Test func songBuildStagingCopiesAllowlistedMIDI() throws {
    let root = FileManager.default.temporaryDirectory
        .appendingPathComponent("lpm-songbuild-\(UUID().uuidString)", isDirectory: true)
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: root) }
    let source = root.appendingPathComponent("ATT FINAL DRUMS 164 BPM.mid")
    try Data([0x4D, 0x54, 0x68, 0x64, 0, 0, 0, 6, 0, 0, 0, 1, 0x01, 0xE0]).write(to: source)

    setenv("LOGIC_MCP_IMPORT_ROOTS", root.path, 1)
    defer { unsetenv("LOGIC_MCP_IMPORT_ROOTS") }

    let staged = try #require(SMFWriter.stageSongBuildMIDIFile(source.path))
    #expect(staged != source.resolvingSymlinksInPath().path)
    #expect(staged.hasSuffix("/ATT FINAL DRUMS 164 BPM.mid"))
    #expect(SMFWriter.isManagedTemporaryMIDIFile(staged))
    #expect(AccessibilityChannel.validatedMIDIImportPath(staged) == staged)
    #expect(SMFWriter.stageSongBuildMIDIFile(root.appendingPathComponent("missing.mid").path) == nil)
}
