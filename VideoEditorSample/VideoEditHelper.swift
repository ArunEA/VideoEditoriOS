//
//  VideoEditHelper.swift
//  VideoEditorSample
//
//  Created by KnilaDev on 09/03/21.
//

import AVFoundation
import UIKit
import Photos

struct VideoEditor {
	static func merge(videoAssets: [AVAsset], audioAssets: [AVAsset], videoContainer: UIView, completion: @escaping (AVAsset)->Void) {
		var totalDuration: CMTime = .zero
		let mixComposition = AVMutableComposition()
		var videoTracks = [AVMutableCompositionTrack]()
		
		// Prepare video tracks
		videoAssets.forEach { (asset) in
			if let track = prepareVideoTrack(for: asset, with: mixComposition, after: totalDuration) {
				videoTracks.append(track)
				totalDuration = totalDuration + asset.duration
			}
		}
		
		let finalRenderSize = renderSize(videoTracks, videoContainer)
		
		// Composition Instructions
		let mainInstruction = AVMutableVideoCompositionInstruction()
		mainInstruction.timeRange = CMTimeRangeMake( start: .zero,
													 duration: totalDuration)
		
		var allInstructions = [AVMutableVideoCompositionLayerInstruction]()
		
		// Set up the instructions — one for each asset
		var tempDuration: CMTime = .zero
		for idx in 0..<videoTracks.count {
			let track = videoTracks[idx]
			let asset = videoAssets[idx]
			
			let instruction = VideoEditor.videoCompositionInstruction(track, asset: asset, renderSize: finalRenderSize)
			allInstructions.append(instruction)
			tempDuration = tempDuration + asset.duration
			
			if idx != videoTracks.count-1 {
				instruction.setOpacity(0.0, at: tempDuration)
			}
		}
		
		mainInstruction.layerInstructions = allInstructions
		
		let mainComposition = AVMutableVideoComposition()
		mainComposition.instructions = [mainInstruction]
		mainComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
		mainComposition.renderSize = finalRenderSize
		
		// Prepare audio tracks
		var audioTracks = [AVMutableCompositionTrack]()
		
		var audioDuration: CMTime = .zero
		audioAssets.forEach { (asset) in
			if let track = prepareAudioTrack(for: asset, with: mixComposition, after: audioDuration, videoDuration: totalDuration) {
				audioTracks.append(track)
				audioDuration = audioDuration + asset.duration
			}
		}
		
		// Get path
		guard
			let documentDirectory = FileManager.default.urls(
				for: .documentDirectory,
				in: .userDomainMask).first
		else { return }
		let dateFormatter = DateFormatter()
		dateFormatter.dateStyle = .long
		dateFormatter.timeStyle = .short
		let date = dateFormatter.string(from: Date())
		let url = documentDirectory.appendingPathComponent("mergeVideo-\(date).mov")
		
		// 8 - Create Exporter
		guard let exporter = AVAssetExportSession(
				asset: mixComposition,
				presetName: AVAssetExportPresetHighestQuality)
		else { return }
		exporter.outputURL = url
		exporter.outputFileType = AVFileType.mov
		exporter.shouldOptimizeForNetworkUse = true
		exporter.videoComposition = mainComposition
		
		// 9 - Perform the Export
		exporter.exportAsynchronously {
			DispatchQueue.main.async {
				if let outputURL = exporter.outputURL {
					completion(AVAsset(url: outputURL))
				}
			}
		}
	}
	
	static func prepareVideoTrack(for asset: AVAsset, with composition: AVMutableComposition, after duration: CMTime) -> AVMutableCompositionTrack? {
		guard let firstTrack = composition.addMutableTrack( withMediaType: .video, preferredTrackID: Int32(kCMPersistentTrackID_Invalid)) else { return nil }
		
		do {
			try firstTrack.insertTimeRange(
				CMTimeRangeMake(start: .zero, duration: asset.duration),
				of: asset.tracks(withMediaType: .video)[0],
				at: duration)
		} catch {
			print("Failed to load first track")
			return nil
		}
		
		return firstTrack
	}
	
