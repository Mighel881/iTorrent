//
//  RssDetailsViewController.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 08.04.2024.
//

import MvvmFoundation
import SafariServices
import UIKit
import WebKit

class RssDetailsViewController<VM: RssDetailsViewModel>: BaseViewController<VM> {
    var webView: WKWebView!

    override func loadView() {
        let button = UIBarButtonItem(primaryAction: .init(image: .init(systemName: "safari"), handler: { [unowned self] _ in
            present(SFSafariViewController(url: viewModel.rssModel.link), animated: true)
        }))
        navigationItem.setRightBarButton(button, animated: false)

        webView = WKWebView()
        webView.backgroundColor = .secondarySystemBackground
        webView.scrollView.keyboardDismissMode = .onDrag
        view = webView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }

    private lazy var delegates = Delegates(parent: self)
}

private extension RssDetailsViewController {
    func setup() {
        navigationItem.largeTitleDisplayMode = .never
        binding()

        webView.navigationDelegate = delegates
        loadHtml()
    }

    func binding() {
        disposeBag.bind {
            viewModel.$title.sink { [unowned self] text in
                title = text
            }
        }
    }

    func loadHtml() {
        if let description = viewModel.rssModel.description {
            let res = themedHtmlPart + description
            webView.loadHTMLString(res, baseURL: nil)
        }
    }
}

private extension RssDetailsViewController {
    class Delegates: DelegateObject<RssDetailsViewController>, WKNavigationDelegate {
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard navigationAction.navigationType == .linkActivated
            else { return decisionHandler(.allow) }

            guard let url = navigationAction.request.url,
                  UIApplication.shared.canOpenURL(url)
            else { return decisionHandler(.allow) }

            if url.absoluteString.hasSuffix(".torrent") {
                Task {
                    if await TorrentAddViewModel.presentRemote(with: url, from: parent, showAlerts: false) == false {
                        await parent.present(SFSafariViewController(url: url), animated: true)
                    }
                }
            } else {
                parent.present(SFSafariViewController(url: url), animated: true)
            }
            decisionHandler(.cancel)
        }
    }
}

private extension RssDetailsViewController {
    var themedHtmlPart: String {
        if traitCollection.userInterfaceStyle == .dark {
            return """
            <style>
            @media (prefers-color-scheme: dark) {
                body {
                    background-color: \(view.backgroundColor!.rgbString);
                    color: white;
                }
                a:link {
                    color: \(UIColor.tintColor.rgbString);
                }
                a:visited {
                    color: #9d57df;
                }
            }
            </style>
            """
        } else {
            return """
            <style>
            @media (prefers-color-scheme: light) {
                a:link {
                    color: \(view.tintColor.rgbString);
                }
                a:visited {
                    color: #9d57df;
                }
            }
            </style>
            """
        }
    }
}

private extension UIColor {
    var rgbString: String {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        return "rgb(\(Int(red*255)),\(Int(green*255)),\(Int(blue*255)))"
    }
}