//
//  State.swift
//  Promise
//
//  Created by wegie on 2016/04/29.
//  Copyright © 2016年 wegie. All rights reserved.
//

import Foundation

enum State<T> {
    case Pending(Handlers<State<T>>)
    case Fullfilled(T)
    case Rejected(ErrorType)
}
