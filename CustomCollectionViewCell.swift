//
//  CustomCollectionViewCell.swift
//  FinalProject
//
//  Created by Venkata on 3/17/24.
//

import UIKit

class CustomCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var blurEffectView: UIVisualEffectView!
    
    func configure(with image: UIImage?, isHidden: Bool) {
        imageView.image = image
        blurEffectView.isHidden = isHidden
    }
}
