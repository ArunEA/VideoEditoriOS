//
//  ViewController.swift
//  VideoEditorSample
//
//  Created by KnilaDev on 08/03/21.
//

import UIKit
import AVFoundation
import MobileCoreServices

protocol ControllerTrimViewDelegate: class {
	func trimStateChanged(isTrimming: Bool)
	func seekTo(position: Double)
}

class ViewController: UIViewController {
	
	private lazy var videoContainerView: UIView = {
		let view = UIView()
		view.translatesAutoresizingMaskIntoConstraints = false
		
		return view
	}()
	
	private var playerLayer: AVPlayerLayer!
	private var player: AVPlayer?
	private var currentAsset: AVAsset?

	private lazy var timelineView: VideoTimelineView = {
		let view = VideoTimelineView(frame: .zero)
		view.translatesAutoresizingMaskIntoConstraints = false
		view.delegate = self
		
		return view
	}()
	
	private lazy var mergeButton: UIBarButtonItem = {
		let button = UIBarButtonItem(title: "Export", style: .done, target: self, action: #selector(merge))
		
		return button
	}()
	
	private lazy var trimButton: UIBarButtonItem = {
		let button = UIBarButtonItem(title: "Trim", style: .done, target: self, action: #selector(trim))
		
		return button
	}()
	
	private lazy var addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(add))
	
	private lazy var cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel))
		
	override func viewDidLoad() {
		super.viewDidLoad()
		
		let asset1 = AVAsset(url: URL(fileURLWithPath: Bundle.main.path(forResource: "sample-mp4-file", ofType:"mp4")!))
		let asset2 = AVAsset(url: URL(fileURLWithPath: Bundle.main.path(forResource: "file_example_MP4_640_3MG", ofType:"mp4")!))
		
		processAsset(asset1)
		processAsset(asset2)
		
		self.navigationItem.leftBarButtonItem = addButton
		self.navigationItem.rightBarButtonItem = mergeButton
		
		view.addSubview(videoContainerView)
		view.addSubview(timelineView)
		
		let margin = view.safeAreaLayoutGuide
		let constraints = [
			videoContainerView.leadingAnchor.constraint(equalTo: margin.leadingAnchor),
			videoContainerView.trailingAnchor.constraint(equalTo: margin.trailingAnchor),
			videoContainerView.topAnchor.constraint(equalTo: margin.topAnchor),
			
			timelineView.topAnchor.constraint(equalTo: videoContainerView.bottomAnchor),
			timelineView.leadingAnchor.constraint(equalTo: margin.leadingAnchor),
			timelineView.trailingAnchor.constraint(equalTo: margin.trailingAnchor),
			timelineView.bottomAnchor.constraint(equalTo: margin.bottomAnchor),
			timelineView.heightAnchor.constraint(equalToConstant: CGFloat(Constants.eachFrameHeight))
		]
		
		NSLayoutConstraint.activate(constraints)
	}
	
	func setupPlayer(_ asset: AVAsset) {
		let playerItem = AVPlayerItem(asset: asset)
		self.player = AVPlayer(playerItem: playerItem)
		
		playerLayer = AVPlayerLayer(player: player)
		playerLayer.frame = self.videoContainerView.bounds
		playerLayer.videoGravity = .resizeAspect
		
		self.videoContainerView.layer.addSublayer(playerLayer)
		
//		self.player?.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1, preferredTimescale: 2), queue: DispatchQueue.main) {[weak self] (progressTime) in
//			if let duration = self?.player?.currentItem?.duration {
//
//				let durationSeconds = CMTimeGetSeconds(duration)
//				let seconds = CMTimeGetSeconds(progressTime)
//				let progress = Float(seconds/durationSeconds)
//
//				DispatchQueue.main.async {
//					if progress >= 1.0 || progress.isNaN {
//						self?.timelineView.updateProgress(0)
//					} else {
//						self?.timelineView.updateProgress(progress)
//					}
//				}
//			}
//		}
	}
	
	private func processAsset(_ asset: AVAsset) {
		timelineView.addAsset(asset)
		
		if let currentAsset = self.currentAsset {
			VideoEditor.merge(firstAsset: currentAsset, secondAsset: asset, audioAsset: nil, controller: self) { (mergedAsset) in
				self.currentAsset = mergedAsset
				self.setupPlayer(mergedAsset)
			}
		} else {
			self.currentAsset = asset
			self.setupPlayer(asset)
		}
	}
	
	@objc func add() {
		// Ensure permission to access Photo Library
		let status = VideoPicker.requestPermission { (permitted) in
			if permitted {
				self.pickPhotos()
			}
		}
		
		if status {
			self.pickPhotos()
		}
	}
	
	func pickPhotos() {
		DispatchQueue.main.async {
			if VideoPicker.savedPhotosAvailable(self) {
				VideoPicker.startMediaBrowser(delegate: self, sourceType: .savedPhotosAlbum)
			}
		}
	}
	
	@objc func merge() {
		
	}
	
	@objc func trim() {
		timelineView.applyTrim()
	}
	
	@objc func cancel() {
		timelineView.cancelTrim()
	}
	
	public func playVideo() {
		player?.play()
	}
	
	public func pauseVideo() {
		player?.pause()
	}
	
	func rewindVideo(by seconds: Float64) {
		if let currentTime = player?.currentTime() {
			var newTime = CMTimeGetSeconds(currentTime) - seconds
			if newTime <= 0 {
				newTime = 0
			}
			player?.seek(to: CMTime(value: CMTimeValue(newTime * 1000), timescale: 1000))
		}
	}
	
	func forwardVideo(by seconds: Float64) {
		if let currentTime = player?.currentTime(), let duration = player?.currentItem?.duration {
			var newTime = CMTimeGetSeconds(currentTime) + seconds
			if newTime >= CMTimeGetSeconds(duration) {
				newTime = CMTimeGetSeconds(duration)
			}
			player?.seek(to: CMTime(value: CMTimeValue(newTime * 1000), timescale: 1000))
		}
	}
}

extension ViewController: ControllerTrimViewDelegate {
	func seekTo(position: Double) {
		if let totalDuration = player?.currentItem?.duration {
			let seekTime = CMTimeGetSeconds(totalDuration) * position
			let seekCmTime = CMTimeMake(value: CMTimeValue(seekTime * 1000), timescale: 1000)
			
			player?.seek(to: seekCmTime)
		}
	}
	
	func trimStateChanged(isTrimming: Bool) {
		if isTrimming {
			self.navigationItem.rightBarButtonItem = trimButton
			self.navigationItem.leftBarButtonItem = cancelButton
		} else {
			self.navigationItem.rightBarButtonItem = mergeButton
			self.navigationItem.leftBarButtonItem = addButton
		}
	}
}

extension ViewController: UINavigationControllerDelegate, UIImagePickerControllerDelegate {
	func imagePickerController(_ picker: UIImagePickerController,
		didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
		dismiss(animated: true, completion: nil)
		
		guard let mediaType = info[UIImagePickerController.InfoKey.mediaType] as? String,
			  mediaType == (kUTTypeMovie as String),
			  let url = info[UIImagePickerController.InfoKey.mediaURL] as? URL
		else { return }
		
		let avAsset = AVAsset(url: url)
		processAsset(avAsset)
		
		let alert = UIAlertController(
			title: "Asset Loaded",
			message: "",
			preferredStyle: .alert)
		alert.addAction(UIAlertAction(
							title: "OK",
							style: UIAlertAction.Style.cancel,
							handler: nil))
		
		present(alert, animated: true, completion: nil)
	}
}
