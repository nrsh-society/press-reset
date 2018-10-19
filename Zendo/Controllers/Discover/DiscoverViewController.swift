//
//  DiscoverViewController.swift
//  Zendo
//
//  Created by Anton Pavlov on 18/10/2018.
//  Copyright © 2018 zenbf. All rights reserved.
//

import UIKit
import Hero
import AVFoundation

class DiscoverViewController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    let space: CGFloat = 9
    let showVideo = "showVideo"

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        collectionView.register(DiscoverCollectionViewCell.nib, forCellWithReuseIdentifier: DiscoverCollectionViewCell.reuseIdentifierCell)

        // Do any additional setup after loading the view.
    }
    

    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//         guard let vc = segue.destination as? VideoViewController else { return }
        
        
    }
    

}

//MARK: - UICollectionViewDataSource

extension DiscoverViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 5
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DiscoverCollectionViewCell.reuseIdentifierCell, for: indexPath) as! DiscoverCollectionViewCell
        cell.hero.id = "cellImage" + indexPath.row.description
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {        
        let vc = VideoViewController.loadFromStoryboard()
        vc.idAnim = "cellImage" + indexPath.row.description
        vc.hero.isEnabled = true
        present(vc, animated: true, completion: nil)

    }
    
}

//MARK: - UICollectionViewDelegateFlowLayout

extension DiscoverViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let padding: CGFloat = space * 3
        let collectionViewSize = collectionView.frame.size.width - padding
        let collectionViewSizeHeight = collectionView.frame.size.height - padding
        
        return CGSize(width: (collectionViewSize/2), height: (collectionViewSizeHeight - space * 2))
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: space, left: space, bottom: space, right: space)
    }

}
