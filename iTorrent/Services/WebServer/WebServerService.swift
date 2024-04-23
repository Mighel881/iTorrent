//
//  WebServerService.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 23/04/2024.
//

import Combine
import GCDWebServers
import MvvmFoundation
import UIKit

@MainActor
class WebServerService {
    init() { binding() }

    private var webUploadServer = GCDWebUploader(uploadDirectory: TorrentService.downloadPath.path())
    private var webDAVServer = GCDWebDAVServer(uploadDirectory: TorrentService.downloadPath.path())

    private let disposeBag = DisposeBag()
    private var backgroundDisposeBag: DisposeBag?
    @Injected private var preferences: PreferencesStorage
    @Injected private var backgroundService: BackgroundService
}

private extension WebServerService {
    var commonBinding: AnyPublisher<Void, Never> {
        Just(())
            .combineLatest(preferences.$isFileSharingEnabled)
            .combineLatest(preferences.$webServerLogin)
            .combineLatest(preferences.$webServerPassword)
            .map { _ in () }
            .eraseToAnyPublisher()
    }

    var options: [String: Any] {
        var options: [String: Any] = [:]

        if !preferences.webServerLogin.isEmpty {
            options[GCDWebServerOption_AuthenticationAccounts] = [preferences.webServerLogin: preferences.webServerPassword]
            options[GCDWebServerOption_AuthenticationMethod] = GCDWebServerAuthenticationMethod_DigestAccess
        }

        options[GCDWebServerOption_AutomaticallySuspendInBackground] = false

        return options
    }

    func binding() {
        disposeBag.bind {
            Just(())
                .combineLatest(commonBinding)
                .combineLatest(preferences.$isWebServerEnabled)
                .combineLatest(preferences.$webServerPort)
                .receive(on: DispatchQueue.global(qos: .utility))
                .sink { [unowned self] _ in
                    refreshWebServerState()
                }

            Just(())
                .combineLatest(commonBinding)
                .combineLatest(preferences.$isWebDavServerEnabled)
                .combineLatest(preferences.$webDavServerPort)
                .receive(on: DispatchQueue.global(qos: .utility))
                .sink { [unowned self] _ in
                    refreshWebDavServerState()
                }

            NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
                .receive(on: DispatchQueue.global(qos: .utility))
                .sink { [unowned self] _ in
                    invalidateBackgroundState(true)
                }

            NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
                .receive(on: DispatchQueue.global(qos: .utility))
                .sink { [unowned self] _ in
                    invalidateBackgroundState(false)
                }
        }
    }

    func invalidateBackgroundState(_ goToBackground: Bool) {
//        print("WebService test: \(goToBackground) && \(backgroundService.isRunning)")

        backgroundDisposeBag = DisposeBag()

        if goToBackground { // Going background
            if backgroundService.isRunning {
                backgroundDisposeBag?.bind {
                    backgroundService.$isRunningPublisher
                        // Wait a bit to allow unbind before triggering on going foreground
                        .debounce(for: 0.1, scheduler: DispatchQueue.main)
                        .sink { [unowned self] isRunning in
                            guard !isRunning else { return }

                            if webUploadServer.isRunning {
                                webUploadServer.stop()
                            }

                            if webDAVServer.isRunning {
                                webDAVServer.stop()
                            }

                            backgroundDisposeBag = nil
                        }
                }
            } else {
                if webUploadServer.isRunning {
                    webUploadServer.stop()
                }

                if webDAVServer.isRunning {
                    webDAVServer.stop()
                }
            }
        } else { // Going foreground
            if !webUploadServer.isRunning {
                refreshWebServerState()
            }

            if !webDAVServer.isRunning {
                refreshWebDavServerState()
            }
        }
    }

    func refreshWebServerState() {
        let needToEnable = preferences.isFileSharingEnabled && preferences.isWebServerEnabled

        if webUploadServer.isRunning {
            webUploadServer.stop()
        }

        if needToEnable, !webUploadServer.isRunning {
            var localOptions = options
            var port = preferences.webServerPort
            localOptions[GCDWebServerOption_Port] = port
            while (try? webUploadServer.start(options: localOptions)) == nil {
                port += 1
                localOptions[GCDWebServerOption_Port] = port
            }
        }
    }

    func refreshWebDavServerState() {
        let needToEnable = preferences.isFileSharingEnabled && preferences.isWebDavServerEnabled

        if webDAVServer.isRunning {
            webDAVServer.stop()
        }

        if needToEnable, !webDAVServer.isRunning {
            var localOptions = options
            var port = preferences.webDavServerPort
            localOptions[GCDWebServerOption_Port] = port
            while (try? webDAVServer.start(options: localOptions)) == nil {
                port += 1
                localOptions[GCDWebServerOption_Port] = port
            }
        }
    }
}