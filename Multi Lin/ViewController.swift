//
//  ViewController.swift
//  Multi Lin
//
//  Created by Suyogya Ratna Tamrakar on 3/19/19.
//  Copyright © 2019 Suyogya Ratna Tamrakar. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    var accountOne: Account!
    var accountTwo: Account!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupAccounts()
    }
    
    @IBAction func registerOneTapped(_ sender: UIButton) {
        LinphoneManager.shared.register(account: accountOne)
    }
    
    @IBAction func registerTwoTapped(_ sender: UIButton) {
        LinphoneManager.shared.register(account: accountTwo)
    }
    
    @IBAction func unRegisterOneTapped(_ sender: UIButton) {
        
        for config in LinphoneManager.shared.proxyConfigs {
            if config.uniqueId == accountOne.sipAddress {
                LinphoneManager.shared.unregister(proxyConfig: config)
            }
        }
        
    }
    
    @IBAction func unRegisterTwoTapped(_ sender: UIButton) {
        
        for config in LinphoneManager.shared.proxyConfigs {
            if config.uniqueId == accountTwo.sipAddress {
                LinphoneManager.shared.unregister(proxyConfig: config)
            }
        }
        
    }
    
    @IBAction func unRegisterAllTapped(_ sender: UIButton) {
        for config in LinphoneManager.shared.proxyConfigs {
            LinphoneManager.shared.unregister(proxyConfig: config)
        }
    }
    
    @IBAction func registerAllTapped(_ sender: UIButton) {
        LinphoneManager.shared.register(account: accountOne)
        LinphoneManager.shared.register(account: accountTwo)
    }
    
    @IBAction func callFromOneTapped(_ sender: UIButton) {
        LinphoneManager.shared.makeCall(from: accountOne)
    }
    
    @IBAction func callFromTwo(_ sender: UIButton) {
        LinphoneManager.shared.makeCall(from: accountTwo)
    }
    
}

extension ViewController {
    
    func setupAccounts() {
        
        // Start Linphone
        let manager = LinphoneManager.shared
        
        accountOne = Account(username: "suyogya", password: "password", domain: "sip.linphone.org")
        accountTwo = Account(username: "srt2", password: "password", domain: "sip.linphone.org")
        
        // Observe call state change
        manager.onCallStateChanged = { [weak self] (object) in
            guard let wSelf = self else { return }
            wSelf.handleCall(for: object)
        }
    }
    
    private func handleCall(for object: LinPhoneCallStateObject) {
        switch object.state {
        case LinphoneCallStateIncomingReceived:
            debugPrint("Incoming")
            
        case LinphoneCallStateEnd:
            debugPrint("Ended")
            
        case LinphoneCallStateError:
            debugPrint("Error: \(linphone_reason_to_string(linphone_call_get_reason(object.linPhoneCall)))")
            
        case LinphoneCallStateReleased:
            debugPrint("Released")
            
        default:
            debugPrint("Could not Handle")
        }
    }
}

