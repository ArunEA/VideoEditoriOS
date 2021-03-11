//
//  VideoTimelineView.swift
//  VideoEditorSample
//
//  Created by KnilaDev on 09/03/21.
//

import UIKit
import AVFoundation

class VideoTimelineView: UIView {
	
	private var currentTrimView: TrimTimelineView?
	private var allTimelineConstraints = [NSLayoutConstraint]()
	
	weak var delegate: ControllerTrimViewDelegate?
	
	var assets = [VideoAsset]()
	
	override init(frame: CGRect) {
		super.init(frame: .zero)
		
		commonInit()
	}
	
	required init?(coder: NSCoder) {
		super.init(coder: coder)
		
		commonInit()
	}
	
	private lazy var scrollView: UIScrollView = {
		let scrollView = UIScrollView()
		scrollView.translatesAutoresizingMaskIntoConstraints = false
		scrollView.backgroundColor = .darkGray
		
		return scrollView
	}()
	
	private lazy var contentView: UIView = {
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
	
	private var lineViewLeading = NSLayoutConstraint()
	
	func addAsset(_ asset: AVAsset) {
		let videoAsset = VideoAsset(with: asset)
		
		ThumblineGenerator.shared.thumbnails(for: asset) { [weak self] (image) in
			DispatchQueue.main.async {
				videoAsset.thumbnailImage = image
				self?.addNewAsset(videoAsset)
			}
		}
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
		let maxWidth = self.scrollView.contentSize.width
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
		guard contentView.subviews.count == self.assets.count else {
			assertionFailure("Scroll View should have same number of timeline view as assets")
			return
		}
		
		var lastTimelineView: UIView = UIView()
		NSLayoutConstraint.deactivate(allTimelineConstraints)
		allTimelineConstraints.removeAll()
		
		for idx in 0..<self.assets.count {
			let videoAsset = self.assets[idx]
			let timelineView = contentView.subviews[idx]
			let assetWidth = videoAsset.widthForCell(isTrimming: videoAsset.isTrimming).width
			
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
			
			if idx == self.assets.count - 1 {
				constraints += [timelineView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)]
			}
			
			allTimelineConstraints.append(contentsOf: constraints)
			NSLayoutConstraint.activate(constraints)
			
			(timelineView as? TrimTimelineView)?.configure(videoAsset)
			lastTimelineView = timelineView
		}
	}
	
	func addNewAsset(_ asset: VideoAsset) {
		self.assets.append(asset)
		
		let timelineView = TrimTimelineView()
		timelineView.translatesAutoresizingMaskIntoConstraints = false
		timelineView.delegate = self
		
		contentView.addSubview(timelineView)
		
		reloadTimeline()
	}
	
	private func setConstraints() {
		self.addSubview(scrollView)
		scrollView.addSubview(contentView)
		scrollView.addSubview(lineView)
		
		lineViewLeading = lineView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor)
		
		let constraints = [
			scrollView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
			scrollView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
			scrollView.topAnchor.constraint(equalTo: self.topAnchor),
			scrollView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
			
			contentView.heightAnchor.constraint(equalTo: scrollView.heightAnchor),
			contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
			contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
			contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
			contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
			
			lineViewLeading,
			lineView.widthAnchor.constraint(equalToConstant: 7),
			lineView.topAnchor.constraint(equalTo: scrollView.topAnchor),
			lineView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor)
		]
		
		NSLayoutConstraint.activate(constraints)
	}
}

extension VideoTimelineView: TrimViewDelegate {
	func trimViewAdjusted(asset: VideoAsset?) {
		
	}
	
	func trimStateChanged(isTrimming: Bool, cell: TrimTimelineView) {
		delegate?.trimStateChanged(isTrimming: isTrimming)
		currentTrimView = isTrimming ? cell : nil
		
		reloadTimeline()
	}
}

extension VideoTimelineView {
	func applyTrim() {
		currentTrimView?.isTrimming = false
		reloadTimeline()
	}
	
	func cancelTrim() {
		currentTrimView?.videoAsset?.startTrim = 0
		currentTrimView?.videoAsset?.endTrim = 0
		currentTrimView?.isTrimming = false
	}
	
	func updateProgress(_ progress: Float) {
		lineViewLeading.constant = self.scrollView.contentSize.width * CGFloat(progress)
	}
}
