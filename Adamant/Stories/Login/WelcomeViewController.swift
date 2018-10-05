//
//  WelcomeViewController.swift
//  Adamant
//
//  Created by Anton Boyarkin on 04/09/2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import SwiftyOnboard

fileprivate class OnboardingPageItem {
    var image: UIImage
    var text: String
    
    init(image: UIImage, text: String) {
        self.image = image
        self.text = text
    }
}

class WelcomeViewController: UIViewController {
    
    // MARK: Constants
    private static let titleFont = UIFont.adamantPrimary(ofSize: 28.0)
    private static let descriptionFont = UIFont.systemFont(ofSize: 14.0)
    
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
                           text: NSLocalizedString("WelcomeScene.Description.Slide5", comment: "Welcome: Slide 5 Description")),
        ]

    override func viewDidLoad() {
        super.viewDidLoad()
        
        onboarding.style = .light
        onboarding.delegate = self
        onboarding.dataSource = self
        onboarding.backgroundColor = UIColor(patternImage: #imageLiteral(resourceName: "stripeBg"))//UIColor.adamant.background
    }
    
    @objc func handleSkip() {
        UserDefaults.standard.set(true, forKey: "welcomeIsShown")
        DispatchQueue.main.async {
            self.dismiss(animated: true, completion: nil)
        }
    }
}

// MARK: SwiftyOnboard Delegate & DataSource

extension WelcomeViewController: SwiftyOnboardDelegate, SwiftyOnboardDataSource {
    
    func swiftyOnboardNumberOfPages(_ swiftyOnboard: SwiftyOnboard) -> Int {
        return items.count
    }
    
    func swiftyOnboardPageForIndex(_ swiftyOnboard: SwiftyOnboard, index: Int) -> SwiftyOnboardPage? {
        let item = items[index]
        
        let view = OnboardPage.instanceFromNib() as? OnboardPage
        view?.image.image = item.image
        
        let text = "<span style=\"font-family: Exo2-Regular; font-size: 16\">\(item.text)</span>"
        
        if let htmlData = text.data(using: String.Encoding.unicode), let attributedString = try? NSAttributedString(data: htmlData, options: [.documentType: NSAttributedString.DocumentType.html], documentAttributes: nil) {
            view?.text.attributedText = attributedString
        }
        
        return view
    }
    
    func swiftyOnboardViewForOverlay(_ swiftyOnboard: SwiftyOnboard) -> SwiftyOnboardOverlay? {
        let overlay = OnboardOverlay.instanceFromNib() as? OnboardOverlay
        overlay?.skip.addTarget(self, action: #selector(handleSkip), for: .touchUpInside)
        return overlay
    }
    
    func swiftyOnboardOverlayForPosition(_ swiftyOnboard: SwiftyOnboard, overlay: SwiftyOnboardOverlay, for position: Double) {
        let overlay = overlay as! OnboardOverlay
        let currentPage = round(position)
        overlay.contentControl.currentPage = Int(currentPage)
        if currentPage == 4.0 {
            overlay.skip.setImage(#imageLiteral(resourceName: "skip2Btn"), for: .normal)
        } else {
            overlay.skip.setImage(#imageLiteral(resourceName: "skipBtn"), for: .normal)
        }
    }
}
