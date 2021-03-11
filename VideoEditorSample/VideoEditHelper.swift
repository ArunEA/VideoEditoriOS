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
	static func merge(firstAsset: AVAsset?, secondAsset: AVAsset?, audioAsset: AVAsset?, videoContainer: UIView, completion: @escaping (AVAsset)->Void) {
		guard let firstAsset = firstAsset, let secondAsset = secondAsset else { return }
		
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
		
		guard
			let secondTrack = mixComposition.addMutableTrack(
				withMediaType: .video,
				preferredTrackID: Int32(kCMPersistentTrackID_Invalid))
		else { return }
		
		do {
			try secondTrack.insertTimeRange(
				CMTimeRangeMake(start: .zero, duration: secondAsset.duration),
				of: secondAsset.tracks(withMediaType: .video)[0],
				at: firstAsset.duration)
		} catch {
			print("Failed to load second track")
			return
		}
		
		// 3 - Composition Instructions
		let mainInstruction = AVMutableVideoCompositionInstruction()
		mainInstruction.timeRange = CMTimeRangeMake(
			start: .zero,
			duration: CMTimeAdd(firstAsset.duration, secondAsset.duration))
		
		// 4 - Set up the instructions — one for each asset
		let firstInstruction = VideoEditor.videoCompositionInstruction( firstTrack, asset: firstAsset, videoContainer: videoContainer)
		firstInstruction.setOpacity(0.0, at: firstAsset.duration)
		let secondInstruction = VideoEditor.videoCompositionInstruction( secondTrack, asset: secondAsset, videoContainer: videoContainer)
		
		// 5 - Add all instructions together and create a mutable video composition
		mainInstruction.layerInstructions = [firstInstruction, secondInstruction]
		let mainComposition = AVMutableVideoComposition()
		mainComposition.instructions = [mainInstruction]
		mainComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
		mainComposition.renderSize = getRenderSize(firstAsset, secondAsset, videoContainer)
		
		// 6 - Audio track
		if let loadedAudioAsset = audioAsset {
			let audioTrack = mixComposition.addMutableTrack(
				withMediaType: .audio,
				preferredTrackID: 0)
			do {
				try audioTrack?.insertTimeRange(
					CMTimeRangeMake(
						start: CMTime.zero,
						duration: CMTimeAdd(
							firstAsset.duration,
							secondAsset.duration)),
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
	
	static func videoCompositionInstruction(_ track: AVCompositionTrack, asset: AVAsset, videoContainer: UIView ) -> AVMutableVideoCompositionLayerInstruction {
		let instruction = AVMutableVideoCompositionLayerInstruction(assetTrack: track)
		let assetTrack = asset.tracks(withMediaType: AVMediaType.video)[0]
		
		let transform = assetTrack.preferredTransform
		let assetInfo = orientationFromTransform(transform)
		
		var scaleToFitRatio = videoContainer.frame.size.width / assetTrack.naturalSize.width
		if assetInfo.isPortrait {
			scaleToFitRatio = videoContainer.frame.size.width / assetTrack.naturalSize.height
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
			
			if assetInfo.orientation == .down {
				let fixUpsideDown = CGAffineTransform(rotationAngle: CGFloat(Double.pi))
				let windowBounds = videoContainer.frame.size
				let yFix = assetTrack.naturalSize.height + windowBounds.height
				let centerFix = CGAffineTransform(
					translationX: assetTrack.naturalSize.width,
					y: yFix)
				concat = fixUpsideDown.concatenating(centerFix).concatenating(scaleFactor)
			}
			instruction.setTransform(concat, at: .zero)
		}
		
		return instruction
	}
	
	static func getRenderSize(_ asset1: AVAsset, _ asset2: AVAsset, _ container: UIView) -> CGSize {
		let assetTrack1 = asset1.tracks(withMediaType: AVMediaType.video)[0]
		let assetTrack2 = asset2.tracks(withMediaType: AVMediaType.video)[0]
		let maxWidth = max(assetTrack1.naturalSize.width, assetTrack2.naturalSize.width)
		let maxHeight = max(assetTrack1.naturalSize.height, assetTrack2.naturalSize.height)
		let scaleToFitRatio = container.frame.size.width / maxWidth
		
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
