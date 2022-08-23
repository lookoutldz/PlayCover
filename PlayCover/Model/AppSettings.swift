//
//  AppSettings.swift
//  PlayCover
//

import Foundation
import UniformTypeIdentifiers
import AppKit

struct AppSettingsData: Codable {
    var keymapping: Bool = true
    var mouseMapping: Bool = true
    var sensitivity: Float = 50

    var disableTimeout: Bool = false
    var iosDeviceModel: String = "iPad8,6"
    var refreshRate: Int = 60
    var windowWidth: Int = 1920
    var windowHeight: Int = 1080
    var resolution: Int = 2
    var aspectRatio: Int = 1
    var notch: Bool = NSScreen.hasNotch()
    var bypass: Bool = false
}

class AppSettings {
    static var appSettingsDir: URL {
        let settingsFolder =
            PlayTools.playCoverContainer.appendingPathComponent("App Settings")
        if !fileMgr.fileExists(atPath: settingsFolder.path) {
            do {
                try fileMgr.createDirectory(at: settingsFolder, withIntermediateDirectories: true, attributes: [:])
            } catch {
                Log.shared.error(error)
            }
        }
        return settingsFolder
    }

    let info: AppInfo
    let settingsUrl: URL
    var container: AppContainer?
    var settings: AppSettingsData {
        didSet {
            encode()
        }
    }

    init(_ info: AppInfo, container: AppContainer?) {
        self.info = info
        self.container = container
        self.settingsUrl = AppSettings.appSettingsDir.appendingPathComponent("\(info.bundleIdentifier).plist")
        self.settings = AppSettingsData()
        if !decode() {
            encode()
        }
    }

    public func sync() {
        settings.notch = NSScreen.hasNotch()
    }

    public func reset() {
        settings = AppSettingsData()
    }

    @discardableResult
    public func decode() -> Bool {
        do {
            let data = try Data(contentsOf: settingsUrl)
            settings = try PropertyListDecoder().decode(AppSettingsData.self, from: data)
            return true
        } catch {
            print(error)
            return false
        }
    }

    @discardableResult
    public func encode() -> Bool {
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .xml

        do {
            let data = try encoder.encode(settings)
            try data.write(to: settingsUrl)
            return true
        } catch {
            print(error)
            return false
        }
    }
}

let notchModels = [ "MacBookPro18,3", "MacBookPro18,4", "MacBookPro18,1", "MacBookPro18,2", "Mac14,2"]

extension NSScreen {
    public static func hasNotch() -> Bool {
        if let model = NSScreen.getMacModel() {
            return notchModels.contains(model)
        } else {
            return false
        }
    }

    private static func getMacModel() -> String? {
        let service = IOServiceGetMatchingService(kIOMainPortDefault,
                                                  IOServiceMatching("IOPlatformExpertDevice"))
        var modelIdentifier: String?

        if let modelData = IORegistryEntryCreateCFProperty(service, "model" as CFString, kCFAllocatorDefault, 0)
            .takeRetainedValue() as? Data {
            if let modelIdentifierCString = String(data: modelData, encoding: .utf8)?.cString(using: .utf8) {
                modelIdentifier = String(cString: modelIdentifierCString)
            }
        }
        IOObjectRelease(service)
        return modelIdentifier
    }
}
