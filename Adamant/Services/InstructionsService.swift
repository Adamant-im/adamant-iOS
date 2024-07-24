//
//  InstructionsService.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 24.07.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import UIKit
import Instructions

struct Instruction {
    let hint: String
    let view: UIView
}

class SkipView: UIButton, CoachMarkSkipView {
    var skipControl: UIControl? {
        return self
    }
}

final class InstructionsService: InstructionsProtocol {
    private let coachMarksController = CoachMarksController()
    private var instructions: [Instruction] = []
    
    init() {
        configure()
    }
    
    func display(
        instructions: [Instruction],
        from viewController: UIViewController
    ) {
        self.instructions = instructions
        DispatchQueue.onMainAsync {
            self.coachMarksController.start(in: .viewController(viewController))
        }
    }
    
    func stop() {
        DispatchQueue.onMainAsync {
            self.coachMarksController.stop(immediately: true)
        }
    }
    
    func showNext() {
        DispatchQueue.onMainAsync {
            self.coachMarksController.flow.showNext()
        }
    }
}

private extension InstructionsService {
    func configure() {
        coachMarksController.dataSource = self
        coachMarksController.delegate = self
        
        coachMarksController.overlay.areTouchEventsForwarded = false
        coachMarksController.overlay.isUserInteractionEnabledInsideCutoutPath = true

        let skipView = SkipView()
        skipView.backgroundColor = UIColor.adamant.pickedReactionBackground
        skipView.layer.cornerRadius = 10
        skipView.setTitle(.adamant.login.guideSkipButton, for: .normal)
        skipView.setTitleColor(UIColor.adamant.textColor, for: .normal)
        coachMarksController.skipView = skipView
    }
}

extension InstructionsService: CoachMarksControllerDataSource, CoachMarksControllerDelegate {
    
    func numberOfCoachMarks(
        for coachMarksController: Instructions.CoachMarksController
    ) -> Int {
        instructions.count
    }
    
    func coachMarksController(
        _ coachMarksController: Instructions.CoachMarksController,
        coachMarkAt index: Int
    ) -> Instructions.CoachMark {
        var coachMark = coachMarksController.helper.makeCoachMark(
            for: instructions[index].view
        )
        let cutoutPath = UIBezierPath(rect: instructions[index].view.frame)
        coachMark.isUserInteractionEnabledInsideCutoutPath = true
        return coachMark
    }
    
    func coachMarksController(
        _ coachMarksController: Instructions.CoachMarksController,
        coachMarkViewsAt index: Int,
        madeFrom coachMark: Instructions.CoachMark
    ) -> (bodyView: (UIView & Instructions.CoachMarkBodyView), arrowView: (UIView & Instructions.CoachMarkArrowView)?) {
        let coachViews = coachMarksController.helper.makeDefaultCoachViews(
            withArrow: true,
            withNextText: false,
            arrowOrientation: coachMark.arrowOrientation
        )
        
        let backgroundColor = UIColor.adamant.pickedReactionBackground
        coachViews.bodyView.hintLabel.textColor = UIColor.adamant.textColor
        coachViews.bodyView.background.borderColor = backgroundColor
        coachViews.bodyView.background.innerColor = backgroundColor
        coachViews.arrowView?.background.innerColor = backgroundColor
        coachViews.arrowView?.background.borderColor = backgroundColor
        
        coachViews.bodyView.hintLabel.text = instructions[index].hint
        
        return (bodyView: coachViews.bodyView, arrowView: coachViews.arrowView)
    }
}
