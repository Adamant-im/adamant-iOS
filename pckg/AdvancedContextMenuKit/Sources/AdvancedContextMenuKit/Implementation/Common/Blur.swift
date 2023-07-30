//
//  Blur.swift
//  
//
//  Created by Stanislav Jelezoglo on 23.06.2023.
//

import SwiftUI
import Combine

struct Blur: UIViewRepresentable {
    let style: UIBlurEffect.Style
    let sensetivity: Double
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        BlurEffectView(
            effect: UIBlurEffect(style: style),
            sensivity: sensetivity
        )
    }
    
    // TODO: CommonKit
    func updateUIView(_ uiView: UIVisualEffectView, context _: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
}

class BlurEffectView: UIVisualEffectView {
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
            .publisher(for: UIApplication.willEnterForegroundNotification, object: nil)
            .receive(on: OperationQueue.main)
            .sink { [weak self] _ in
                self?.setupBlur()
            }
            .store(in: &subscriptions)
    }
}