	static func prepareAudioTrack(for asset: AVAsset, with composition: AVMutableComposition, after duration: CMTime, videoDuration: CMTime) -> AVMutableCompositionTrack? {
		let audioFinalDuration = videoDuration < (duration + asset.duration) ? (videoDuration - duration) : asset.duration
		let audioTrack = composition.addMutableTrack(
			withMediaType: .audio,
			preferredTrackID: 0)
		do {
			try audioTrack?.insertTimeRange(
				CMTimeRangeMake(
					start: CMTime.zero,
					duration: audioFinalDuration),
				of: asset.tracks(withMediaType: .audio)[0],
				at: duration)
		} catch {
			print("Failed to load Audio track")
			return nil
		}
		
		return audioTrack
	}
	
	static func renderSize(_ videoTracks: [AVAssetTrack], _ container: UIView) -> CGSize {
		var maxWidth: CGFloat = 0
		var maxHeight: CGFloat = 0
		
		videoTracks.forEach { (track) in
			maxWidth = max(maxWidth, track.naturalSize.width)
			maxHeight = max(maxHeight, track.naturalSize.height)
		}
	
		if let firstTrack = videoTracks.first {
			let transform = firstTrack.preferredTransform
			let assetInfo = orientationFromTransform(transform)
			let scaleToFitRatio = assetInfo.isPortrait ? container.frame.size.height/maxHeight : container.frame.size.width/maxWidth
			
			return CGSize(width: scaleToFitRatio*maxWidth, height: scaleToFitRatio*maxHeight)
		}
		
		return .zero
	}
	
	static func merge(firstAsset: AVAsset?, secondAsset: AVAsset?, audioAsset: AVAsset?, videoContainer: UIView, completion: @escaping (AVAsset)->Void) {
		guard let firstAsset = firstAsset else { return }
		
		let mixComposition = AVMutableComposition()
		
		guard let firstTrack = mixComposition.addMutableTrack( withMediaType: .video, preferredTrackID: Int32(kCMPersistentTrackID_Invalid)) else { return }
		
		do {
			try firstTrack.insertTimeRange(
				CMTimeRangeMake(start: .zero, duration: firstAsset.duration),
				of: firstAsset.tracks(withMediaType: .video)[0],
				at: .zero)
		} catch {
			print("Failed to load first track")
			return
		}
		
		var totalDuration = firstAsset.duration
		var finalRenderSize = getSize(firstAsset)
		var secondInstruction: AVMutableVideoCompositionLayerInstruction? = nil
		
		if let secondAsset = secondAsset, let secondTrack = mixComposition.addMutableTrack(withMediaType: .video, preferredTrackID: Int32(kCMPersistentTrackID_Invalid))
		{
			do {
				try secondTrack.insertTimeRange(
					CMTimeRangeMake(start: .zero, duration: secondAsset.duration),
					of: secondAsset.tracks(withMediaType: .video)[0],
					at: firstAsset.duration)
				totalDuration = CMTimeAdd(firstAsset.duration, secondAsset.duration)
				
				finalRenderSize = getRenderSize(firstAsset, secondAsset, videoContainer)
				secondInstruction = VideoEditor.videoCompositionInstruction( secondTrack, asset: secondAsset, renderSize: finalRenderSize)
			} catch {
				print("Failed to load second track")
				return
			}
		}
		
		// 3 - Composition Instructions
		let mainInstruction = AVMutableVideoCompositionInstruction()
		mainInstruction.timeRange = CMTimeRangeMake( start: .zero,
			duration: totalDuration)
				
		// 4 - Set up the instructions — one for each asset
		let firstInstruction = VideoEditor.videoCompositionInstruction( firstTrack, asset: firstAsset, renderSize: finalRenderSize)
		firstInstruction.setOpacity(0.0, at: firstAsset.duration)
		
		// 5 - Add all instructions together and create a mutable video composition
		if let secondInstruction = secondInstruction {
			mainInstruction.layerInstructions = [firstInstruction, secondInstruction]
		} else {
			mainInstruction.layerInstructions = [firstInstruction]
		}
		
		let mainComposition = AVMutableVideoComposition()
		mainComposition.instructions = [mainInstruction]
		mainComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
		mainComposition.renderSize = finalRenderSize
		
		// 6 - Audio track
		if let loadedAudioAsset = audioAsset {
			let audioTrack = mixComposition.addMutableTrack(
				withMediaType: .audio,
				preferredTrackID: 0)
			do {
				try audioTrack?.insertTimeRange(
					CMTimeRangeMake(
						start: CMTime.zero,
						duration: totalDuration),
					of: loadedAudioAsset.tracks(withMediaType: .audio)[0],
					at: .zero)
			} catch {
				print("Failed to load Audio track")
			}
		}
		
		// 7 - Get path
		guard
			let documentDirectory = FileManager.default.urls(
				for: .documentDirectory,
				in: .userDomainMask).first
		else { return }
		let dateFormatter = DateFormatter()
		dateFormatter.dateStyle = .long
		dateFormatter.timeStyle = .short
		let date = dateFormatter.string(from: Date())
		let url = documentDirectory.appendingPathComponent("mergeVideo-\(date).mov")
		
		// 8 - Create Exporter
		guard let exporter = AVAssetExportSession(
				asset: mixComposition,
				presetName: AVAssetExportPresetHighestQuality)
		else { return }
		exporter.outputURL = url
		exporter.outputFileType = AVFileType.mov
		exporter.shouldOptimizeForNetworkUse = true
		exporter.videoComposition = mainComposition
		
		// 9 - Perform the Export
		exporter.exportAsynchronously {
			DispatchQueue.main.async {
				if let outputURL = exporter.outputURL {
					completion(AVAsset(url: outputURL))
				}
			}
		}
	}
	
