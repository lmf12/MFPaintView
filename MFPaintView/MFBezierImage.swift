//
//  MFBezierImage.swift
//  MFPaintViewDemo
//
//  Created by Lyman Li on 2017/10/29.
//  Copyright © 2017年 Lyman Li. All rights reserved.
//

import UIKit

class MFBezierImage {

    // MARK: - public property
    var origin: CGPoint = CGPoint.zero
    var isEraser: Bool = false
    var image: UIImage
    
    // MARK: - super methods
    init(image: UIImage) {
        self.image = image
    }
}
