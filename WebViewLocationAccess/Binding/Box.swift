//
//  Box.swift
//  WebViewLocationAccess
//
//  Created by Hanis Hassim on 01/05/2020.
//  Copyright © 2020 H. All rights reserved.
//

import Foundation

public class Box<T> {
    public typealias Listener = (T) -> Void
    private var listener: Listener?
    
    public var value: T {
        didSet {
            listener?(value)
        }
    }
    
    public init(_ value: T) {
        self.value = value
    }
    
    public func bind(_ listener: Listener?) {
        self.listener = listener
        listener?(value)
    }
}
