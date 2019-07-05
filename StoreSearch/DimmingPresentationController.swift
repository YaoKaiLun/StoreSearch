//
//  DimmingPresentationController.swift
//  StoreSearch
//
//  Created by kailun on 2019/6/30.
//  Copyright © 2019 kailun.com. All rights reserved.
//

import UIKit

class DimmingPresentationController: UIPresentationController {
    lazy var dimmingView = GradientView(frame: CGRect.zero)
    
    override func presentationTransitionWillBegin() {
        dimmingView.frame = containerView!.bounds
        containerView!.insertSubview(dimmingView, at: 0)
    }

    override var shouldRemovePresentersView: Bool {
        return false
    }
}
