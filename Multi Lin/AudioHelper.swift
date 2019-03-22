//
//  AudioHelper.swift
//  Avanser
//
//  Created by Suyogya Ratna Tamrakar on 2/18/19.
//  Copyright © 2019 EBPearls. All rights reserved.
//

import Foundation
import AVFoundation

class AudioHelper {
    
    class func builtinAudioDevice() -> AVAudioSessionPortDescription? {
        let builtinRoutes = [AVAudioSession.Port.builtInMic]
        return AudioHelper.audioDevice(fromTypes: builtinRoutes)
    }
    
    class func speakerAudioDevice() -> AVAudioSessionPortDescription? {
        let builtinRoutes = [AVAudioSession.Port.builtInSpeaker]
        return AudioHelper.audioDevice(fromTypes: builtinRoutes)
    }
    
    class func audioDevice(fromTypes types: [Any]?) -> AVAudioSessionPortDescription? {
        let routes = AVAudioSession.sharedInstance().availableInputs
        for route: AVAudioSessionPortDescription? in routes ?? [] {
            if let portType = route?.portType {
                if (types as NSArray?)?.contains(portType) ?? false {
                    return route
                }
            }
        }
        return nil
    }
}
