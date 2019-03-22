//
//  LinphoneManager.swift
//  Multi Lin
//
//  Created by Suyogya Ratna Tamrakar on 3/19/19.
//  Copyright © 2019 Suyogya Ratna Tamrakar. All rights reserved.
//

import Foundation

class LinphoneManager {
    
    static let shared = LinphoneManager()
    
    // Contains Core object and vTable object
    let linphone: Linphone
    private var timer: Timer?
    
    var onCallStateChanged: ((LinPhoneCallStateObject) -> ())!
    
    var proxyConfigs: [ProxyConfig] = [] {
        didSet {
            debugPrint("Current Proxy Configs: \(proxyConfigs)")
        }
    }
    
    let registrationStateChanged: LinphoneCoreRegistrationStateChangedCb = { (core, config, state, message) in
        let regObject = LinPhoneRegistrationStateObject(linPhoneCore: core, linPhoneConfig: config, state: state, message: message)
        switch state {
        case LinphoneRegistrationNone: print("state: none")
        case LinphoneRegistrationProgress: print("state: progress")
        case LinphoneRegistrationOk: print("state: ok")
        case LinphoneRegistrationCleared: print("state: cleared")
        case LinphoneRegistrationFailed: print("state: failed")
        default: break
        }
    }
    
    let callStateChanged: LinphoneCoreCallStateChangedCb = {(core, call, state, message) in
        let callStateObject = LinPhoneCallStateObject(linPhoneCore: core, linPhoneCall: call, state: state, message: message)
        LinphoneManager.shared.onCallStateChanged(callStateObject)
        debugPrint(linphone_call_state_to_string(state))
    }
    
    private init() {
        
        // Assign callback states
        var vTable = LinphoneCoreVTable()
        vTable.registration_state_changed = registrationStateChanged
        vTable.call_state_changed = callStateChanged
        
        // Config parameters
        let configFileName = LinphoneManager.getDocument(file: "linphonerc")
        let configFileNamePtr = UnsafeMutablePointer<Int8>(mutating: (configFileName as NSString).utf8String)!
        let factoryConfigFileName = LinphoneManager.getBundle(file: "linphonerc-factory", ofType: nil)
        let factoryConfigFileNamePtr = UnsafeMutablePointer<Int8>(mutating: (factoryConfigFileName as NSString).utf8String)!
        let linphoneConfig = linphone_config_new_with_factory(configFileNamePtr, factoryConfigFileNamePtr)!
        let factory = linphone_factory_get()
        let cbs = linphone_factory_create_core_cbs(factory)
    
        linphone_core_cbs_set_registration_state_changed(cbs, registrationStateChanged)
        linphone_core_cbs_set_call_state_changed(cbs, callStateChanged)
        
        // Create Core
        let core = linphone_factory_create_core_with_config_3(factory, linphoneConfig, nil)!
        linphone_core_add_callbacks(core, cbs)
        linphone_core_start(core)
        
        // Let Core handle cbs
        linphone_core_cbs_unref(cbs)
        
        // Set ring asset
        if let ringbackPath = Bundle.main.path(forResource: "ringback", ofType: "wav") {
            debugPrint("RingbackPath: \(ringbackPath)")
            linphone_core_set_ringback(core, ringbackPath)
        }
        
        // Local Ringtone
        if let localRingbackPath = Bundle.main.path(forResource: "toy-mono", ofType: "wav") {
            linphone_core_set_ring(core, localRingbackPath)
        }

        // Create Linphone object with core and vTable
        self.linphone = Linphone(core: core, vTable: vTable)
        debugPrint("linphone INIT done")
    }
    
}

// MARK:- REGISTRATION
extension LinphoneManager {
    
    /// Adds newly created registered proxy config to the Store
    ///
    /// - Parameter account: Account contains Identity (username, password, domain)
    func register(account: Account) {
        guard let newProxyConfig = createProxyConfig(for: account) else {
            debugPrint("Proxy config FAILED to create, there may be existing proxy for your account")
            return
        }
        self.add(proxyConfig: newProxyConfig)
    }

