//
//  ViewController.swift
//  VideoEditorSample
//
//  Created by KnilaDev on 08/03/21.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
	
	private lazy var videoContainerView: UIView = {
		let view = UIView()
		view.translatesAutoresizingMaskIntoConstraints = false
		
		return view
	}()
	
	private var playerLayer: AVPlayerLayer!
	private var player: AVPlayer?

	private lazy var timelineView: VideoTimelineView = {
		let view = VideoTimelineView(frame: .zero)
		view.translatesAutoresizingMaskIntoConstraints = false
		view.delegate = self
		
		return view
	}()
	
	private lazy var mergeButton: UIBarButtonItem = {
		let button = UIBarButtonItem(title: "Merge", style: .done, target: self, action: #selector(merge))
		
		return button
	}()
	
	private lazy var trimButton: UIBarButtonItem = {
		let button = UIBarButtonItem(title: "Trim", style: .done, target: self, action: #selector(trim))
		
		return button
	}()
	
	private lazy var cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel))
		
	override func viewDidLoad() {
		super.viewDidLoad()
		
		let asset1 = AVAsset(url: URL(fileURLWithPath: Bundle.main.path(forResource: "sample-mp4-file", ofType:"mp4")!))
		let asset2 = AVAsset(url: URL(fileURLWithPath: Bundle.main.path(forResource: "file_example_MP4_640_3MG", ofType:"mp4")!))
		timelineView.addAsset(asset1)
		//timelineView.addAsset(asset2)

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
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		let asset1 = AVAsset(url: URL(fileURLWithPath: Bundle.main.path(forResource: "sample-mp4-file", ofType:"mp4")!))
		
		setupPlayer(asset1)
	}
	
	func setupPlayer(_ asset: AVAsset) {
		let playerItem = AVPlayerItem(asset: asset)
		self.player = AVPlayer(playerItem: playerItem)
		
		playerLayer = AVPlayerLayer(player: player)
		playerLayer.frame = self.videoContainerView.bounds
		playerLayer.videoGravity = .resizeAspect
		
		self.videoContainerView.layer.addSublayer(playerLayer)
		
		self.player?.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1, preferredTimescale: 2), queue: DispatchQueue.main) {[weak self] (progressTime) in
			if let duration = self?.player?.currentItem?.duration {
				
				let durationSeconds = CMTimeGetSeconds(duration)
				let seconds = CMTimeGetSeconds(progressTime)
				let progress = Float(seconds/durationSeconds)
				
				DispatchQueue.main.async {
					if progress >= 1.0 || progress.isNaN {
						self?.timelineView.updateProgress(0)
					} else {
						self?.timelineView.updateProgress(progress)
					}
				}
			}
		}
		
		self.player?.play()
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
}

extension ViewController: TrimViewDelegate {
	func trimViewAdjusted(asset: VideoAsset?) {
		
	}
	
	func trimStateChanged(isTrimming: Bool, cell: TrimTimelineView) {
		if isTrimming {
			self.navigationItem.rightBarButtonItem = trimButton
			self.navigationItem.leftBarButtonItem = cancelButton
		} else {
			
			self.navigationItem.rightBarButtonItem = mergeButton
			self.navigationItem.leftBarButtonItem = nil
		}
	}
}
