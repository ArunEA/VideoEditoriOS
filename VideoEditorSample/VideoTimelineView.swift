//
//  VideoTimelineView.swift
//  VideoEditorSample
//
//  Created by KnilaDev on 09/03/21.
//

import UIKit
import AVFoundation

class VideoTimelineView: UIView {
	
	private var selectedTimelineView: TrimTimelineView?
	private var allTimelineConstraints = [NSLayoutConstraint]()
	
	weak var delegate: ControllerTrimViewDelegate?
	
	var videoAssets = [VideoAsset]()
	var audioAssets = [VideoAsset]()
	
	override init(frame: CGRect) {
		super.init(frame: .zero)
		
		commonInit()
	}
	
	required init?(coder: NSCoder) {
		super.init(coder: coder)
		
		commonInit()
	}
	
	private lazy var videoScrollView: UIScrollView = {
		let scrollView = UIScrollView()
		scrollView.translatesAutoresizingMaskIntoConstraints = false
		scrollView.backgroundColor = .darkGray
		scrollView.clipsToBounds = false
		
		return scrollView
	}()
	
	private lazy var audioScrollView: UIScrollView = {
		let scrollView = UIScrollView()
		scrollView.translatesAutoresizingMaskIntoConstraints = false
		scrollView.backgroundColor = .darkGray
		
		return scrollView
	}()
	
	private lazy var videoContentView: UIView = {
		let view = UIView()
		view.backgroundColor = .darkGray
		view.translatesAutoresizingMaskIntoConstraints = false
		
		return view
	}()
	
	private lazy var audioContentView: UIView = {
		let view = UIView()
		view.backgroundColor = .darkGray
		view.translatesAutoresizingMaskIntoConstraints = false
		
		return view
	}()
	
	private lazy var lineView: LineView = {
		let view = LineView()
		view.translatesAutoresizingMaskIntoConstraints = false
		
		return view
	}()
	
	private lazy var borderView: UIView = {
		let view = UIView()
		view.translatesAutoresizingMaskIntoConstraints = false
		view.backgroundColor = .white
		
		return view
	}()
	
	private var lineViewLeading = NSLayoutConstraint()
	
	func addVideoAsset(_ asset: AVAsset) {
		let videoAsset = VideoAsset(with: asset)
		
		ThumblineGenerator.shared.thumbnails(for: asset) { [weak self] (image) in
			DispatchQueue.main.async {
				videoAsset.thumbnailImage = image
				self?.addNewAsset(videoAsset, isAudio: false)
			}
		}
	}
	
	func addAudioAsset(_ asset: AVAsset) {
		let videoAsset = VideoAsset(with: asset, isAudio: true)
		videoAsset.thumbnailImage = UIImage(named: "waveform")
		self.addNewAsset(videoAsset, isAudio: true)
	}
	
	func commonInit() {
		setConstraints()
		setGestures()
	}
	
