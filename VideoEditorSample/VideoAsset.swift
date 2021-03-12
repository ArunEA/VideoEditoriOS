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
	
	// TODO: cache this asset
	func getTrimmedAsset() -> AVAsset? {
		guard let asset = self.asset else { return nil }
		
		if startTrim > 0 || endTrim > 0 {
			let duration = CMTimeGetSeconds(asset.duration)
			let startTime = CMTimeMake(value: Int64(duration*Double(startTrim)), timescale: 1)
			let endTime = CMTimeMake(value: Int64(duration*Double(1-endTrim)), timescale: 1)
			
			do {
				return try asset.assetByTrimming(startTime: startTime, endTime: endTime)
			} catch {
				print("Error trimming asset")
				return nil
			}
		}
		
		return asset
	}
}

enum TimelineViewState {
	case normal, trim, select
}
