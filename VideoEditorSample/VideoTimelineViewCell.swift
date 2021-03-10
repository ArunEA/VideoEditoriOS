//
//  VideoTimelineViewCell.swift
//  VideoEditorSample
//
//  Created by KnilaDev on 09/03/21.
//

import UIKit
import AVFoundation

protocol TrimViewDelegate: class {
	func trimViewAdjusted(asset: VideoAsset?)
	func trimStateChanged(isTrimming: Bool, cell: VideoTimelineViewCell)
}

class VideoTimelineViewCell: UICollectionViewCell {
	static let reuseId = "VideoTimelineViewCell"
	
	weak var delegate: TrimViewDelegate?
	var isTrimming: Bool = false {
		didSet {
			trimStateChanged()
		}
	}
	
	var videoAsset: VideoAsset?
	
	var leftEarWidth = NSLayoutConstraint()
	var rightEarWidth = NSLayoutConstraint()
	var leftEarLeading = NSLayoutConstraint()
	var rightEarTrailing = NSLayoutConstraint()
	var imageViewLeading = NSLayoutConstraint()
	var imageViewTrailing = NSLayoutConstraint()
	
	func configure(_ asset: VideoAsset?) {
		self.videoAsset = asset
		self.imageView.image = asset?.thumbnailImage
		
		guard let tAsset = self.videoAsset else { return }
		
		imageViewLeading.constant = -tAsset.startTrim * contentView.frame.size.width
		imageViewTrailing.constant = tAsset.endTrim * contentView.frame.size.width
	}
	
	override func didMoveToWindow() {
		super.didMoveToWindow()
		
		guard let tAsset = self.videoAsset else { return }
		
		imageViewLeading.constant = -tAsset.startTrim * contentView.frame.size.width
		imageViewTrailing.constant = tAsset.endTrim * contentView.frame.size.width
	}
	
