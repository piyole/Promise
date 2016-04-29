//
//  Handlers.swift
//  Promise
//
//  Created by wegie on 2016/04/29.
//  Copyright © 2016年 wegie. All rights reserved.
//

import Foundation

class Handlers<T> {

    private var handlers: [T -> Void] = []

    func append(handler: T -> Void) {
        handlers.append(handler)
    }

}

extension Handlers : SequenceType {
    func generate() -> IndexingGenerator<[T -> Void]> {
        return handlers.generate()
    }
}