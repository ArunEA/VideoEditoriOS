//
//  PlaybackControl.swift
//  VideoEditorSample
//
//  Created by KnilaDev on 11/03/21.
//

import UIKit

protocol PlaybackControlDelegate: class {
	func play()
	func pause()
	func forward()
	func reverse()
}

class PlaybackControl: UIView {
	
	weak var delegate: PlaybackControlDelegate?
	
	var isPlaying: Bool = false {
		didSet {
			changePlayState()
		}
	}
	
	@objc func play(_ sender: UIButton) {
		isPlaying = !isPlaying
		changePlayState()
	}
	
	private func changePlayState() {
		if self.isPlaying {
			playButton.setImage(#imageLiteral(resourceName: "pause.png"), for: .normal)
			delegate?.play()
		} else {
			playButton.setImage(#imageLiteral(resourceName: "play"), for: .normal)
			delegate?.pause()
		}
	}
	
	@objc func forward(_ sender: UIButton) {
		delegate?.forward()
	}
	
	@objc func rewind(_ sender: UIButton) {
		delegate?.reverse()
	}
	
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
		setupEventHandlers()
	}
	
	private func setupEventHandlers() {
		playButton.addTarget(self, action: #selector(play(_:)), for: .touchUpInside)
		forwardButton.addTarget(self, action: #selector(forward(_:)), for: .touchUpInside)
		rewindButton.addTarget(self, action: #selector(rewind(_:)), for: .touchUpInside)
	}
	
	private func setConstraints() {
		addSubview(playButton)
		addSubview(forwardButton)
		addSubview(rewindButton)
		
		var constraints = [
			rewindButton.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 20),
			playButton.leadingAnchor.constraint(equalTo: rewindButton.trailingAnchor, constant: 20),
			forwardButton.leadingAnchor.constraint(equalTo: playButton.trailingAnchor, constant: 20),
			forwardButton.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -20)
		]
		
		[rewindButton, forwardButton, playButton].forEach { (button) in
			constraints += [
				button.topAnchor.constraint(equalTo: self.topAnchor, constant: 20),
				button.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -20),
				button.heightAnchor.constraint(equalToConstant: 40),
				button.widthAnchor.constraint(equalToConstant: 40)
			]
		}
		
		NSLayoutConstraint.activate(constraints)
	}
	
	private lazy var playButton: UIButton = {
		let button = UIButton(type: .custom)
		button.translatesAutoresizingMaskIntoConstraints = false
		button.setImage(#imageLiteral(resourceName: "play"), for: .normal)
		button.tintColor = .white
		
		return button
	}()

	private lazy var rewindButton: UIButton = {
		let button = UIButton(type: .custom)
		button.translatesAutoresizingMaskIntoConstraints = false
		button.setImage(#imageLiteral(resourceName: "rewind"), for: .normal)
		button.tintColor = .white
		
		return button
	}()
	
	private lazy var forwardButton: UIButton = {
		let button = UIButton(type: .custom)
		button.translatesAutoresizingMaskIntoConstraints = false
		button.setImage(#imageLiteral(resourceName: "forward"), for: .normal)
		button.tintColor = .white
		
		return button
	}()
}
