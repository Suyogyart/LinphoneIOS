//
//  Models.swift
//  Multi Lin
//
//  Created by Suyogya Ratna Tamrakar on 3/19/19.
//  Copyright © 2019 Suyogya Ratna Tamrakar. All rights reserved.
//

import Foundation

// Assuming that there is only 1 core and 1 vTable in whole app
// We will then create new proxy config, each one for each account
//
class Linphone {
    let core: OpaquePointer
    let vTable: LinphoneCoreVTable
    
    init(core: OpaquePointer, vTable: LinphoneCoreVTable) {
        self.core = core
        self.vTable = vTable
    }
}

// Contains user credential
// For connecting to sip server
// For registration
class Account {
    let username: String
    let password: String
    let domain: String

    init(username: String, password: String, domain: String) {
        self.username = username
        self.password = password
        self.domain = domain
    }
    
    var sipAddress: String {
        return "sip:\(username)@\(domain)"
    }
}

// For Callback state
struct LinPhoneCallStateObject {
    let linPhoneCore: OpaquePointer?
    let linPhoneCall: OpaquePointer?
    let state: LinphoneCallState
    let message: UnsafePointer<Int8>?
}

// For Registration state
struct LinPhoneRegistrationStateObject {
    let linPhoneCore: OpaquePointer?
    let linPhoneConfig: OpaquePointer?
    let state: LinphoneRegistrationState
    let message: UnsafePointer<Int8>?
}

struct ProxyConfig: Equatable {
    let config: OpaquePointer?
    let uniqueId: String
    
    init(config: OpaquePointer?, uniqueId: String) {
        self.config = config
        self.uniqueId = uniqueId
    }
    
    static func == (lhs: ProxyConfig, rhs: ProxyConfig) -> Bool {
        return lhs.config == rhs.config && lhs.uniqueId == rhs.uniqueId
    }
}
