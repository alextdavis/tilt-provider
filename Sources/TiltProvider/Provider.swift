import Core
import Vapor

/// Use this provider to use Leaf as your
/// view renderer

public final class Provider: Vapor.Provider {
    public static let repositoryName = "tilt-provider"

    public convenience init(config: Config) throws {
        self.init()
    }

    public func boot(_ config: Config) throws {
        config.addConfigurable(view: TiltRenderer.init, name: "tilt")
    }

    public func boot(_ drop: Droplet) throws {
    }

    public func beforeRun(_ drop: Droplet) throws {
    }
}
