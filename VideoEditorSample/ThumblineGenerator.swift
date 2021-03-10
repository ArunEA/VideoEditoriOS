//
//  ImageExtensions.swift
//  VideoEditorSample
//
//  Created by KnilaDev on 08/03/21.
//

import UIKit
import AVFoundation

struct ThumblineGenerator {
	
	static let shared: ThumblineGenerator = ThumblineGenerator()
	
	var thumbnailFrameSize:CGSize = CGSize(width: 400,height: 300)
	var timeTolerance = CMTimeMakeWithSeconds(10 , preferredTimescale:100)
	var frameImagesArray: [UIImage] = []
	let preferredTimescale:Int32 = 100
	let durationBetweenFrames: Int = 10
	
	func thumbnails(for asset: AVAsset, completion: @escaping (UIImage)->Void) {
		requestAll(for: asset, completion: completion)
	}
	
	func requestAll(for asset: AVAsset, completion: @escaping (UIImage)->Void) {
		var timesArray = [NSValue]()
		for index in 0 ..< durationBetweenFrames {
			timesArray += [NSValue(time: CMTimeMakeWithSeconds(timeWithIndex(index, for: asset) , preferredTimescale:preferredTimescale))]
		}
		
		requestImageGeneration(for: asset, timesArray: timesArray) { images in
			DispatchQueue.global(qos: .userInitiated).async {
				let stitchedImage = images.stitchImages()
				completion(stitchedImage)
			}
		}
	}
	
	func requestImageGeneration(for asset: AVAsset, timesArray:[NSValue], completion: @escaping ([UIImage])->Void) {
		let assetImgGenerate: AVAssetImageGenerator = AVAssetImageGenerator(asset: asset)
		assetImgGenerate.appliesPreferredTrackTransform = true
		let maxsize = CGSize(width: thumbnailFrameSize.width * 1.5, height: thumbnailFrameSize.height * 1.5)
		assetImgGenerate.maximumSize = maxsize
		assetImgGenerate.requestedTimeToleranceAfter = timeTolerance
		assetImgGenerate.requestedTimeToleranceBefore = timeTolerance
		
		var resultant = [UIImage]()
		
		assetImgGenerate.generateCGImagesAsynchronously(forTimes: timesArray, completionHandler: { time,resultImage,actualTime,result,error  in
			if let image = resultImage {
				DispatchQueue.main.async {
					resultant.append(UIImage(cgImage:image))
					
					if timesArray.last == NSValue(time: time) {
						completion(resultant)
					}
				}
			}
		})
	}
	
	func timeWithIndex(_ index: Int, for asset: AVAsset) -> Float64 {
		let assetDuration = CMTimeGetSeconds(asset.duration)
		return (assetDuration / Float64(durationBetweenFrames)) * Float64(index)
	}
	
	func indexWithTime(_ time: Float64, for asset: AVAsset) -> Int {
		let assetDuration = CMTimeGetSeconds(asset.duration)
		let value = time / (assetDuration / Float64(durationBetweenFrames))
		var intValue = Int(value)
		if value - Float64(intValue) >= 0.5 {
			intValue += 1
		}
		return intValue
	}
}

extension Array where Element: UIImage {
	func stitchImages(isVertical: Bool = false) -> UIImage {
		let maxWidth = self.compactMap { $0.size.width }.max()
		let maxHeight = self.compactMap { $0.size.height }.max()
		
		let maxSize = CGSize(width: maxWidth ?? 0, height: maxHeight ?? 0)
		let totalSize = isVertical ?
			CGSize(width: maxSize.width, height: maxSize.height * (CGFloat)(self.count))
			: CGSize(width: maxSize.width  * (CGFloat)(self.count), height:  maxSize.height)
		let renderer = UIGraphicsImageRenderer(size: totalSize)
		
		return renderer.image { (context) in
			for (index, image) in self.enumerated() {
				let rect = AVMakeRect(aspectRatio: image.size, insideRect: isVertical ?
										CGRect(x: 0, y: maxSize.height * CGFloat(index), width: maxSize.width, height: maxSize.height) :
										CGRect(x: maxSize.width * CGFloat(index), y: 0, width: maxSize.width, height: maxSize.height))
				image.draw(in: rect)
			}
		}
	}
}