	static func videoCompositionInstruction(_ track: AVCompositionTrack, asset: AVAsset, renderSize: CGSize) -> AVMutableVideoCompositionLayerInstruction {
		let instruction = AVMutableVideoCompositionLayerInstruction(assetTrack: track)
		let assetTrack = asset.tracks(withMediaType: AVMediaType.video)[0]
		
		let transform = assetTrack.preferredTransform
		let assetInfo = orientationFromTransform(transform)
		
		var scaleToFitRatio = renderSize.width / assetTrack.naturalSize.width
		if assetInfo.isPortrait {
			scaleToFitRatio = renderSize.width / assetTrack.naturalSize.height
			let scaleFactor = CGAffineTransform(
				scaleX: scaleToFitRatio,
				y: scaleToFitRatio)
			instruction.setTransform(
				assetTrack.preferredTransform.concatenating(scaleFactor),
				at: .zero)
		} else {
			let scaleFactor = CGAffineTransform(
				scaleX: scaleToFitRatio,
				y: scaleToFitRatio)
			var concat = assetTrack.preferredTransform.concatenating(scaleFactor)
			
			// TODO: Add another transform to center the video
			
			if assetInfo.orientation == .down {
				let fixUpsideDown = CGAffineTransform(rotationAngle: CGFloat(Double.pi))
				let yFix = assetTrack.naturalSize.height + renderSize.height
				let centerFix = CGAffineTransform(
					translationX: assetTrack.naturalSize.width,
					y: yFix)
				concat = fixUpsideDown.concatenating(centerFix).concatenating(scaleFactor)
			}
			instruction.setTransform(concat, at: .zero)
		}
		
		return instruction
	}
	
	static func getSize(_ asset1: AVAsset) -> CGSize {
		let assetTrack1 = asset1.tracks(withMediaType: AVMediaType.video)[0]
		return assetTrack1.naturalSize
	}
	
