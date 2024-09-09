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
    var screensFactory: ScreensFactory
    
    init(
        viewModel: @escaping () -> NotificationsViewModel,
        screensFactory: ScreensFactory
    ) {
        _viewModel = .init(wrappedValue: viewModel())
        self.screensFactory = screensFactory
    }
    
    var body: some View {
        GeometryReader { geometry in
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
                    toolbar(maxWidth: geometry.size.width)
                }
            }
            .sheet(isPresented: $viewModel.presentSoundsPicker, content: {
                NavigationView(content: {
                    screensFactory.makeNotificationSounds(target: .baseMessage)
                })
            })
            .sheet(isPresented: $viewModel.presentReactionSoundsPicker, content: {
                NavigationView(content: {
                    screensFactory.makeNotificationSounds(target: .reaction)
                })
            })
            .fullScreenCover(isPresented: $viewModel.openSafariURL) {
                SafariWebView(url: viewModel.safariURL).ignoresSafeArea()
            }
        }
    }
}

private extension NotificationsView {
    func toolbar(maxWidth: CGFloat) -> some View {
        HStack {
            Text(viewModel.notificationsTitle)
                .font(.headline)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
        .frame(maxWidth: maxWidth - toolbarSpace, alignment: .center)
    }
    
    func notificationsSection() -> some View {
        Section {
            Button(action: {
                viewModel.showAlert()
            }, label: {
                HStack {
                    Text(viewModel.notificationsTitle)
                    Spacer()
                    Text(viewModel.notificationsMode.localized)
                        .foregroundColor(.gray)
                    NavigationLink(destination: { EmptyView() }, label: { EmptyView() }).fixedSize()
                }
            })
        } header: {
            Text(viewModel.notificationsTitle)
        }
    }
    
    func messageSoundSection() -> some View {
        Section {
            Button(action: {
                viewModel.presentNotificationSoundsPicker()
            }, label: {
                HStack {
                    Text(soundTitle)
                    Spacer()
                    Text(viewModel.notificationSound.localized)
                        .foregroundColor(.gray)
                    NavigationLink(destination: { EmptyView() }, label: { EmptyView() }).fixedSize()
                }
            })
        } header: {
            Text(messagesHeader)
        }
    }
    
    func messageReactionsSection() -> some View {
        Section {
            Button(action: {
                viewModel.presentReactionNotificationSoundsPicker()
            }, label: {
                HStack {
                    Text(soundTitle)
                    Spacer()
                    Text(viewModel.notificationReactionSound.localized)
                        .foregroundColor(.gray)
                    NavigationLink(destination: { EmptyView() }, label: { EmptyView() }).fixedSize()
                }
            })
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
            .onChange(of: viewModel.inAppSounds) { value in
                viewModel.applyInAppSounds(value: value)
            }
            
            Toggle(isOn: $viewModel.inAppVibrate) {
                Text(vibrateTitle)
            }
            .tint(.init(uiColor: .adamant.active))
            .onChange(of: viewModel.inAppVibrate) { value in
                viewModel.applyInAppVibrate(value: value)
            }
            
            Toggle(isOn: $viewModel.inAppToasts) {
                Text(toastsTitle)
            }
            .tint(.init(uiColor: .adamant.active))
            .onChange(of: viewModel.inAppToasts) { value in
                viewModel.applyInAppToasts(value: value)
            }
        } header: {
            Text(inAppNotifications)
        }
    }
    
    func settingsSection() -> some View {
        Section {
            Button(action: {
                viewModel.openAppSettings()
            }, label: {
                HStack {
                    Text(settingsHeader)
                    Spacer()
                    NavigationLink(destination: { EmptyView() }, label: { EmptyView() }).fixedSize()
                }
            })
        } header: {
            Text(settingsHeader)
        }
    }
    
    func moreDetailsSection() -> some View {
        Section {
            if let attributedString = viewModel.parseMarkdown(descriptionText) {
                Text(AttributedString(attributedString))
            }
            
            Button(action: {
                viewModel.presentSafariURL()
            }, label: {
                HStack {
                    Image(uiImage: viewModel.githubRowImage)
                    
                    Text(visitGithub)
                    
                    Spacer()
                    
                    NavigationLink(destination: { EmptyView() }, label: { EmptyView() }).fixedSize()
                }
                .padding()
            })
        }
    }
}

private let toolbarSpace: CGFloat = 150

private var messagesHeader: String {
    .localized("SecurityPage.Section.Messages")
}

private var soundTitle: String {
    .localized("Notifications.Sound.Name")
}

private var settingsHeader: String {
    .localized("Notifications.Settings.System")
}

private var descriptionText: String {
    .localized("SecurityPage.Row.Notifications.ModesDescription")
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
