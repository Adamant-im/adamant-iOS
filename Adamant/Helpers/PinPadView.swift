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
    enum Mode {
        case enterPin
        case createPin
        case wrongPinEntered
        case pinNotMatching
        case reenterPin
        case pinCreated
        case pinValidated
        case turnOffPin
        case turnOnBiometry
        case turnOffBiometry
    }
    @Published private(set) var mode: Mode
    @Published private var enteredPin: String = ""
    @Published private var previousEntry: String = ""
    @Published private(set) var title: String = ""
    @Published private(set) var titleColor: Color = .white
    let pinLength: Int
    private let validatePin: (String) -> Bool
    let onSuccess: () -> Void
    let onCancel: () -> Void
    
    init(
        pinLength: Int,
        mode: Mode,
        validatePin: @escaping (String) -> Bool,
        onSuccess: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.pinLength = pinLength
        self.validatePin = validatePin
        self.onSuccess = onSuccess
        self.onCancel = onCancel
        self.mode = mode
        update(mode: mode)
    }
    
    func append(_ character: String) {
        enteredPin.append(character)
    }
    
    func removeLast() {
        enteredPin.removeLast()
    }
    
    func update(mode: Mode) {
        let title: String
        let titleColor: Color
        switch mode {
        case .createPin:
            title = "Create new PIN"
            titleColor = .white
        case .enterPin:
            title = "Login into ADAMANT"
            titleColor = .white
        case .reenterPin:
            title = "Re-enter new PIN"
            titleColor = .white
        case .wrongPinEntered:
            title = "Wrong PIN entered!"
            titleColor = .red
        case .pinNotMatching:
            title = "PIN doesn't match!"
            titleColor = .red
        case .pinValidated:
            title = "Success!"
            titleColor = .green
        case .pinCreated:
            title = "PIN created!"
            titleColor = .green
        case .turnOffBiometry, .turnOffPin, .turnOnBiometry:
            title = ""
            titleColor = .white
        }
        self.title = title
        self.titleColor = titleColor
        self.mode = mode
    }
    
    func updateCache(mode: Mode) {
        switch mode {
        case .createPin:
            enteredPin.removeAll()
            previousEntry.removeAll()
        case .enterPin:
            return
        case .reenterPin:
            previousEntry = enteredPin
            enteredPin.removeAll()
        case .wrongPinEntered:
            enteredPin.removeAll()
        case .pinNotMatching:
            enteredPin.removeAll()
            previousEntry.removeAll()
        case .pinValidated:
            return
        case .pinCreated:
            return
        case .turnOffBiometry, .turnOffPin, .turnOnBiometry:
            return
        }
        self.title = title
        self.titleColor = titleColor
    }
    
    func isValid(mode: Mode) -> Bool {
        switch mode {
        case .reenterPin:
            previousEntry == enteredPin
        case .wrongPinEntered,
                .createPin,
                .enterPin,
                .pinNotMatching,
                .pinValidated,
                .pinCreated,
                .turnOffBiometry,
                .turnOffPin,
                .turnOnBiometry:
            true
        }
    }
    
    var isEmpty: Bool {
        enteredPin.isEmpty
    }
    
    var isPinEnteredCompletely: Bool {
        enteredPin.count == pinLength
    }
    
    func hasNumber(at index: Int) -> Bool {
        index < enteredPin.count
    }
    
    var isPinValid: Bool {
        validatePin(enteredPin)
    }
}

// swiftlint:disable multiple_closures_with_trailing_closure
struct PinPadView: View {
    @StateObject var viewModel: PinPadViewModel
    
    var body: some View {
        VStack {
            Spacer()
            Text(viewModel.title)
                .foregroundColor(viewModel.titleColor)
                .textCase(nil)
                .font(.body)
                .padding(.top, 30)
            
            HStack(spacing: 10) {
                ForEach(0..<viewModel.pinLength, id: \.self) { index in
                    Circle()
                        .frame(width: 15, height: 15)
                        .foregroundColor(viewModel.hasNumber(at: index) ? .white : .gray)
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
        viewModel.append(digit)
        if viewModel.isPinEnteredCompletely {
            switch viewModel.mode {
            case .enterPin:
                if viewModel.isPinValid {
                    viewModel.update(mode: .pinValidated)
                    viewModel.onSuccess()
                } else {
                    viewModel.update(mode: .wrongPinEntered)
                    Task.detached { @MainActor in
                        viewModel.update(mode: .enterPin)
                        viewModel.updateCache(mode: .enterPin)
                    }
                }
            case .createPin:
                viewModel.update(mode: .reenterPin)
                Task.detached { @MainActor in
                    try await Task.sleep(nanoseconds: 300_000_000)
                    viewModel.updateCache(mode: .reenterPin)
                }
            case .reenterPin:
                if viewModel.isValid(mode: .reenterPin) {
                    viewModel.update(mode: .pinCreated)
                    Task.detached { @MainActor in
                        try await Task.sleep(nanoseconds: 100_000_000)
                        viewModel.updateCache(mode: .pinCreated)
                        viewModel.onSuccess()
                    }
                } else {
                    viewModel.update(mode: .pinNotMatching)
                    Task.detached { @MainActor in
                        try await Task.sleep(nanoseconds: 500_000_000)
                        viewModel.update(mode: .createPin)
                        viewModel.updateCache(mode: .createPin)
                    }
                }
            case .turnOffBiometry,
                    .turnOffPin,
                    .turnOnBiometry,
                    .pinCreated,
                    .wrongPinEntered,
                    .pinNotMatching,
                    .pinValidated:
                return
            }
        }
    }
    
    private func deleteLastDigit() {
        guard !viewModel.isEmpty else { return }
        viewModel.removeLast()
    }
}

#if DEBUG
#Preview {
    PinPadView(
        viewModel:
            PinPadViewModel(
                pinLength: 6,
                mode: .createPin,
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