	func setupPanGestures() {
		let leftPan = UIPanGestureRecognizer(target: self, action: #selector(leftEarPanned(panGesture:)))
		leftEarView.addGestureRecognizer(leftPan)
		
		let rightPan = UIPanGestureRecognizer(target: self, action: #selector(rightEarPanned(panGesture:)))
		rightEarView.addGestureRecognizer(rightPan)
		
		let longPress = UILongPressGestureRecognizer(target: self, action: #selector(longPressed(gesture:)))
		imageView.addGestureRecognizer(longPress)
	}
	
	@objc func leftEarPanned(panGesture: UIPanGestureRecognizer) {
		guard let videoAsset = self.videoAsset else { return }
		
		let translation = panGesture.translation(in: self.contentView)
		panGesture.setTranslation(.zero, in: self.contentView)
		
		let amountToAdjust = leftEarLeading.constant + translation.x
		if amountToAdjust > 0 {
			leftEarLeading.constant = amountToAdjust
		}
		
		if panGesture.state == UIGestureRecognizer.State.ended {
			let leftAdjust = abs(leftEarLeading.constant / videoAsset.widthForCell().width)
			let rightAdjust = abs(rightEarTrailing.constant / videoAsset.widthForCell().width)
			videoAsset.startTrim = leftAdjust
			videoAsset.endTrim = rightAdjust
			
			delegate?.trimViewAdjusted(asset: self.videoAsset)
		}
	}
	
	@objc func rightEarPanned(panGesture: UIPanGestureRecognizer) {
		guard let videoAsset = self.videoAsset else { return }
		
		let translation = panGesture.translation(in: self.contentView)
		panGesture.setTranslation(.zero, in: self.contentView)
		
		let amountToAdjust = rightEarTrailing.constant + translation.x
		if amountToAdjust <= 0 {
			rightEarTrailing.constant = amountToAdjust
		}
		
		if panGesture.state == UIGestureRecognizer.State.ended {
			let leftAdjust = abs(leftEarLeading.constant) / videoAsset.widthForCell().width
			let rightAdjust = abs(rightEarTrailing.constant) / imageView.frame.size.width
			videoAsset.startTrim = leftAdjust
			videoAsset.endTrim = rightAdjust
			
			delegate?.trimViewAdjusted(asset: self.videoAsset)
		}
	}
	
	@objc func longPressed(gesture: UILongPressGestureRecognizer) {
		if gesture.state == .began {
			isTrimming = !isTrimming
		}
	}
	
	private func trimStateChanged() {
		guard let videoAsset = self.videoAsset else { return }
		
		if isTrimming {
			leftEarWidth.constant = 20
			rightEarWidth.constant = 20
			imageViewLeading.constant = 20
			imageViewTrailing.constant = -20
			trimView.isHidden = false
			
			guard let tAsset = self.videoAsset else { return }
			
			leftEarLeading.constant = tAsset.startTrim * videoAsset.widthForCell().width
			rightEarTrailing.constant = -tAsset.endTrim * videoAsset.widthForCell().width
		} else {
			leftEarWidth.constant = 0
			rightEarWidth.constant = 0
			trimView.isHidden = true
			leftEarLeading.constant = 0
			rightEarTrailing.constant = 0
			
			guard let tAsset = self.videoAsset else { return }
			
			imageViewLeading.constant = -tAsset.startTrim * videoAsset.widthForCell().width
			imageViewTrailing.constant = tAsset.endTrim * videoAsset.widthForCell().width
		}
		
		self.videoAsset?.isTrimming = isTrimming
		delegate?.trimStateChanged(isTrimming: isTrimming, cell: self)
	}
	
	internal lazy var imageView: UIImageView = {
		let imageView = UIImageView()
		imageView.translatesAutoresizingMaskIntoConstraints = false
		imageView.contentMode = .scaleToFill
		imageView.clipsToBounds = true
		imageView.isUserInteractionEnabled = true
		
		return imageView
	}()
	
	internal lazy var leftEarView: EarView = {
		let earView = EarView(image: "leftEar")
		earView.isUserInteractionEnabled = true
		earView.translatesAutoresizingMaskIntoConstraints = false
		
		return earView
	}()
	
	internal lazy var rightEarView: EarView = {
		let earView = EarView(image: "rightEar")
		earView.isUserInteractionEnabled = true
		earView.translatesAutoresizingMaskIntoConstraints = false
		
		return earView
	}()
	
	internal lazy var trimView: UIView = {
		let view = UIView()
		view.translatesAutoresizingMaskIntoConstraints = false
		view.backgroundColor = UIColor(named: "TrimColor")
		view.isHidden = true
		
		return view
	}()
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		
		commonInit()
	}
	
	required init?(coder: NSCoder) {
		super.init(coder: coder)
		
		commonInit()
	}
	
	private func commonInit() {
		setConstraints()
		setupPanGestures()
	}
	
	func setConstraints() {
		contentView.clipsToBounds = true
		
		contentView.addSubview(imageView)
		contentView.addSubview(leftEarView)
		contentView.addSubview(rightEarView)
		contentView.addSubview(trimView)
		
		leftEarWidth = leftEarView.widthAnchor.constraint(equalToConstant: 0)
		rightEarWidth = rightEarView.widthAnchor.constraint(equalToConstant: 0)
		leftEarLeading = leftEarView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor)
		rightEarTrailing = rightEarView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
		imageViewLeading = imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor)
		imageViewTrailing = imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
		
		let constraints = [
			imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
			imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
			imageViewLeading,
			imageViewTrailing,
			
			leftEarView.topAnchor.constraint(equalTo: contentView.topAnchor),
			leftEarView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
			leftEarLeading,
			leftEarWidth,
			
			trimView.topAnchor.constraint(equalTo: imageView.topAnchor),
			trimView.bottomAnchor.constraint(equalTo: imageView.bottomAnchor),
			trimView.leadingAnchor.constraint(equalTo: leftEarView.trailingAnchor),
			trimView.trailingAnchor.constraint(equalTo: rightEarView.leadingAnchor),
			
			rightEarView.topAnchor.constraint(equalTo: contentView.topAnchor),
			rightEarView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
			rightEarTrailing,
			rightEarWidth
		]
		
		NSLayoutConstraint.activate(constraints)
	}
}
