//
//  NotificationsView.swift
//  Adamant
//
//  Created by Yana Silosieva on 05.08.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import SwiftUI
import CommonKit

struct NotificationsView: View {
    @StateObject var viewModel: NotificationsViewModel
    private let baseSoundsView: () -> AnyView
    private let reactionSoundsView: () -> AnyView
    private let screensFactory: ScreensFactory
    
    init(
        viewModel: @escaping () -> NotificationsViewModel,
        baseSoundsView: @escaping () -> AnyView,
        reactionSoundsView: @escaping () -> AnyView,
        screensFactory: ScreensFactory
    ) {
        _viewModel = .init(wrappedValue: viewModel())
        self.baseSoundsView = baseSoundsView
        self.reactionSoundsView = reactionSoundsView
        self.screensFactory = screensFactory
    }
    
    var body: some View {
        Form {
            notificationsSection()
            messageSoundSection()
            messageReactionsSection()
            inAppNotificationsSection()
            settingsSection()
            moreDetailsSection()
        }
        .withoutListBackground()
        .background(Color(.adamant.secondBackgroundColor))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                toolbar()
            }
        }
        .sheet(isPresented: $viewModel.presentSoundsPicker, content: {
            NavigationView(content: { baseSoundsView() })
        })
        .sheet(isPresented: $viewModel.presentReactionSoundsPicker, content: {
            NavigationView(content: { reactionSoundsView() })
        })
        .fullScreenCover(isPresented: $viewModel.openSafariURL) {
            SafariWebView(url: viewModel.safariURL).ignoresSafeArea()
        }
        .fullScreenCover(isPresented: $viewModel.presentBuyAndSell) {
            screensFactory.makeBuyAndSellView(action: {
                viewModel.presentBuyAndSell = false
            })
        }
    }
}

private extension NotificationsView {
    func toolbar() -> some View {
        HStack {
            Text(viewModel.notificationsTitle)
                .font(.headline)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
        .frame(alignment: .center)
    }
    
    func notificationsSection() -> some View {
        Section {
            NavigationButton(action: { viewModel.showAlert() }) {
                HStack {
                    Text(viewModel.notificationsTitle)
                    Spacer()
                    Text(viewModel.notificationsMode.localized)
                        .foregroundColor(.gray)
                }
            }
        } header: {
            Text(viewModel.notificationsTitle)
        }
    }
    
    func messageSoundSection() -> some View {
        Section {
            NavigationButton(action: { viewModel.presentNotificationSoundsPicker() }) {
                HStack {
                    Text(soundTitle)
                    Spacer()
                    Text(viewModel.notificationSound.localized)
                        .foregroundColor(.gray)
                }
            }
        } header: {
            Text(messagesHeader)
        }
    }
    
    func messageReactionsSection() -> some View {
        Section {
            NavigationButton(action: { viewModel.presentReactionNotificationSoundsPicker() }) {
                HStack {
                    Text(soundTitle)
                    Spacer()
                    Text(viewModel.notificationReactionSound.localized)
                        .foregroundColor(.gray)
                }
            }
        } header: {
            Text(reactionsHeader)
        }
    }
    
    func inAppNotificationsSection() -> some View {
        Section {
            Toggle(isOn: $viewModel.inAppSounds) {
                Text(soundsTitle)
            }
            .tint(.init(uiColor: .adamant.active))
            
            Toggle(isOn: $viewModel.inAppVibrate) {
                Text(vibrateTitle)
            }
            .tint(.init(uiColor: .adamant.active))
            
            Toggle(isOn: $viewModel.inAppToasts) {
                Text(toastsTitle)
            }
            .tint(.init(uiColor: .adamant.active))
        } header: {
            Text(inAppNotifications)
        }
    }
    
    func settingsSection() -> some View {
        Section {
            NavigationButton(action: { viewModel.openAppSettings() }) {
                HStack {
                    Text(settingsHeader)
                    Spacer()
                }
            }
        } header: {
            Text(settingsHeader)
        }
    }
    
    func moreDetailsSection() -> some View {
        Section {
            if let description = viewModel.parsedMarkdownDescription {
                Text(description)
            }
            NavigationButton(action: { viewModel.presentSafariURL() }) {
                HStack {
                    Image(uiImage: githubRowImage)
                    Text(visitGithub)
                    Spacer()
                }
            }
        }
    }
}

private let githubRowImage: UIImage = .asset(named: "row_github") ?? UIImage()

private var messagesHeader: String {
    .localized("SecurityPage.Section.Messages")
}

private var soundTitle: String {
    .localized("Notifications.Sound.Name")
}

private var settingsHeader: String {
    .localized("Notifications.Settings.System")
}

private var visitGithub: String {
    .localized("SecurityPage.Row.VisitGithub")
}

private var reactionsHeader: String {
    .localized("Notifications.Reactions.Header")
}

private var inAppNotifications: String {
    .localized("Notifications.InAppNotifications.Header")
}

private var soundsTitle: String {
    .localized("Notifications.Sounds.Name")
}

private var vibrateTitle: String {
    .localized("Notifications.Vibrate.Title")
}

private var toastsTitle: String {
    .localized("Notifications.Toasts.Title")
}
