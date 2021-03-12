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
	var state: TimelineViewState = .normal
	var isAudio: Bool = false
	
	init(with asset: AVAsset, isAudio: Bool = false) {
		self.asset = asset
		self.isAudio = isAudio
	}
	
	func width(byApplyingTrim state: Bool = false) -> CGFloat {
		guard let asset = self.asset else { return .zero }
		let numberOfFrames = CMTimeGetSeconds(asset.duration) / Constants.eachPreviewDuration
		
		if state == false {
			return CGFloat(numberOfFrames * Constants.eachFrameWidth)
		} else {
			let numberOfFramesAfterTrim = numberOfFrames * Double(1 - (startTrim + endTrim))
			return CGFloat(numberOfFramesAfterTrim * Constants.eachFrameWidth)
		}
	}
}

enum TimelineViewState {
	case normal, trim, select
}
