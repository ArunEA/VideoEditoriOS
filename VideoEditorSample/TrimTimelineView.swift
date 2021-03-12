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
	func trimStateChanged(state: TimelineViewState, cell: TrimTimelineView)
}

extension TrimViewDelegate {
	func moveSeekerTo(position: CGFloat, for asset: VideoAsset) {}
}

class TrimTimelineView: UIView {
	weak var delegate: TrimViewDelegate?
	var state: TimelineViewState = .normal {
		didSet {
			stateChanged()
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
		self.imageView.contentMode = asset?.isAudio == false ? .scaleAspectFit : .scaleToFill
		
		self.reloadView()
	}
	
	func reloadView() {
		switch state {
		case .normal:
			switchToNormal()
		case .trim:
			switchToTrimMode()
		case .select:
			switchToSelectMode()
		}
	}
	
	override func didMoveToWindow() {
		super.didMoveToWindow()
		
		guard let tAsset = self.videoAsset else { return }
		
		imageViewLeading.constant = -tAsset.startTrim * self.frame.size.width
		imageViewTrailing.constant = tAsset.endTrim * self.frame.size.width
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
		
		let translation = panGesture.translation(in: self)
		panGesture.setTranslation(.zero, in: self)
		
		let amountToAdjust = leftEarLeading.constant + translation.x
		if amountToAdjust > 0 {
			leftEarLeading.constant = amountToAdjust
		}
		
		if panGesture.state == UIGestureRecognizer.State.ended {
			let leftAdjust = abs(leftEarLeading.constant / videoAsset.width())
			let rightAdjust = abs(rightEarTrailing.constant / videoAsset.width())
			videoAsset.startTrim = leftAdjust
			videoAsset.endTrim = rightAdjust
			
			delegate?.trimViewAdjusted(asset: self.videoAsset)
		}
	}
	
	@objc func rightEarPanned(panGesture: UIPanGestureRecognizer) {
		guard let videoAsset = self.videoAsset else { return }
		
		let translation = panGesture.translation(in: self)
		panGesture.setTranslation(.zero, in: self)
		
		let amountToAdjust = rightEarTrailing.constant + translation.x
		if amountToAdjust <= 0 {
			rightEarTrailing.constant = amountToAdjust
		}
		
		if panGesture.state == UIGestureRecognizer.State.ended {
			let leftAdjust = abs(leftEarLeading.constant) / videoAsset.width()
			let rightAdjust = abs(rightEarTrailing.constant) / imageView.frame.size.width
			videoAsset.startTrim = leftAdjust
			videoAsset.endTrim = rightAdjust
			
			delegate?.trimViewAdjusted(asset: self.videoAsset)
		}
	}
	
	@objc func longPressed(gesture: UILongPressGestureRecognizer) {
		if gesture.state == .began {
			if state == .normal {
				state = .select
			} else {
				state = .normal
			}
		}
	}
	
	private func stateChanged() {
		self.reloadView()
		
		self.videoAsset?.state = state
		delegate?.trimStateChanged(state: state, cell: self)
	}
	
	internal lazy var imageView: UIImageView = {
		let imageView = UIImageView()
		imageView.translatesAutoresizingMaskIntoConstraints = false
		imageView.contentMode = .scaleAspectFit
		imageView.clipsToBounds = true
		imageView.isUserInteractionEnabled = true
		imageView.tintColor = .white
		
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
	
	internal lazy var selectView: UIView = {
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
		self.clipsToBounds = true
		
		self.addSubview(imageView)
		self.addSubview(leftEarView)
		self.addSubview(rightEarView)
		self.addSubview(selectView)
		
		leftEarWidth = leftEarView.widthAnchor.constraint(equalToConstant: 0)
		rightEarWidth = rightEarView.widthAnchor.constraint(equalToConstant: 0)
		leftEarLeading = leftEarView.leadingAnchor.constraint(equalTo: self.leadingAnchor)
		rightEarTrailing = rightEarView.trailingAnchor.constraint(equalTo: self.trailingAnchor)
		imageViewLeading = imageView.leadingAnchor.constraint(equalTo: self.leadingAnchor)
		imageViewTrailing = imageView.trailingAnchor.constraint(equalTo: self.trailingAnchor)
		
		let constraints = [
			imageView.topAnchor.constraint(equalTo: self.topAnchor),
			imageView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
			imageViewLeading,
			imageViewTrailing,
			
			leftEarView.topAnchor.constraint(equalTo: self.topAnchor),
			leftEarView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
			leftEarLeading,
			leftEarWidth,
			
			selectView.topAnchor.constraint(equalTo: imageView.topAnchor),
			selectView.bottomAnchor.constraint(equalTo: imageView.bottomAnchor),
			selectView.leadingAnchor.constraint(equalTo: leftEarView.trailingAnchor),
			selectView.trailingAnchor.constraint(equalTo: rightEarView.leadingAnchor),
			
			rightEarView.topAnchor.constraint(equalTo: self.topAnchor),
			rightEarView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
			rightEarTrailing,
			rightEarWidth
		]
		
		NSLayoutConstraint.activate(constraints)
	}
	
	func switchToNormal() {
		guard let videoAsset = self.videoAsset else { return }
		
		leftEarWidth.constant = 0
		rightEarWidth.constant = 0
		selectView.isHidden = true
		leftEarLeading.constant = 0
		rightEarTrailing.constant = 0
		
		imageViewLeading.constant = -videoAsset.startTrim * videoAsset.width()
		imageViewTrailing.constant = videoAsset.endTrim * videoAsset.width()
	}
	
	func switchToTrimMode() {
		guard let videoAsset = self.videoAsset else { return }
		
		leftEarWidth.constant = 20
		rightEarWidth.constant = 20
		imageViewLeading.constant = 0
		imageViewTrailing.constant = 0
		selectView.isHidden = false
				
		leftEarLeading.constant = videoAsset.startTrim * videoAsset.width()
		rightEarTrailing.constant = -videoAsset.endTrim * videoAsset.width()
	}
	
	func switchToSelectMode() {
		leftEarWidth.constant = 0
		rightEarWidth.constant = 0
		imageViewLeading.constant = 0
		imageViewTrailing.constant = 0
		selectView.isHidden = false
		
		leftEarLeading.constant = 0
		rightEarTrailing.constant = 0
	}
}
