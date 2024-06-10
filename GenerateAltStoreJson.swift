//#!/usr/bin/swiftc -parse-as-library

import Foundation

let rootUrl = "https://raw.githubusercontent.com/XITRIX/iTorrent-v2/main"
let rootDistrUrl = "https://raw.githubusercontent.com/XITRIX/xitrix.github.io/master"

let _iphoneStandardScreenshots: [String] = [
    "\(rootDistrUrl)/screenshots/1.PNG",
    "\(rootDistrUrl)/screenshots/2.PNG",
    "\(rootDistrUrl)/screenshots/3.PNG",
    "\(rootDistrUrl)/screenshots/4.PNG",
]

let _iphoneEdgeToEdgeScreenshots: [String] = [
    "\(rootDistrUrl)/screenshots/sidestore/1.png",
    "\(rootDistrUrl)/screenshots/sidestore/2.png",
    "\(rootDistrUrl)/screenshots/sidestore/3.png",
    "\(rootDistrUrl)/screenshots/sidestore/4.png",
    "\(rootDistrUrl)/screenshots/sidestore/5.png",
]

// MARK: - AltStore Models
struct SideStoreScreenshotsModel: Codable {
    var iphoneStandard: [String]? = _iphoneStandardScreenshots
    var iphoneEdgeToEdge: [String]? = _iphoneEdgeToEdgeScreenshots
    var ipad: [String]?

    enum CodingKeys: String, CodingKey {
        case iphoneStandard = "iphone-standard"
        case iphoneEdgeToEdge = "iphone-edgeToEdge"
        case ipad
    }
}

struct AltStoreAppPermissionModel: Codable {
    var entitlements: [String] = ["com.apple.security.application-groups"]
    var privacy: [String: String] = [
        "NSLocationWhenInUseUsageDescription": "More robust alternative to hold app working in background which requires additional permission, enables Dynamic Island progress extension",
        "NSLocationAlwaysAndWhenInUseUsageDescription": "This additional permition allows to hide location indicator from status bar during background downloading"
    ]
}

struct SideStoreAppPermissionModel: Codable {
    var type: String
    var usageDescription: String
}

struct AltStoreAppVersionModel: Codable {
    var version: String
    var buildVersion: String = "1"
    var date: String
    var size: UInt
    var downloadURL: String
    var localizedDescription: String?
    var minOSVersion: String? = "16.0"
}

struct AltStoreAppModel: Codable {
    var name: String = "iTorrent"
    var bundleIdentifier: String = "com.xitrix.iTorrent2"
    var developerName: String = "XITRIX"
    var marketplaceID: String = "6499499971"
    var subtitle: String?
    var localizedDescription: String = 
        """
        It is an ordinary torrent client for iOS with Files app support.

        What can this app do:

        • Download in the background
        • Sequential download (use VLC to watch films while loading)
        • Add torrent files from Share menu (Safari and other apps)
        • Add magnet links directly from Safari
        • Store files in Files app (iOS 11+)
        • File sharing directly from app
        • Download torrent by link
        • Download torrent by magnet
        • Send notification on torrent downloaded
        • WebDav Server
        • Select files to download or not
        • Change UI to dark theme
        • RSS Feed
        • ???
        """
    var downloadURL: String
    var iconURL: String = "\(rootUrl)/iTorrent/Core/Assets/Assets.xcassets/AppIcon.appiconset/Untitled.png"
    var tintColor: String? = "#D03E43"
    var category: String? = "utilities"
    var screenshots: [String]? = _iphoneStandardScreenshots
    var screenshotURLs: [String]? = _iphoneEdgeToEdgeScreenshots
    var versions: [AltStoreAppVersionModel]
    var appPermissions: AltStoreAppPermissionModel = .init()
    var permissions: [SideStoreAppPermissionModel] = [
        .init(type: "network", usageDescription: "Needs to download torrents"),
        .init(type: "background-audio", usageDescription: "Needs to hold app working in background"),
        .init(type: "location", usageDescription: "More robust alternative to hold app working in background which requires additional permission")]
}

struct AltStoreSourceModel: Codable {
    var name: String = "iTorrent Source"
    var identifier: String = "com.xitrix.itorrent"
    var subtitle: String?
    var description: String? = "Official source for iTorrent app"
    var iconURL: String? = "\(rootUrl)/iTorrent/Core/Assets/Assets.xcassets/AppIcon.appiconset/Untitled.png"
    var headerURL: String? = "\(rootUrl)/iTorrent/Core/Assets/Assets.xcassets/AppIcon.appiconset/Untitled.png"
    var website: String? = "https://github.com/XITRIX/iTorrent"
    var patreonURL: String? = "https://www.patreon.com/xitrix"
    var tintColor: String? = "#D03E43"
    var featuredApps: [String] = ["com.xitrix.iTorrent2"]
    var apps: [AltStoreAppModel]
}

// MARK: - GitHub Models
struct GitHubAssetModel: Codable {
    var name: String
    var browserDownloadUrl: String
    var size: UInt
}

struct GitHubReleaseModel: Codable {
    var name: String
    var publishedAt: String
    var assets: [GitHubAssetModel]
}

// MARK: - App
@main
struct AltServerGenerator {
    static func main() async throws {
        let url = "https://api.github.com/repos/XITRIX/iTorrent-v2/releases"
        let (data, _) = try await URLSession.shared.data(from: URL(string: url)!)

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let releases = try decoder.decode([GitHubReleaseModel].self, from: data)

//        print(releases)

        let versions = releases.compactMap { release -> AltStoreAppVersionModel? in
            guard let ipaAsset = release.assets.first(where: { $0.name == "iTorrent.ipa" })
            else { return nil }

            return AltStoreAppVersionModel(version: release.name, date: release.publishedAt, size: ipaAsset.size, downloadURL: ipaAsset.browserDownloadUrl)
        }

        let model = AltStoreSourceModel(apps: [
            .init(
                downloadURL: versions.first?.downloadURL ?? "",
                versions: versions
            )
        ])

        let sourceJsonData = try JSONEncoder().encode(model)
        let sourceJson = String(data: sourceJsonData, encoding: .utf8)!
        print(sourceJson)
    }
}
