//
//  Blur.swift
//  
//
//  Created by Andrey Golubenko on 06.12.2022.
//

import SwiftUI
import Combine

public struct Blur: UIViewRepresentable {
    private let style: UIBlurEffect.Style
    private let sensetivity: Double
    
    public func makeUIView(context: Context) -> UIVisualEffectView {
        BlurEffectView(
            effect: UIBlurEffect(style: style),
            sensivity: sensetivity
        )
    }
    
    public func updateUIView(_ uiView: UIVisualEffectView, context _: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
    
    public init(style: UIBlurEffect.Style) {
        self.style = style
        self.sensetivity = 1.0
    }
    
    public init(style: UIBlurEffect.Style, sensetivity: Double) {
        self.style = style
        self.sensetivity = sensetivity
    }
}

final class BlurEffectView: UIVisualEffectView {
    // MARK: Proprieties
    
    private var animator: UIViewPropertyAnimator?
    private var sensivity = 0.2
    private var visualEffect: UIVisualEffect?
    private var subscriptions = Set<AnyCancellable>()
    
    // MARK: Init
    
    init(effect: UIVisualEffect?, sensivity: Double) {
        super.init(effect: effect)
        self.sensivity = sensivity
        self.visualEffect = effect
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMoveToSuperview() {
        guard let superview = superview else { return }
        
        backgroundColor = .clear
        frame = superview.bounds
        
        guard animator == nil else {
            setupSensivity(sensivity: sensivity)
            return
        }
        
        setupBlur()
        addObservers()
    }
    
    func setupBlur() {
        if animator == nil {
            animator = UIViewPropertyAnimator(duration: 1, curve: .linear)
        }
        
        animator?.stopAnimation(true)
        effect = nil

        animator?.addAnimations { [weak self] in
            self?.effect = self?.visualEffect
        }
        
        animator?.fractionComplete = sensivity
    }
    
    func setupSensivity(sensivity: Double) {
        animator?.fractionComplete = sensivity
    }
    
    func addObservers() {
        NotificationCenter.default
            .notifications(named: UIApplication.willEnterForegroundNotification, object: nil)
            .sink { @MainActor [weak self] _ in
                self?.setupBlur()
            }
            .store(in: &subscriptions)
    }
}
