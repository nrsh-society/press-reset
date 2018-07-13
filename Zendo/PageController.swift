//
//  PageController.swift
//  Zendo
//
//  Created by Douglas Purdy on 7/8/18.
//  Copyright © 2018 zenbf. All rights reserved.
//

import Foundation
import UIKit

class PageController : UIPageViewController, UIPageViewControllerDataSource
{
    
    var orderedViewControllers: [UIViewController]?
    
    override func viewDidLoad() {
    
        super.viewDidLoad()
        
        orderedViewControllers = [newViewController("Overview"), newViewController("Session")]

        dataSource = self
        
        self.setViewControllers([(orderedViewControllers?.first)!], direction: .forward, animated: true, completion: nil)
        
    }
    
    private func setupPageControl() {

        let appearance = UIPageControl.appearance(whenContainedInInstancesOf: [PageController.self])
        appearance.pageIndicatorTintColor = .red
        appearance.currentPageIndicatorTintColor = .black
    }
    
    private func newViewController(_ name: String) -> UIViewController {
        return UIStoryboard(name: "Main", bundle: nil) .
            instantiateViewController(withIdentifier: "\(name)")
    }
    

    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerBefore viewController: UIViewController) -> UIViewController? {
        
        guard let viewControllerIndex = orderedViewControllers?.index(of:viewController) else {
            return nil
        }
        
        let previousIndex = viewControllerIndex - 1
        
        // User is on the first view controller and swiped left to loop to
        // the last view controller.
        guard previousIndex >= 0 else {
            return orderedViewControllers?.last
        }
        
        guard (orderedViewControllers?.count)! > previousIndex else {
            return nil
        }
        
        return orderedViewControllers?[previousIndex]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = orderedViewControllers?.index(of:viewController) else {
            return nil
        }
        
        let nextIndex = viewControllerIndex + 1
        let orderedViewControllersCount = orderedViewControllers?.count
        
        // User is on the last view controller and swiped right to loop to
        // the first view controller.
        guard orderedViewControllersCount != nextIndex else {
            return orderedViewControllers?.first
        }
        
        guard orderedViewControllersCount! > nextIndex else {
            return nil
        }
        
        return orderedViewControllers?[nextIndex]
    }
    
    func presentationCountForPageViewController(pageViewController: UIPageViewController) -> Int
    {
        setupPageControl()
        return orderedViewControllers!.count
    }
    
    func presentationIndexForPageViewController(pageViewController: UIPageViewController) -> Int
    {
        return orderedViewControllers!.index(of:pageViewController)!
    }
}
