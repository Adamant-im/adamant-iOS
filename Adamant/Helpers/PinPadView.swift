//
//  StyledPinpadView.swift
//  Adamant
//
//  Created by Brian on 23/01/2025.
//  Copyright © 2025 Adamant. All rights reserved.
//

import SwiftUI

struct PinPadViewRepresentable: UIViewRepresentable {
    @Binding var enteredPin: String
    let pinLength: Int
    let validatePin: (String) -> Bool
    let onSuccess: () -> Void
    let onCancel: () -> Void

    func makeUIView(context: Context) -> UIView {
        let hostingController = UIHostingController(
            rootView: PinPadView(
                enteredPin: $enteredPin,
                pinLength: pinLength,
                validatePin: validatePin,
                onSuccess: onSuccess,
                onCancel: onCancel
            )
        )
        return hostingController.view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // Handle updates to the view if needed
    }
}

// swiftlint:disable multiple_closures_with_trailing_closure
struct PinPadView: View {
    @Binding var enteredPin: String
    @State var isPinpadVisible: Bool = true
    let pinLength: Int
    let validatePin: (String) -> Bool
    let onSuccess: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack {
            Spacer()
            Text("Login into ADAMANT")
                .foregroundColor(.white)
                .textCase(nil)
                .font(.body)
                .padding(.top, 30)
            
            HStack(spacing: 10) {
                ForEach(0..<pinLength, id: \.self) { index in
                    Circle()
                        .frame(width: 15, height: 15)
                        .foregroundColor(index < enteredPin.count ? .white : .gray)
                }
            }
            .padding(.vertical, 20)
            Spacer()
                .frame(height: 20)
            VStack(alignment: .center) {
                row(from: 1, to: 3)
                row(from: 4, to: 6)
                row(from: 7, to: 9)
                row(from: 0, to: 0, showsDeleteButton: true)
            }
            Spacer()
            Button(String.adamant.alert.cancel) {
                onCancel()
                isPinpadVisible = false
            }
            .foregroundColor(.white)
            .padding(.top, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.edgesIgnoringSafeArea(.all))
    }
    
    private func row(from: Int, to: Int, showsDeleteButton: Bool = false) -> some View {
        HStack {
            if showsDeleteButton {
                Circle()
                    .frame(width: 75, height: 75)
                    .foregroundColor(.clear)
            }
            ForEach(from...to, id: \.self) { number in
                Button(action: {
                    handlePinInput("\(number)")
                }) {
                    Circle()
                        .frame(width: 75, height: 75)
                        .overlay(
                            Text("\(number)")
                                .foregroundColor(.white)
                                .font(.title)
                        )
                        .foregroundColor(.clear)
                        .overlay(Circle().stroke(Color.white, lineWidth: 1))
                }
            }
            if showsDeleteButton {
                Button(action: deleteLastDigit) {
                    Circle()
                        .frame(width: 75, height: 75)
                        .overlay(
                            Image(systemName: "delete.left")
                                .foregroundColor(.white)
                                .font(.title)
                        )
                        .foregroundColor(.clear)
                        .overlay(Circle().stroke(Color.white, lineWidth: 1))
                }
            }
        }
    }
    
    private func handlePinInput(_ digit: String) {
        guard enteredPin.count < pinLength else { return }
        enteredPin.append(digit)
        if enteredPin.count == pinLength {
            if validatePin(enteredPin) {
                onSuccess()
                isPinpadVisible = false
            } else {
                enteredPin.removeAll()
            }
        }
    }

    private func deleteLastDigit() {
        guard !enteredPin.isEmpty else { return }
        enteredPin.removeLast()
    }
}

#if DEBUG

private struct Placeholder {
    @State var enteredPin: String = ""
}

#Preview {
    PinPadView(
        enteredPin: Placeholder().$enteredPin,
        pinLength: 6
    ) { _ in
            true
        } onSuccess: {
            
        } onCancel: {
            
        }
}

#endif