    /// Creates and registers a new proxy config, doesn't if it is already available in the Store
    ///
    /// - Parameter account: Account contains Identity (username, password, domain)
    /// - Returns: Proxy config if created. If not, nil
    private func createProxyConfig(for account: Account) -> ProxyConfig? {
        
        let existingProxy = LinphoneManager.shared.proxyConfigs.filter {
            return $0.uniqueId == account.sipAddress
        }
        if existingProxy.count > 0 {
            return nil
        }
        
        let proxyConfig = linphone_core_create_proxy_config(self.linphone.core)
        
        // Parse identity
        guard let senderAddress = linphone_address_new(account.sipAddress) else {
            debugPrint("\(account.sipAddress) is not valid address")
            return nil
        }
        
        // Create authentication structure from identity and add to core
        let authInfo = linphone_auth_info_new(linphone_address_get_username(senderAddress), nil, account.password, nil, nil, nil)
        linphone_core_add_auth_info(self.linphone.core, authInfo)
        
        // Configure proxy entries
        linphone_proxy_config_set_identity_address(proxyConfig, senderAddress)  // Set Identity with username and domain
        let serverAddress = linphone_address_get_domain(senderAddress)  // Extract domain address from senderAddress
        linphone_proxy_config_set_server_addr(proxyConfig, serverAddress) // Assume domain = server address. Sets proxy address
        linphone_proxy_config_enable_register(proxyConfig, 1)   // Activate Registration for this proxy config
        
        // Release Resource
        linphone_address_unref(senderAddress)
        
        // Add a proxy configuration. This will start registration on the proxy, if registration is enabled.
        linphone_core_add_proxy_config(self.linphone.core, proxyConfig)
        linphone_core_set_default_proxy_config(self.linphone.core, proxyConfig) // Set to default proxy
        
        startTimer(for: proxyConfig)
        
        debugPrint("Created New Proxy Config")
        return ProxyConfig(config: proxyConfig, uniqueId: account.sipAddress)
        
    }
    
    
    /// Unregisters Proxy Config
    ///
    /// - Parameter proxyConfig: proxy Config
    func unregister(proxyConfig: ProxyConfig) {
        let config = proxyConfig.config
        
        linphone_proxy_config_edit(config)
        linphone_proxy_config_enable_register(config, 0)
        linphone_proxy_config_done(config)
        
        startTimer(for: config)
        
        remove(proxyConfig: proxyConfig)
    }
    
    
    /// Initiates core iteration on timed intervals
    ///
    /// - Parameter proxyCfg: proxy config to iterate core on
    private func startTimer(for proxyCfg: OpaquePointer?) {
        if linphone_proxy_config_get_state(proxyCfg) != LinphoneRegistrationCleared {
            timer = Timer.scheduledTimer(timeInterval: 0.02, target: self, selector: #selector(iterate), userInfo: nil, repeats: true)
            debugPrint("TIMER RUNNING...")
        } else {
            timer?.invalidate()
            debugPrint("TIMER INVALIDATED !!!")
        }
    }
    
    @objc private func iterate() {
        linphone_core_iterate(self.linphone.core)
    }
    
    
    /// Adds new proxy config to the Store
    ///
    /// - Parameter proxyConfig: proxy config to be added
    private func add(proxyConfig: ProxyConfig) {
        if LinphoneManager.shared.proxyConfigs.contains(proxyConfig) {
            return
        } else {
            LinphoneManager.shared.proxyConfigs.append(proxyConfig)
        }
    }

    /// Removes proxy config from the Store
    ///
    /// - Parameter proxyConfig: proxy config to be removed
    private func remove(proxyConfig: ProxyConfig) {
        for (index, config) in LinphoneManager.shared.proxyConfigs.enumerated() {
            if config.uniqueId == proxyConfig.uniqueId {
                LinphoneManager.shared.proxyConfigs.remove(at: index)
            }
        }
    }
    
    private func getProxyConfig(for account: Account) -> ProxyConfig? {
        
        for (index, config) in LinphoneManager.shared.proxyConfigs.enumerated() {
            if config.uniqueId == account.sipAddress {
                return LinphoneManager.shared.proxyConfigs[index]
            }
        }
        return nil
    }
}

// MARK: - CALL HANDLING
extension LinphoneManager {
    func makeCall(from account: Account) {
        let calleeAddress = "sip:srt@sip.linphone.org"
        
        guard let callerProxyConfig = getProxyConfig(for: account) else {
            debugPrint("Caller Proxy Config not found")
            return
        }
        
        // Set caller proxy config to default proxy config
        linphone_core_set_default_proxy_config(self.linphone.core, callerProxyConfig.config)
        
        // Place an outgoing call
        guard let _ = linphone_core_invite(self.linphone.core, calleeAddress) else {
            debugPrint("Could not place call to \(calleeAddress)")
            return
        }
        //linphone_call_ref(call)
        debugPrint("Call to \(calleeAddress) in progress...")
        
        startTimer(for: callerProxyConfig.config)
    }
    
    func terminateCall() {
        
    }
}

// MARK: - FILE MANAGER
extension LinphoneManager {
    static func getBundle(file: String, ofType type: String?) -> String {
        return Bundle.main.path(forResource: file, ofType: type)!
    }
    
    static func getDocument(file: String) -> String {
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        return (path as NSString).appendingPathComponent(file)
    }
}
