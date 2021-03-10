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
	
	weak var delegate: TrimViewDelegate?
	
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
		
		return scrollView
	}()
	
	private lazy var contentView: UIView = {
		let view = UIView()
		view.backgroundColor = .black
		view.translatesAutoresizingMaskIntoConstraints = false
		
		return view
	}()
	
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
		
		let constraints = [
			scrollView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
			scrollView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
			scrollView.topAnchor.constraint(equalTo: self.topAnchor),
			scrollView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
			scrollView.heightAnchor.constraint(equalToConstant: 55),
			
			contentView.heightAnchor.constraint(equalTo: scrollView.heightAnchor),
			contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
			contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
			contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
			contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor)
		]
		
		NSLayoutConstraint.activate(constraints)
	}
}

extension VideoTimelineView: TrimViewDelegate {
	func trimViewAdjusted(asset: VideoAsset?) {
		
	}
	
	func trimStateChanged(isTrimming: Bool, cell: TrimTimelineView) {
		delegate?.trimStateChanged(isTrimming: isTrimming, cell: cell)
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
}