	private func setGestures() {
		let seekPan = UIPanGestureRecognizer(target: self, action: #selector(seekerPanned(panGesture:)))
		lineView.addGestureRecognizer(seekPan)
	}
	
	@objc func seekerPanned(panGesture: UIPanGestureRecognizer) {
		let translation = panGesture.translation(in: self)
		panGesture.setTranslation(.zero, in: self)
		
		if panGesture.state != .cancelled {
			moveSeekerTo(position: translation.x * 0.8)
		}
	}
	
	func moveSeekerTo(position: CGFloat) {
		let maxWidth = self.videoScrollView.contentSize.width
		if lineViewLeading.constant + position < 0 {
			lineViewLeading.constant = 0
		} else if (lineViewLeading.constant + position) > maxWidth {
			lineViewLeading.constant = maxWidth
		} else {
			lineViewLeading.constant = lineViewLeading.constant + position
		}
		
		print(position, lineViewLeading.constant)
		
		let position = Double(lineViewLeading.constant / maxWidth)
		delegate?.seekTo(position: position)
	}
	
	private func asset(for position: CGFloat) -> VideoAsset? {
		if let subView = self.hitTest(CGPoint(x: position, y: 10), with: nil) as? TrimTimelineView {
			return subView.videoAsset
		}
		
		return nil
	}
	
	func reloadTimeline() {
		guard videoContentView.subviews.count == self.videoAssets.count else {
			assertionFailure("Scroll View should have same number of timeline view as assets")
			return
		}
		
		NSLayoutConstraint.deactivate(allTimelineConstraints)
		allTimelineConstraints.removeAll()
		
		reloadTimeline(videoContentView, with: videoAssets)
		
		guard audioContentView.subviews.count == self.audioAssets.count else {
			assertionFailure("Scroll View should have same number of timeline view as assets")
			return
		}
		
		reloadTimeline(audioContentView, with: audioAssets)
		
		NSLayoutConstraint.activate(allTimelineConstraints)
	}
	
	private func reloadTimeline(_ contentView: UIView, with assets: [VideoAsset]) {
		var lastTimelineView: UIView = UIView()
		
		for idx in 0 ..< assets.count {
			let asset = assets[idx]
			let timelineView = contentView.subviews[idx]
			let assetWidth = asset.width(byApplyingTrim: asset.state != .trim)
			
			var constraints = [
				timelineView.topAnchor.constraint(equalTo: contentView.topAnchor),
				timelineView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
				timelineView.widthAnchor.constraint(equalToConstant: assetWidth)
			]
			
			if idx == 0 {
				constraints += [timelineView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor)]
			} else {
				constraints += [timelineView.leadingAnchor.constraint(equalTo: lastTimelineView.trailingAnchor)]
			}
			
			if idx == assets.count - 1 {
				constraints += [timelineView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)]
			}
			
			allTimelineConstraints.append(contentsOf: constraints)
			
			(timelineView as? TrimTimelineView)?.configure(asset)
			lastTimelineView = timelineView
		}
	}
	
	func addNewAsset(_ asset: VideoAsset, isAudio: Bool) {
		let timelineView = TrimTimelineView()
		timelineView.translatesAutoresizingMaskIntoConstraints = false
		timelineView.delegate = self
		
		if isAudio == false {
			self.videoAssets.append(asset)
			videoContentView.addSubview(timelineView)
		} else {
			self.audioAssets.append(asset)
			audioContentView.addSubview(timelineView)
		}
		
		reloadTimeline()
	}
	
	private func setConstraints() {
		self.addSubview(audioScrollView)
		audioScrollView.addSubview(audioContentView)
		
		self.addSubview(borderView)
		self.addSubview(videoScrollView)
		videoScrollView.addSubview(videoContentView)
		videoScrollView.addSubview(lineView)
		
		lineViewLeading = lineView.centerXAnchor.constraint(equalTo: videoScrollView.leadingAnchor)
		
		let constraints = [
			videoScrollView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
			videoScrollView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
			videoScrollView.topAnchor.constraint(equalTo: self.topAnchor),
			videoScrollView.heightAnchor.constraint(equalToConstant: CGFloat(Constants.eachFrameHeight)),
			
			borderView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
			borderView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
			borderView.topAnchor.constraint(equalTo: videoScrollView.bottomAnchor),
			borderView.heightAnchor.constraint(equalToConstant: 1),
			
			audioScrollView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
			audioScrollView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
			audioScrollView.topAnchor.constraint(equalTo: borderView.bottomAnchor),
			audioScrollView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
			audioScrollView.heightAnchor.constraint(equalToConstant: CGFloat(Constants.audioTimelineHeight)),
			
			videoContentView.heightAnchor.constraint(equalTo: videoScrollView.heightAnchor),
			videoContentView.topAnchor.constraint(equalTo: videoScrollView.topAnchor),
			videoContentView.bottomAnchor.constraint(equalTo: videoScrollView.bottomAnchor),
			videoContentView.leadingAnchor.constraint(equalTo: videoScrollView.leadingAnchor),
			videoContentView.trailingAnchor.constraint(equalTo: videoScrollView.trailingAnchor),
			
			audioContentView.heightAnchor.constraint(equalTo: audioScrollView.heightAnchor),
			audioContentView.topAnchor.constraint(equalTo: audioScrollView.topAnchor),
			audioContentView.bottomAnchor.constraint(equalTo: audioScrollView.bottomAnchor),
			audioContentView.leadingAnchor.constraint(equalTo: audioScrollView.leadingAnchor),
			audioContentView.trailingAnchor.constraint(equalTo: audioScrollView.trailingAnchor),
			
			lineViewLeading,
			lineView.topAnchor.constraint(equalTo: videoScrollView.topAnchor),
			lineView.bottomAnchor.constraint(equalTo: audioScrollView.bottomAnchor)
		]
		
		NSLayoutConstraint.activate(constraints)
	}
}

extension VideoTimelineView: TrimViewDelegate {
	func trimStateChanged(state: TimelineViewState, cell: TrimTimelineView) {
		delegate?.trimStateChanged(state: state)
		selectedTimelineView = state != .normal ? cell : nil
		
		reloadTimeline()
	}
	
	func trimViewAdjusted(asset: VideoAsset?) {
		
	}
}

extension VideoTimelineView {
	func enableSelectView() {
		selectedTimelineView?.state = .select
	}
	
	func enableTrimView() {
		selectedTimelineView?.state = .trim
	}
	
	func applyTrim() {
		selectedTimelineView?.state = .normal
		reloadTimeline()
	}
	
	func cancelTrim() {
		selectedTimelineView?.videoAsset?.startTrim = 0
		selectedTimelineView?.videoAsset?.endTrim = 0
		selectedTimelineView?.state = .normal
	}
	
	func updateProgress(_ progress: Float) {
		lineViewLeading.constant = self.videoScrollView.contentSize.width * CGFloat(progress)
	}
}
