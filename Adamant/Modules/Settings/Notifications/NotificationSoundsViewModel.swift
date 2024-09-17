//
//  NotificationSoundsViewModel.swift
//  Adamant
//
//  Created by Yana Silosieva on 20.08.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import SwiftUI
import CommonKit
import Combine
import AVFoundation

@MainActor
final class NotificationSoundsViewModel: ObservableObject {
    private let notificationsService: NotificationsService
    private var notificationTarget: NotificationTarget
    
    private(set) var dismissAction = PassthroughSubject<Void,Never>()
    @Published var isPresented: Bool = false
    @Published var selectedSound: NotificationSound = .inputDefault
    @Published var sounds: [NotificationSound] = [.none, .noteDefault, .inputDefault, .proud, .relax, .success, .note, .antic, .cheers, .chord, .droplet, .handoff, .milestone, .passage, .portal, .rattle, .rebound, .slide, .welcome]
    
    private var audioPlayer: AVAudioPlayer?
    
    nonisolated init(
        notificationsService: NotificationsService,
        target: NotificationTarget
    ) {
        self.notificationsService = notificationsService
        self.notificationTarget = target
        
        Task { @MainActor in
            switch notificationTarget {
            case .baseMessage:
                self.selectedSound = notificationsService.notificationsSound
            case .reaction:
                self.selectedSound = notificationsService.notificationsReactionSound
            }
        }
    }
    
    func setup(notificationTarget: NotificationTarget) {
        self.notificationTarget = notificationTarget
    }
    
    func save() {
        setNotificationSound(selectedSound)
        dismissAction.send()
    }
    
    func setNotificationSound(_ sound: NotificationSound) {
        notificationsService.setNotificationSound(sound, for: notificationTarget)
    }
    
    func selectSound(_ sound: NotificationSound) {
        selectedSound = sound
        playSound(sound)
    }
    
    func playSound(_ sound: NotificationSound) {
            switch sound {
            case .none:
                break
            default:
                playSound(by: sound.fileName)
            }
        }
    
    private func playSound(by fileName: String) {
        guard let url = Bundle.main.url(forResource: fileName.replacingOccurrences(of: ".mp3", with: ""), withExtension: "mp3") else {
            return
        }

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true)
            audioPlayer = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.mp3.rawValue)
            audioPlayer?.volume = 1.0
            audioPlayer?.play()
        } catch let error as NSError {
            print("error: \(error.localizedDescription)")
        }
    }
}
