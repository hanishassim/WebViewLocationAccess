//
//  HNZLocationWebViewModel.swift
//  WebViewLocationAccess
//
//  Created by Hanis Hassim on 01/05/2020.
//  Copyright © 2020 H. All rights reserved.
//

import Foundation

protocol HNZLocationWebViewModelInputs { }

protocol HNZLocationWebViewModelOutputs {
    var url: Box<URL?> { get }
}

protocol HNZLocationWebViewModelType {
    var inputs: HNZLocationWebViewModelInputs { get }
    var outputs: HNZLocationWebViewModelOutputs { get }
}

class HNZLocationWebViewModel: HNZLocationWebViewModelType, HNZLocationWebViewModelInputs, HNZLocationWebViewModelOutputs {
    var inputs: HNZLocationWebViewModelInputs { return self }
    var outputs: HNZLocationWebViewModelOutputs { return self }
    
    let url: Box<URL?> = Box(nil)
    
    required convenience init(url: String) {
        self.init()
        
        outputs.url.value = URL(string: url)
    }
}

