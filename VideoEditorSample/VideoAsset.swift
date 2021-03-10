//
//  VideoAsset.swift
//  VideoEditorSample
//
//  Created by KnilaDev on 09/03/21.
//

import UIKit
import AVFoundation

class VideoAsset {
	let id: String = UUID().uuidString
	var asset: AVAsset?
	var startTrim: CGFloat = 0, endTrim: CGFloat = 0
	var thumbnailImage: UIImage?
	var isTrimming: Bool = false
	
	init(with asset: AVAsset) {
		self.asset = asset
	}
	
	func widthForCell(isTrimming: Bool = true) -> CGSize {
		guard let asset = self.asset else { return .zero }
		let numberOfFrames = CMTimeGetSeconds(asset.duration) / 10
		
		if isTrimming {
			return CGSize(width: numberOfFrames * 55, height: 100)
		} else {
			let numberOfFramesAfterTrim = numberOfFrames * Double(1 - (startTrim + endTrim))
			return CGSize(width: numberOfFramesAfterTrim * 55, height: 100)
		}
	}
}
