//
//  NotificationSoundsView.swift
//  Adamant
//
//  Created by Yana Silosieva on 20.08.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import SwiftUI
import CommonKit

struct NotificationSoundsView: View {
    @ObservedObject var viewModel: NotificationSoundsViewModel
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        GeometryReader { _ in
            Form {
                Section {
                    listSounds()
                } header: {
                    Text(alertHeader)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                        dismiss()
                    }, label: {
                        HStack {
                            Text(cancelTitle)
                        }
                    })
                }
                
                ToolbarItem(placement: .principal) {
                    Text(toolbarTitle)
                        .font(.headline)
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        viewModel.save()
                    }, label: {
                        HStack {
                            Text(saveTitle)
                        }
                    })
                }
            }
            .onReceive(viewModel.dismissAction) {
                dismiss()
            }
        }
    }
}

private extension NotificationSoundsView {
    func toolbar() -> some View {
        HStack {
            Button(action: {
                dismiss()
            }, label: {
                HStack {
                    Text(cancelTitle)
                }
            })
            
            Spacer()
            
            Text(toolbarTitle)
                .font(.headline)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .center)
            
            Spacer()
            
            Button(action: {
                viewModel.save()
            }, label: {
                HStack {
                    Text(saveTitle)
                }
            })
        }
    }
    
    func listSounds() -> some View {
        List {
            ForEach(viewModel.sounds, id: \.self) { sound in
                Button(
                    action: { viewModel.selectSound(sound) },
                    label: {
                        HStack {
                            Text(sound.localized)
                            Spacer()
                            if viewModel.selectedSound == sound {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.black)
                                    .frame(width: 30, height: 30)
                            }
                        }
                    }
                )
            }
        }
    }
}

private var toolbarTitle: String {
    .localized("Notifications.Sounds.Name")
}

private var cancelTitle: String {
    .localized("Notifications.Alert.Cancel")
}

private var saveTitle: String {
    .localized("Notifications.Alert.Save")
}

private var alertHeader: String {
    .localized("Notifications.Alert.Tones")
}