	static func getRenderSize(_ asset1: AVAsset, _ asset2: AVAsset, _ container: UIView) -> CGSize {
		let assetTrack1 = asset1.tracks(withMediaType: AVMediaType.video)[0]
		let assetTrack2 = asset2.tracks(withMediaType: AVMediaType.video)[0]
		let maxWidth = max(assetTrack1.naturalSize.width, assetTrack2.naturalSize.width)
		let maxHeight = max(assetTrack1.naturalSize.height, assetTrack2.naturalSize.height)
		let transform = assetTrack1.preferredTransform
		let assetInfo = orientationFromTransform(transform)
		let scaleToFitRatio = assetInfo.isPortrait ? container.frame.size.height/maxHeight : container.frame.size.width/maxWidth
		
		return CGSize(width: scaleToFitRatio*maxWidth, height: scaleToFitRatio*maxHeight)
	}
	
	static func orientationFromTransform(
		_ transform: CGAffineTransform
	) -> (orientation: UIImage.Orientation, isPortrait: Bool) {
		var assetOrientation = UIImage.Orientation.up
		var isPortrait = false
		let tfA = transform.a
		let tfB = transform.b
		let tfC = transform.c
		let tfD = transform.d
		
		if tfA == 0 && tfB == 1.0 && tfC == -1.0 && tfD == 0 {
			assetOrientation = .right
			isPortrait = true
		} else if tfA == 0 && tfB == -1.0 && tfC == 1.0 && tfD == 0 {
			assetOrientation = .left
			isPortrait = true
		} else if tfA == 1.0 && tfB == 0 && tfC == 0 && tfD == 1.0 {
			assetOrientation = .up
		} else if tfA == -1.0 && tfB == 0 && tfC == 0 && tfD == -1.0 {
			assetOrientation = .down
		}
		return (assetOrientation, isPortrait)
	}
	
	static func exportDidFinish(_ session: AVAssetExportSession, completion: ((Error?)->Void)?) {
		guard
			session.status == AVAssetExportSession.Status.completed,
			let outputURL = session.outputURL
		else {
			completion?(VideoExportError.setupError)
			return
		}
		
		let saveVideoToPhotos = {
			let changes: () -> Void = {
				PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: outputURL)
			}
			PHPhotoLibrary.shared().performChanges(changes) { saved, error in
				DispatchQueue.main.async {
					completion?(error)
				}
			}
		}
		
		// Ensure permission to access Photo Library
		if PHPhotoLibrary.authorizationStatus() != .authorized {
			PHPhotoLibrary.requestAuthorization { status in
				if status == .authorized {
					saveVideoToPhotos()
				} else {
					completion?(VideoExportError.setupError)
				}
			}
		} else {
			saveVideoToPhotos()
		}
	}
	
	static func exportVideo(_ asset: AVAsset, _ completion: ((Error?) -> Void)?) {
		guard let exporter = AVAssetExportSession(
				asset: asset,
				presetName: AVAssetExportPresetHighestQuality)
		else {
			completion?(VideoExportError.setupError)
			return
		}
		
		let dateFormatter = DateFormatter()
		dateFormatter.dateStyle = .long
		dateFormatter.timeStyle = .short
		let outputURL = getDocumentsDirectory().appendingPathComponent("mergeVideo-\(dateFormatter.string(from: Date())).mov")
		exporter.outputURL = outputURL
		exporter.outputFileType = AVFileType.mov
		exporter.shouldOptimizeForNetworkUse = true
		
		if FileManager.default.fileExists(atPath: outputURL.path) {
			do {
				try FileManager.default.removeItem(at: outputURL)
			} catch { print(error.localizedDescription) }
		}
		
		// 9 - Perform the Export
		exporter.exportAsynchronously {
			DispatchQueue.main.async {
				self.exportDidFinish(exporter, completion: completion)
			}
		}
	}
}

enum VideoExportError: Error {
	case setupError
}

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
