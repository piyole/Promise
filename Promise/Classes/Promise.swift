//
//  Promise.swift
//  Promise
//
//  Created by wegie on 2016/04/29.
//  Copyright © 2016年 wegie. All rights reserved.
//

import Foundation

public class Promise<T> {

    private var lock: NSRecursiveLock = NSRecursiveLock()

    private var state: State<T> = .Pending(Handlers()) {
        didSet {
            if case .Pending(let handlers) = oldValue {
                handlers.forEach { handler in handler(self.state) }
            }
        }
    }

    private lazy var resolve: T -> Void = { value in
        self.lock.lock()
        if case .Pending = self.state {
            self.state = .Fullfilled(value)
        }
        self.lock.unlock()
    }

    private lazy var reject: ErrorType -> Void = { error in
        self.lock.lock()
        if case .Pending = self.state {
            self.state = .Rejected(error)
        }
        self.lock.unlock()
    }

    public init(@noescape _ executor: (T -> Void, ErrorType -> Void) throws -> Void) {
        do {
            try executor(resolve, reject)
        } catch {
            reject(error)
        }
    }

}

extension Promise {

    public func then(onFullfilled: T -> Void) -> Promise<T> {
        return then(onFullfilled) { _ in }
    }

    public func then(onFullfilled: T -> Void, _ onRejected: ErrorType -> Void) -> Promise<T> {
        return Promise<T>(when: self) { state, resolve, reject in
            switch state {
            case .Fullfilled(let value):
                onFullfilled(value)
                resolve(value)
            case .Rejected(let error):
                onRejected(error)
                reject(error)
            default: ()
            }
        }
    }

    public func then<U>(onFullfilled: T -> U) -> Promise<U> {
        return then(onFullfilled) { _ in }
    }

    public func then<U>(onFullfilled: T -> U, _ onRejected: ErrorType -> Void) -> Promise<U> {
        return Promise<U>(when: self) { state, resolve, reject in
            switch state {
            case .Fullfilled(let value):
                let newValue = onFullfilled(value)
                resolve(newValue)
            case .Rejected(let error):
                onRejected(error)
                reject(error)
            default: ()
            }
        }
    }

    public func then<U>(onFullfilled: T -> Promise<U>) -> Promise<U> {
        return then(onFullfilled) { _ in }
    }

    public func then<U>(onFullfilled: T -> Promise<U>, _ onRejected: ErrorType -> Void) -> Promise<U> {
        return Promise<U>(when: self) { state, resolve, reject in
            switch state {
            case .Fullfilled(let value):
                let newValue = onFullfilled(value)
                newValue.at { state in
                    switch state {
                    case .Fullfilled(let value):
                        resolve(value)
                    case .Rejected(let error):
                        reject(error)
                    default: ()
                    }
                }
            case .Rejected(let error):
                onRejected(error)
                reject(error)
            default: ()
            }
        }
    }

}

extension Promise {

    public func `catch`(onRejected: ErrorType -> Void) -> Promise<T> {
        return then({ _ in }, onRejected)
    }

}

extension Promise {

    public func always(on: () -> Void) -> Promise<T> {
        return then({ _ in on() }, { _ in on() })
    }

}

extension Promise {

    public static func resolve(value: T) -> Promise<T> {
        return Promise<T> { resolve, reject in
            resolve(value)
        }
    }

    public static func reject(error: ErrorType) -> Promise<T> {
        return Promise<T> { resolve, reject in
            reject(error)
        }
    }

    public static func race(promises: Promise<T>...) -> Promise<T> {
        return Promise<T> { resolve, reject in
            promises.forEach { $0.then({ resolve($0) }, reject) }
        }
    }

}

extension Promise {

    private convenience init<U>(when: Promise<U>, _ executor: (State<U>, T -> Void, ErrorType -> Void) -> Void) {
        self.init { resolve, reject in
            when.at { state in
                executor(state, resolve, reject)
            }
        }
    }

    private func at(handler: State<T> -> Void) {
        self.lock.lock()
        switch state {
        case .Pending(let handlers):
            handlers.append(handler)
        case .Fullfilled, .Rejected:
            handler(state)
        }
        self.lock.unlock()
    }

}
