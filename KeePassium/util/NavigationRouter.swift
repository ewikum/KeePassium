//  KeePassium Password Manager
//  Copyright © 2018–2019 Andrei Popleteev <info@keepassium.com>
//
//  This program is free software: you can redistribute it and/or modify it
//  under the terms of the GNU General Public License version 3 as published
//  by the Free Software Foundation: https://www.gnu.org/licenses/).
//  For commercial licensing, please contact the author.

import UIKit

public class NavigationRouter: NSObject {
    public typealias PopHandler = ((UIViewController) -> ())
    
    public private(set) var navigationController: UINavigationController
    private var popHandlers = [ObjectIdentifier: PopHandler]()
    private weak var oldDelegate: UINavigationControllerDelegate?
    
    static func createModal(
        style: UIModalPresentationStyle,
        at popoverAnchor: PopoverAnchor? = nil
    ) -> NavigationRouter {
        let navVC = UINavigationController()
        let router = NavigationRouter(navVC)
        navVC.modalPresentationStyle = style
        navVC.presentationController?.delegate = router
        if let popover = navVC.popoverPresentationController {
            popoverAnchor?.apply(to: popover)
            popover.delegate = router
        }
        return router
    }

    init(_ navigationController: UINavigationController) {
        self.navigationController = navigationController
        oldDelegate = navigationController.delegate
        super.init()

        navigationController.delegate = self
    }
    
    deinit {
        navigationController.delegate = oldDelegate
    }
    
    public func dismiss(animated: Bool) {
        navigationController.dismiss(animated: animated, completion: { [self] in
            self.popAll(animated: animated)
        })
    }
    
    public func push(_ viewController: UIViewController, animated: Bool, onPop popHandler: PopHandler?) {
        if let popHandler = popHandler {
            let id = ObjectIdentifier(viewController)
            popHandlers[id] = popHandler
        }
        navigationController.pushViewController(viewController, animated: animated)
    }
    
    public func pop(animated: Bool) {
        let isLastVC = (navigationController.viewControllers.count == 1)
        if isLastVC {
            navigationController.dismiss(animated: animated, completion: nil)
            triggerAndRemovePopHandler(for: navigationController.topViewController!) 
        } else {
            navigationController.popViewController(animated: animated)
        }
    }
    
    public func popTo(viewController: UIViewController, animated: Bool) {
        navigationController.popToViewController(viewController, animated: true)
    }
    
    public func pop(viewController: UIViewController, animated: Bool) {
        let isPushed = navigationController.viewControllers.contains(viewController)
        guard isPushed else {
            return
        }
        popTo(viewController: viewController, animated: animated)
        pop(animated: animated) 
    }
    
    public func popToRoot(animated: Bool) {
        navigationController.popToRootViewController(animated: animated)
    }
    
    fileprivate func popAll(animated: Bool) {
        popToRoot(animated: false)
        pop(animated: false) 
    }
    
    fileprivate func triggerAndRemovePopHandler(for viewController: UIViewController) {
        let id = ObjectIdentifier(viewController)
        if let popHandler = popHandlers[id] {
            popHandler(viewController)
            popHandlers.removeValue(forKey: id)
        }
    }
}

extension NavigationRouter: UINavigationControllerDelegate {
    public func navigationController(
        _ navigationController: UINavigationController,
        didShow viewController: UIViewController,
        animated: Bool)
    {
        guard let fromVC = navigationController.transitionCoordinator?.viewController(forKey: .from),
            !navigationController.viewControllers.contains(fromVC)
            else { return }
        triggerAndRemovePopHandler(for: fromVC)
        oldDelegate?.navigationController?(
            navigationController,
            didShow: viewController,
            animated: true)
    }
    
    public func navigationController(
        _ navigationController: UINavigationController,
        willShow viewController: UIViewController,
        animated: Bool)
    {
        let shouldShowToolbar = (viewController.toolbarItems?.count ?? 0) > 0
        navigationController.setToolbarHidden(!shouldShowToolbar, animated: true)
    }
}

extension NavigationRouter: UIPopoverPresentationControllerDelegate {
    public func presentationController(
        _ controller: UIPresentationController,
        viewControllerForAdaptivePresentationStyle style: UIModalPresentationStyle
    ) -> UIViewController?
    {
        return nil // "keep existing"
    }
}

extension NavigationRouter: UIAdaptivePresentationControllerDelegate {
    public func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        popAll(animated: false)
    }
}
