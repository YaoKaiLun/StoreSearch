//
//  SearchResultCellTableViewCell.swift
//  StoreSearch
//
//  Created by kailun on 2019/6/28.
//  Copyright © 2019 kailun.com. All rights reserved.
//

import UIKit

class SearchResultCell: UITableViewCell {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var artistNameLabel: UILabel!
    @IBOutlet weak var artworkImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()

        let selectedView = UIView(frame: CGRect.zero)
        selectedView.backgroundColor = UIColor(red: 20/255,
                                               green: 160/255, blue: 160/255, alpha: 0.5)
        selectedBackgroundView = selectedView
    }
}
