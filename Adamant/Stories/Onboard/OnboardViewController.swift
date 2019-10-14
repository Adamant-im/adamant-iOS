//
//  OnboardViewController.swift
//  Adamant
//
//  Created by Anton Boyarkin on 04/09/2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import SwiftyOnboard
import SafariServices

fileprivate class OnboardingPageItem {
    var image: UIImage
    var text: String
    
    init(image: UIImage, text: String) {
        self.image = image
        self.text = text
    }
}

fileprivate extension String.adamantLocalized {
    struct Onboard {
        static let beginButton = NSLocalizedString("WelcomeScene.Description.BeginButton", comment: "Welcome: Last slide Begin button")
        static let continueButton = NSLocalizedString("WelcomeScene.Description.ContinueButton", comment: "Welcome: Next screen button")
        static let skipButton = NSLocalizedString("WelcomeScene.Description.SkipButton", comment: "Welcome: Skip button")
        
        private init() {}
    }
}

class OnboardViewController: UIViewController {
    
    // MARK: Constants
    private static let titleFont = UIFont.adamantPrimary(ofSize: 18)
    private static let buttonsFont = UIFont.adamantPrimary(ofSize: 16)
    private static let themeColor = UIColor.adamant.primary
    
    
    // MARK: Outlets
    @IBOutlet weak var onboarding: SwiftyOnboard!
    @IBOutlet var skipButton: UIButton!
    
    // MARK: Properties
    fileprivate let items = [
        OnboardingPageItem(image: #imageLiteral(resourceName: "SlideImage1"),
                           text: NSLocalizedString("WelcomeScene.Description.Slide1", comment: "Welcome: Slide 1 Description")),

        OnboardingPageItem(image: #imageLiteral(resourceName: "SlideImage2"),
                           text: NSLocalizedString("WelcomeScene.Description.Slide2", comment: "Welcome: Slide 2 Description")),

        OnboardingPageItem(image: #imageLiteral(resourceName: "SlideImage3"),
                           text: NSLocalizedString("WelcomeScene.Description.Slide3", comment: "Welcome: Slide 3 Description")),

        OnboardingPageItem(image: #imageLiteral(resourceName: "SlideImage4"),
                           text: NSLocalizedString("WelcomeScene.Description.Slide4", comment: "Welcome: Slide 4 Description")),

        OnboardingPageItem(image: #imageLiteral(resourceName: "SlideImage5"),
                           text: NSLocalizedString("WelcomeScene.Description.Slide5", comment: "Welcome: Slide 5 Description"))
        ]

    override func viewDidLoad() {
        super.viewDidLoad()
        
        onboarding.delegate = self
        onboarding.dataSource = self
        onboarding.backgroundColor = UIColor(patternImage: #imageLiteral(resourceName: "stripeBg"))//UIColor.adamant.background
    }
    
    @objc func handleSkip() {
        DispatchQueue.main.async { [weak self] in
            self?.dismiss(animated: true, completion: nil)
        }
    }
    
    @objc func handleContinue() {
        DispatchQueue.main.async { [weak self] in
            guard let onboarding = self?.onboarding else {
                return
            }
            
            if let count = self?.items.count, onboarding.currentPage == count - 1 {
                self?.handleSkip()
            } else {
                onboarding.goToPage(index: onboarding.currentPage + 1, animated: true)
            }
        }
    }
}

// MARK: SwiftyOnboard Delegate & DataSource

extension OnboardViewController: SwiftyOnboardDelegate, SwiftyOnboardDataSource {
    
    func swiftyOnboardNumberOfPages(_ swiftyOnboard: SwiftyOnboard) -> Int {
        return items.count
    }
    
    func swiftyOnboardPageForIndex(_ swiftyOnboard: SwiftyOnboard, index: Int) -> SwiftyOnboardPage? {
        let item = items[index]
        
        guard let view = OnboardPage.instanceFromNib() as? OnboardPage else {
            return nil
        }
        
        view.image.image = item.image
        view.text.delegate = self
        
        // Font & size logic moved to OnboardPage
        view.rawRichText = item.text
        
        return view
    }
    
    func swiftyOnboardViewForOverlay(_ swiftyOnboard: SwiftyOnboard) -> SwiftyOnboardOverlay? {
        let overlay = SwiftyOnboardOverlay()
        
        //Setup targets for the buttons on the overlay view:
        overlay.skipButton.addTarget(self, action: #selector(handleSkip), for: .touchUpInside)
        overlay.continueButton.addTarget(self, action: #selector(handleContinue), for: .touchUpInside)
        
        //Setup for the overlay buttons:
        overlay.continueButton.titleLabel?.font = OnboardViewController.buttonsFont
        overlay.continueButton.setTitle(String.adamantLocalized.Onboard.continueButton, for: .normal)
        
        overlay.skipButton.titleLabel?.font = OnboardViewController.buttonsFont
        overlay.skipButton.setTitle(String.adamantLocalized.Onboard.skipButton, for: .normal)
        
        return overlay
    }
    
    func swiftyOnboardOverlayForPosition(_ swiftyOnboard: SwiftyOnboard, overlay: SwiftyOnboardOverlay, for position: Double) {
        let currentPage = Int(round(position))
        overlay.pageControl.currentPage = currentPage
        
        if currentPage == items.count - 1 {
            overlay.skipButton.isHidden = true
            overlay.continueButton.setTitle(String.adamantLocalized.Onboard.beginButton, for: .normal)
        } else {
            overlay.skipButton.isHidden = false
            overlay.continueButton.setTitle(String.adamantLocalized.Onboard.continueButton, for: .normal)
        }
    }
}


// MARK: - UITextViewDelegate
extension OnboardViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        let safari = SFSafariViewController(url: URL)
        safari.preferredControlTintColor = UIColor.adamant.primary
        safari.modalPresentationStyle = .overFullScreen
        present(safari, animated: true, completion: nil)
        return false
    }
}
