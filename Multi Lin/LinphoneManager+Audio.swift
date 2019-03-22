//
//  LinphoneManager+Audio.swift
//  Avanser
//
//  Created by Suyogya Ratna Tamrakar on 2/18/19.
//  Copyright © 2019 EBPearls. All rights reserved.
//

import UIKit
import AVFoundation

extension LinphoneManager {
    
    /// Determines if loudspeaker is allowed
    ///
    /// - Returns: True if allowed
    private func allowSpeaker() -> Bool {
        var allow = true
        let newRoute: AVAudioSessionRouteDescription = AVAudioSession.sharedInstance().currentRoute
        if newRoute.outputs.count > 0 {
            let route = newRoute.outputs[0].portType
            allow = !((route == .lineOut) || (route == .headphones))
        }
        return allow
    }
    
    /// Enable / Disable loudspeaker during call
    ///
    /// - Parameter enabled: True if needs to be enabled
    func setSpeakerEnabled(_ enabled: Bool) {
        
        var err: Error?
        
        // If speaker needs to be enabled
        if enabled && LinphoneManager.shared.allowSpeaker() {
            try? AVAudioSession.sharedInstance().overrideOutputAudioPort(AVAudioSession.PortOverride.speaker)
            UIDevice.current.isProximityMonitoringEnabled = false
        } else {
            let builtinPort: AVAudioSessionPortDescription? = AudioHelper.builtinAudioDevice()
            try? AVAudioSession.sharedInstance().setPreferredInput(builtinPort)
            UIDevice.current.isProximityMonitoringEnabled = (linphone_core_get_calls_nb(linphone.core) > 0)
        }
        
        if let routeError = err {
            debugPrint("Failed to change audio route: \(routeError.localizedDescription)")
            err = nil
        }
    }
    
    /// Enable / Disable microphone during call
    ///
    /// - Parameter enabled: True if needs to be enabled
    func setMicEnabled(_ enabled: Bool) {
        let micEnabled = enabled ? 1 : 0
        linphone_core_enable_mic(linphone.core, bool_t(micEnabled))
    }
    
}
