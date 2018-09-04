//
//  WelcomeViewController.swift
//  Adamant
//
//  Created by Anton Boyarkin on 04/09/2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import paper_onboarding

class WelcomeViewController: UIViewController {
    
    // MARK: Constants
    private static let titleFont = UIFont.adamantPrimary(ofSize: 28.0)
    private static let descriptionFont = UIFont.systemFont(ofSize: 14.0)
    
    // MARK: Outlets
    @IBOutlet weak var onboarding: PaperOnboarding!
    @IBOutlet var skipButton: UIButton!
    
    // MARK: Properties
    fileprivate let items = [
        OnboardingItemInfo(informationImage: #imageLiteral(resourceName: "SlideImage1"),
                           title: NSLocalizedString("WelcomeScene.Title.Slide1", comment: "Welcome: Slide 1 Title"),
                           description: NSLocalizedString("WelcomeScene.Description.Slide1", comment: "Welcome: Slide 1 Description"),
                           pageIcon: #imageLiteral(resourceName: "SlideIcon1"),
                           color: UIColor.white,
                           titleColor: UIColor.adamant.primary, descriptionColor: UIColor.adamant.secondary, titleFont: titleFont, descriptionFont: descriptionFont),
        
        OnboardingItemInfo(informationImage: #imageLiteral(resourceName: "SlideImage2"),
                           title: NSLocalizedString("WelcomeScene.Title.Slide2", comment: "Welcome: Slide 2 Title"),
                           description: NSLocalizedString("WelcomeScene.Description.Slide2", comment: "Welcome: Slide 2 Description"),
                           pageIcon: #imageLiteral(resourceName: "SlideIcon2"),
                           color: UIColor.white,
                           titleColor: UIColor.adamant.primary, descriptionColor: UIColor.adamant.secondary, titleFont: titleFont, descriptionFont: descriptionFont),
        
        OnboardingItemInfo(informationImage: #imageLiteral(resourceName: "SlideImage3"),
                           title: NSLocalizedString("WelcomeScene.Title.Slide3", comment: "Welcome: Slide 3 Title"),
                           description: NSLocalizedString("WelcomeScene.Description.Slide3", comment: "Welcome: Slide 3 Description"),
                           pageIcon: #imageLiteral(resourceName: "SlideIcon3"),
                           color: UIColor.white,
                           titleColor: UIColor.adamant.primary, descriptionColor: UIColor.adamant.secondary, titleFont: titleFont, descriptionFont: descriptionFont),
        
        OnboardingItemInfo(informationImage: #imageLiteral(resourceName: "SlideImage4"),
                           title: NSLocalizedString("WelcomeScene.Title.Slide4", comment: "Welcome: Slide 4 Title"),
                           description: NSLocalizedString("WelcomeScene.Description.Slide4", comment: "Welcome: Slide 4 Description"),
                           pageIcon: #imageLiteral(resourceName: "SlideIcon4"),
                           color: UIColor.white,
                           titleColor: UIColor.adamant.primary, descriptionColor: UIColor.adamant.secondary, titleFont: titleFont, descriptionFont: descriptionFont),
        
        OnboardingItemInfo(informationImage: #imageLiteral(resourceName: "SlideImage5"),
                           title: NSLocalizedString("WelcomeScene.Title.Slide5", comment: "Welcome: Slide 5 Title"),
                           description: NSLocalizedString("WelcomeScene.Description.Slide5", comment: "Welcome: Slide 5 Description"),
                           pageIcon: #imageLiteral(resourceName: "SlideIcon5"),
                           color: UIColor.white,
                           titleColor: UIColor.adamant.primary, descriptionColor: UIColor.adamant.secondary, titleFont: titleFont, descriptionFont: descriptionFont),
        
        ]

    override func viewDidLoad() {
        super.viewDidLoad()

        onboarding.dataSource = self
        onboarding.delegate = self
        
        skipButton.setTitleColor(UIColor.adamant.primary, for: .normal)
        
        onboarding.currentIndex(0, animated: false)
    }
    
    @IBAction func skipButtonTapped(_: UIButton) {
        UserDefaults.standard.set(true, forKey: "welcomeIsShown")
        DispatchQueue.main.async {
            self.dismiss(animated: true, completion: nil)
        }
    }
}

// MARK: PaperOnboardingDelegate

extension WelcomeViewController: PaperOnboardingDelegate {
    
    func onboardingDidTransitonToIndex(_: Int) {
    }
    
    func onboardingConfigurationItem(_ item: OnboardingContentViewItem, index: Int) {
        item.titleCenterConstraint?.constant = 12
        item.titleLabel?.numberOfLines = 2
        item.descriptionLabel?.textAlignment = .left
    }
}

// MARK: PaperOnboardingDataSource

extension WelcomeViewController: PaperOnboardingDataSource {
    
    func onboardingItem(at index: Int) -> OnboardingItemInfo {
        return items[index]
    }
    
    func onboardingItemsCount() -> Int {
        return items.count
    }
    
    func onboardingPageItemColor(at index: Int) -> UIColor {
        return UIColor.adamant.secondary
    }
}
