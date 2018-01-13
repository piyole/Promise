//
//  Promise.swift
//  Promise
//
//  Created by wegie on 2016/04/29.
//  Copyright © 2016年 wegie. All rights reserved.
//

import Foundation

public typealias Handler<T> = (T) -> Void
public typealias ErrorHandler = (Error) -> Void

public final class Promise<T> {

    fileprivate typealias Handlers<T> = [Handler<T>]

    fileprivate enum State<T> {
        case pending(Handlers<State<T>>)
        case fullfilled(T)
        case rejected(Error)
    }

    private var lock: NSRecursiveLock = NSRecursiveLock()

    private var state: State<T> = .pending(Handlers()) {
        didSet {
            if case .pending(let handlers) = oldValue {
                handlers.forEach { handler in handler(self.state) }
            }
        }
    }

    private lazy var resolve: Handler<T> = { value in
        self.lock.lock()
        if case .pending = self.state {
            self.state = .fullfilled(value)
        }
        self.lock.unlock()
    }

    private lazy var reject: ErrorHandler = { error in
        self.lock.lock()
        if case .pending = self.state {
            self.state = .rejected(error)
        }
        self.lock.unlock()
    }

    public init(_ executor: (@escaping Handler<T>, @escaping ErrorHandler) throws -> Void) {
        do {
            try executor(resolve, reject)
        } catch {
            reject(error)
        }
    }

}

extension Promise {

    public func then(_ onfullfilled: @escaping Handler<T>) -> Promise<T> {
        return then(onfullfilled) { _ in }
    }

    public func then(_ onfullfilled: @escaping Handler<T>, _ onrejected: @escaping ErrorHandler) -> Promise<T> {
        return Promise<T>(when: self) { state, resolve, reject in
            switch state {
            case .fullfilled(let value):
                onfullfilled(value)
                resolve(value)
            case .rejected(let error):
                onrejected(error)
                reject(error)
            default: ()
            }
        }
    }

    public func then<U>(_ onfullfilled: @escaping (T) -> U) -> Promise<U> {
        return then(onfullfilled) { _ in }
    }

    public func then<U>(_ onfullfilled: @escaping (T) -> U, _ onrejected: @escaping ErrorHandler) -> Promise<U> {
        return Promise<U>(when: self) { state, resolve, reject in
            switch state {
            case .fullfilled(let value):
                let newValue = onfullfilled(value)
                resolve(newValue)
            case .rejected(let error):
                onrejected(error)
                reject(error)
            default: ()
            }
        }
    }

    public func then<U>(_ onfullfilled: @escaping (T) -> Promise<U>) -> Promise<U> {
        return then(onfullfilled) { _ in }
    }

    public func then<U>(_ onfullfilled: @escaping (T) -> Promise<U>, _ onrejected: @escaping ErrorHandler) -> Promise<U> {
        return Promise<U>(when: self) { state, resolve, reject in
            switch state {
            case .fullfilled(let value):
                let newValue = onfullfilled(value)
                newValue.at { state in
                    switch state {
                    case .fullfilled(let value):
                        resolve(value)
                    case .rejected(let error):
                        reject(error)
                    default: ()
                    }
                }
            case .rejected(let error):
                onrejected(error)
                reject(error)
            default: ()
            }
        }
    }

}

extension Promise {

    public func `catch`(onrejected: @escaping ErrorHandler) -> Promise<T> {
        return then({ _ in }, onrejected)
    }

}

extension Promise {

    public func always(on: @escaping () -> Void) -> Promise<T> {
        return then({ _ in on() }, { _ in on() })
    }

}

extension Promise {

    public static func resolve(value: T) -> Promise<T> {
        return Promise<T> { resolve, reject in
            resolve(value)
        }
    }

    public static func reject(error: Error) -> Promise<T> {
        return Promise<T> { resolve, reject in
            reject(error)
        }
    }

    public static func race(promises: Promise<T>...) -> Promise<T> {
        return Promise<T> { resolve, reject in
            promises.forEach { _ = $0.then({ resolve($0) }, reject) }
        }
    }

}

extension Promise {

    private convenience init<U>(when: Promise<U>, _ executor: @escaping (Promise<U>.State<U>, @escaping Handler<T>, @escaping ErrorHandler) -> Void) {
        self.init { resolve, reject in
            when.at { state in
                executor(state, resolve, reject)
            }
        }
    }

    private func at(handler: @escaping (State<T>) -> Void) {
        self.lock.lock()
        switch state {
        case .pending(var handlers):
            handlers.append(handler)
        case .fullfilled, .rejected:
            handler(state)
        }
        self.lock.unlock()
    }

}
