//
//  VideoEditHelper.swift
//  VideoEditorSample
//
//  Created by KnilaDev on 09/03/21.
//

import AVFoundation

extension AVAsset {
	func assetByTrimming(startTime: CMTime, endTime: CMTime) throws -> AVAsset {
		let duration = CMTimeSubtract(endTime, startTime)
		let timeRange = CMTimeRange(start: startTime, duration: duration)
		
		let composition = AVMutableComposition()
		
		do {
			for track in tracks {
				let compositionTrack = composition.addMutableTrack(withMediaType: track.mediaType, preferredTrackID: track.trackID)
				compositionTrack?.preferredTransform = track.preferredTransform
				try compositionTrack?.insertTimeRange(timeRange, of: track, at: CMTime.zero)
			}
		} catch let error {
			throw TrimError("error during composition", underlyingError: error)
		}
		
		return composition
	}
	
	struct TrimError: Error {
		let description: String
		let underlyingError: Error?
		
		init(_ description: String, underlyingError: Error? = nil) {
			self.description = "TrimVideo: " + description
			self.underlyingError = underlyingError
		}
	}
}
