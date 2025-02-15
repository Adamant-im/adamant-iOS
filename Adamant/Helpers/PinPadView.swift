//
//  StyledPinpadView.swift
//  Adamant
//
//  Created by Brian on 23/01/2025.
//  Copyright © 2025 Adamant. All rights reserved.
//

import SwiftUI

struct PinPadViewRepresentable: UIViewRepresentable {
    let pinLength: Int
    let validatePin: (String) -> Bool
    let onSuccess: () -> Void
    let onCancel: () -> Void

    func makeUIView(context: Context) -> UIView {
        let hostingController = UIHostingController(
            rootView: PinPadView(
                viewModel:
                    PinPadViewModel(
                        pinLength: pinLength,
                        validatePin: validatePin,
                        onSuccess: onSuccess,
                        onCancel: onCancel
                    )
            )
        )
        return hostingController.view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // Handle updates to the view if needed
    }
}

class PinPadViewModel: ObservableObject {
    @Published var enteredPin: String = ""
    let pinLength: Int
    let validatePin: (String) -> Bool
    let onSuccess: () -> Void
    let onCancel: () -> Void
    
    init(
        pinLength: Int,
        validatePin: @escaping (String) -> Bool,
        onSuccess: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.pinLength = pinLength
        self.validatePin = validatePin
        self.onSuccess = onSuccess
        self.onCancel = onCancel
    }
    
    func append(_ text: String) {
        enteredPin.append(text)
    }
}

// swiftlint:disable multiple_closures_with_trailing_closure
struct PinPadView: View {
    
    enum PinPadViewMode {
        case createPin
        case reenterPin(pin: String)
        case turnOffPin
        case turnOnBiometry
        case turnOffBiometry
    }
    
    @StateObject var viewModel: PinPadViewModel
    
    var body: some View {
        VStack {
            Spacer()
            Text("Login into ADAMANT")
                .foregroundColor(.white)
                .textCase(nil)
                .font(.body)
                .padding(.top, 30)
            
            HStack(spacing: 10) {
                ForEach(0..<viewModel.pinLength, id: \.self) { index in
                    Circle()
                        .frame(width: 15, height: 15)
                        .foregroundColor(index < viewModel.enteredPin.count ? .white : .gray)
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
            Button("Cancel") {
                viewModel.onCancel()
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
        guard viewModel.enteredPin.count < viewModel.pinLength else { return }
        viewModel.enteredPin.append(digit)
        if viewModel.enteredPin.count == viewModel.pinLength {
            if viewModel.validatePin(viewModel.enteredPin) {
                viewModel.onSuccess()
            } else {
                viewModel.enteredPin.removeAll()
            }
        }
    }

    private func deleteLastDigit() {
        guard !viewModel.enteredPin.isEmpty else { return }
        viewModel.enteredPin.removeLast()
    }
}

#if DEBUG
#Preview {
    PinPadView(
        viewModel:
            PinPadViewModel(
                pinLength: 6,
                validatePin:
                    { _ in
                        true
                    }, onSuccess: {
                        
                    }, onCancel: {
                        
                    }
            )
    )
}
#endif
