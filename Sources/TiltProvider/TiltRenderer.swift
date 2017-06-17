import Foundation
import Vapor

public final class TiltRenderer: ViewRenderer {
    public internal(set) var environment: Environment = .development
    public var shouldCache = false // Not used
    private let viewsDir: String

    public init(viewsDir: String) {
        self.viewsDir = viewsDir
    }

    public func make(_ path: String, _ context: Node) throws -> View {
        let tmp_filename = "/tmp/me.alextdavis.tilt-provider/\(UUID().uuidString).html"
        let task = Process()
        let inPipe = Pipe()
        task.launchPath = "\(viewsDir)adapter.rb"
        let contextString = try JSON(node: context).serialize().makeString()

        task.arguments = [viewsDir, path, tmp_filename]
        task.standardInput = inPipe
        task.launch()
        inPipe.fileHandleForWriting.write(contextString.data(using: .utf8)!)
        inPipe.fileHandleForWriting.closeFile()
        task.waitUntilExit()
        let data = FileManager.default.contents(atPath: tmp_filename)
        try FileManager.default.removeItem(atPath: tmp_filename)
        return View(data: data?.makeBytes() ?? "Fatal Template Error".makeBytes())
    }
}

extension TiltRenderer: ConfigInitializable {
    public convenience init(config: Config) throws {
        self.init(viewsDir: config.viewsDir)
    }
}
