//
//  VideoTimelineView.swift
//  VideoEditorSample
//
//  Created by KnilaDev on 09/03/21.
//

import UIKit
import AVFoundation

class VideoTimelineView: UIView {
	
	private var currentTrimCell: VideoTimelineViewCell?
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
	
	private lazy var collectionView: UICollectionView = {
		let layout = UICollectionViewFlowLayout()
		layout.scrollDirection = .horizontal
		
		let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
		collectionView.translatesAutoresizingMaskIntoConstraints = false
		collectionView.dataSource = self
		collectionView.delegate = self
		
		collectionView.register(VideoTimelineViewCell.self,
								forCellWithReuseIdentifier: VideoTimelineViewCell.reuseId)
		
		return collectionView
	}()
	
	
	func addAsset(_ asset: AVAsset) {
		let videoAsset = VideoAsset(with: asset)
//		videoAsset.startTrim = 0.3
//		videoAsset.endTrim = 0.3
		
		ThumblineGenerator.shared.thumbnails(for: asset) { [weak self] (image) in
			DispatchQueue.main.async {
				videoAsset.thumbnailImage = image
				
				self?.collectionView.reloadData()
			}
		}
		
		assets.append(videoAsset)
	}
	
	func commonInit() {
		setConstraints()
	}
	
	private func setConstraints() {
		self.addSubview(collectionView)
		
		let lineView = LineView(frame: .zero)
		collectionView.addSubview(lineView)
		
		let constraints = [
			lineView.leadingAnchor.constraint(equalTo: collectionView.leadingAnchor),
			lineView.topAnchor.constraint(equalTo: collectionView.topAnchor),
			lineView.widthAnchor.constraint(equalToConstant: 50),
			lineView.heightAnchor.constraint(equalToConstant: 50),
			
			collectionView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
			collectionView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
			collectionView.topAnchor.constraint(equalTo: self.topAnchor),
			collectionView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
		]
		
		NSLayoutConstraint.activate(constraints)
	}
}

extension VideoTimelineView: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return assets.count
	}
	
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: VideoTimelineViewCell.reuseId, for: indexPath) as? VideoTimelineViewCell else {
			return UICollectionViewCell()
		}
		cell.configure(self.assets[indexPath.item])
		cell.delegate = self
		
		return cell
	}
	
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
		let videoAsset = self.assets[indexPath.item]
		
		return videoAsset.widthForCell(isTrimming: videoAsset.isTrimming)
	}
}

extension VideoTimelineView: TrimViewDelegate {
	func trimViewAdjusted(asset: VideoAsset?) {
		
	}
	
	func trimStateChanged(isTrimming: Bool, cell: VideoTimelineViewCell) {
		delegate?.trimStateChanged(isTrimming: isTrimming, cell: cell)
		
		collectionView.collectionViewLayout.invalidateLayout()
		currentTrimCell = isTrimming ? cell : nil
	}
}

extension VideoTimelineView {
	func applyTrim() {
		currentTrimCell?.isTrimming = false
		collectionView.collectionViewLayout.invalidateLayout()
		collectionView.reloadData()
	}
	
	func cancelTrim() {
		currentTrimCell?.videoAsset?.startTrim = 0
		currentTrimCell?.videoAsset?.endTrim = 0
		currentTrimCell?.isTrimming = false
	}
}
