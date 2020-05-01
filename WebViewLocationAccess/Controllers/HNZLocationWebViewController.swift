//
//  HNZLocationWebViewController.swift
//  WebViewLocationAccess
//
//  Created by Hanis Hassim on 01/05/2020.
//  Copyright © 2020 H. All rights reserved.
//

import WebKit
import CoreLocation

class HNZLocationWebViewController: UIViewController {
    // MARK: - Properties -
    
    // MARK: Private
    
    private var viewModel: HNZLocationWebViewModelType
    private var listenersCount = 0
    private var status = CLLocationManager.authorizationStatus()
    
    // MARK: - UI Variables
    
    private lazy var webView: WKWebView = {
        let contentController = WKUserContentController()
        contentController.add(self, name: "locationHandler")
        contentController.add(self, name: "listenerAdded")
        contentController.add(self, name: "listenerRemoved")
        
        let config = WKWebViewConfiguration()
        config.userContentController = contentController
        
        let scriptSource = """
            navigator.geolocation.getCurrentPosition = function(success, error, { timeout:5000, enableHighAccuracy:true }) {
                var id = this.helper.id();
                this.helper.listeners[id] = { onetime: true, success: success || this.noop, error: error || this.noop };
                window.webkit.messageHandlers.listenerAdded.postMessage('');
                window.webkit.messageHandlers.locationHandler.postMessage('getCurrentPosition'); // to trigger webkit

                return id;
            };

            navigator.geolocation.watchPosition = function(success, error, { timeout:5000, enableHighAccuracy:true }) {
                var id = this.helper.id();
                this.helper.listeners[id] = { onetime: false, success: success || this.noop, error: error || this.noop };
                window.webkit.messageHandlers.listenerAdded.postMessage('');
                window.webkit.messageHandlers.locationHandler.postMessage('getCurrentPosition'); // to trigger webkit

                return id;
            };

            // For use with watchPosition()
            navigator.geolocation.clearWatch = function(id) {
                var idExists = this.helper.listeners[id] ? true : false;
                if idExists {
                    this.helper.listeners[id] = null;
                    delete this.helper.listeners[id];
                    window.webkit.messageHandlers.listenerRemoved.postMessage('');
                }
            };
        """
        let script = WKUserScript(source: scriptSource, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        contentController.addUserScript(script)
        
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.uiDelegate = self
        webView.navigationDelegate = self
        webView.scrollView.delegate = self
        webView.scrollView.bounces = false
        webView.scrollView.bouncesZoom = false
        webView.translatesAutoresizingMaskIntoConstraints = false
        return webView
    }()
    
    private lazy var locationManager: CLLocationManager = {
        let manager = CLLocationManager()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization()
        return manager
    }()
    
    // MARK: - Initializer and Lifecycle Methods -
    
    init(viewModel: HNZLocationWebViewModelType) {
        self.viewModel = viewModel
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
        setupListeners()
    }
    
    // MARK: - Private API -
    
    // MARK: Setup Methods
    
    private func setupView() {
        view.backgroundColor = .white
        view.layoutIfNeeded()
        
        view.addSubview(webView)
        
        NSLayoutConstraint.activate([
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupListeners() {
        locationManager.startUpdatingLocation()
        
        viewModel.outputs.url.bind { [weak self] in
            guard let strongSelf = self else { return }
            guard let url = $0 else { return }
            
            let request = URLRequest(url: url)
            
            strongSelf.webView.load(request)
        }
    }
}

extension HNZLocationWebViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            let script =
            "navigator.geolocation.helper.success('\(location.timestamp)', \(location.coordinate.latitude), \(location.coordinate.longitude), \(location.altitude), \(location.horizontalAccuracy), \(location.verticalAccuracy), \(location.course), \(location.speed));"
            
            webView.evaluateJavaScript(script)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let script =
        "navigator.geolocation.helper.error(2, 'Failed to get position (\(error.localizedDescription))');"
        
        webView.evaluateJavaScript(script)
    }
}

extension HNZLocationWebViewController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "locationHandler", let  messageBody = message.body as? String {
            if messageBody == "getCurrentPosition" {
                let script = """
                getLocation(\(locationManager.location?.coordinate.latitude ?? 0) ,\(locationManager.location?.coordinate.longitude ?? 0));
                alert('hey1234'); alert(this.id);
                """
                
                webView.evaluateJavaScript(script)
            }
        } else if message.name == "listenerAdded" {
            listenersCount += 1
            
            if !locationServicesIsEnabled {
                let script =
                "navigator.geolocation.helper.error(2, 'Location service disabled');"
                
                webView.evaluateJavaScript(script)
            } else if authorizationStatusIsDenied {
                let script =
                "navigator.geolocation.helper.error(1, 'App does not have location permission');"
                
                webView.evaluateJavaScript(script)
            } else if authorizationStatusNeedRequest {
                locationManager.requestWhenInUseAuthorization()
            } else if authorizationStatusIsGranted {
                locationManager.startUpdatingLocation()
            }
        } else if message.name == "listenerRemoved" {
            listenersCount -= 1
            
            // chack if no listener left in to wait for position
            if listenersCount == 0 {
                locationManager.stopUpdatingLocation()
            }
        }
    }
}

extension HNZLocationWebViewController {
    private var locationServicesIsEnabled: Bool {
        return CLLocationManager.locationServicesEnabled() ? true : false
    }
    
    private var authorizationStatusNeedRequest: Bool {
        return CLLocationManager.authorizationStatus() == .notDetermined ? true : false
    }
    
    private var authorizationStatusIsGranted: Bool {
        return (status == .authorizedAlways || status == .authorizedWhenInUse) ? true : false
    }
    
    private var authorizationStatusIsDenied: Bool {
        return (status == .restricted || status == .denied) ? true : false
    }
}

extension HNZLocationWebViewController: WKUIDelegate, WKNavigationDelegate, UIScrollViewDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        //        let script = "window.webkit.messageHandlers.locationHandler.postMessage('getCurrentPosition');"
        //
        //        webView.evaluateJavaScript(script)
        //
        //        print("loaded!!!!!")
    }
    
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        let title = NSLocalizedString("OK", comment: "ok Button")
        
        let ok = UIAlertAction(title: title, style: .default) { (action: UIAlertAction) -> Void in
            alert.dismiss(animated: true, completion: nil)
        }
        
        alert.addAction(ok)
        present(alert, animated: true)
        
        completionHandler()
    }
}

