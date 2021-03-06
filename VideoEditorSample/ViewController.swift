//
//  ViewController.swift
//  VideoEditorSample
//
//  Created by KnilaDev on 08/03/21.
//

import UIKit
import AVFoundation
import MobileCoreServices
import MediaPlayer

protocol ControllerTrimViewDelegate: class {
	func trimStateChanged(state: TimelineViewState)
	func seekTo(position: Double)
}

class ViewController: UIViewController {
	
	private lazy var videoContainerView: UIView = {
		let view = UIView()
		view.backgroundColor = .black
		view.translatesAutoresizingMaskIntoConstraints = false
		
		return view
	}()
	
	private var playerLayer: AVPlayerLayer!
	private var player: AVPlayer?
	private var currentAsset: AVAsset?

	private lazy var playbackControls: PlaybackControl = {
		let control = PlaybackControl()
		control.translatesAutoresizingMaskIntoConstraints = false
		control.isUserInteractionEnabled = false
		control.delegate = self
		
		return control
	}()
	
	private lazy var timelineView: VideoTimelineView = {
		let view = VideoTimelineView(frame: .zero)
		view.translatesAutoresizingMaskIntoConstraints = false
		view.delegate = self
		
		return view
	}()
	
	private lazy var exportButton: UIBarButtonItem = {
		let button = UIBarButtonItem(title: "Export", style: .done, target: self, action: #selector(export))
		
		return button
	}()
	
	private lazy var trimButton: UIBarButtonItem = {
		let button = UIBarButtonItem(title: "Trim", style: .done, target: self, action: #selector(trim))
		
		return button
	}()
	
	private lazy var addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(add))
	
	private lazy var cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel))
	
	private lazy var trimEnableButton: UIBarButtonItem = {
		let button = UIBarButtonItem(image: #imageLiteral(resourceName: "cut"), style: .plain, target: self, action: #selector(trimEnable))
		
		return button
	}()
	
	private lazy var deleteButton: UIBarButtonItem = {
		let button = UIBarButtonItem(image: #imageLiteral(resourceName: "delete"), style: .plain, target: self, action: #selector(deleteVideo))
		
		return button
	}()
		
	override func viewDidLoad() {
		super.viewDidLoad()
		
		//let asset1 = AVAsset(url: URL(fileURLWithPath: Bundle.main.path(forResource: "sample-mp4-file", ofType:"mp4")!))
		//let asset2 = AVAsset(url: URL(fileURLWithPath: Bundle.main.path(forResource: "file_example_MP4_640_3MG", ofType:"mp4")!))
		
		//processAsset(asset1)
		//processAsset(asset2)
		
		//let asset1 = AVAsset(url: URL(fileURLWithPath: Bundle.main.path(forResource: "audio", ofType:"m4r")!))
		//processAudio(asset1)
		
		self.navigationItem.leftBarButtonItem = addButton
		self.navigationItem.rightBarButtonItem = exportButton
		
		view.addSubview(videoContainerView)
		view.addSubview(playbackControls)
		view.addSubview(timelineView)
		
		let margin = view.safeAreaLayoutGuide
		let constraints = [
			videoContainerView.leadingAnchor.constraint(equalTo: margin.leadingAnchor),
			videoContainerView.trailingAnchor.constraint(equalTo: margin.trailingAnchor),
			videoContainerView.topAnchor.constraint(equalTo: margin.topAnchor),
			
			playbackControls.bottomAnchor.constraint(equalTo: timelineView.topAnchor, constant: -10),
			playbackControls.centerXAnchor.constraint(equalTo: view.centerXAnchor),
			
			timelineView.topAnchor.constraint(equalTo: videoContainerView.bottomAnchor),
			timelineView.leadingAnchor.constraint(equalTo: margin.leadingAnchor),
			timelineView.trailingAnchor.constraint(equalTo: margin.trailingAnchor),
			timelineView.bottomAnchor.constraint(equalTo: margin.bottomAnchor)
		]
		
		NSLayoutConstraint.activate(constraints)
	}
	
	func setupPlayer(_ asset: AVAsset) {
		if playerLayer == nil {
			playerLayer = AVPlayerLayer()
			playerLayer.frame = self.videoContainerView.bounds
			playerLayer.videoGravity = .resizeAspect
		}
		let playerItem = AVPlayerItem(asset: asset)
		self.player = AVPlayer(playerItem: playerItem)
		self.player?.volume = 1.0
		self.playerLayer.player = player
		
		try! AVAudioSession.sharedInstance().setCategory(.playback)
		
		self.videoContainerView.layer.addSublayer(playerLayer)
		
		self.player?.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1, preferredTimescale: 2), queue: DispatchQueue.main) {[weak self] (progressTime) in
			if let duration = self?.player?.currentItem?.asset.duration {

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
	}
	
	private func processVideo(_ asset: AVAsset) {
		timelineView.addVideoAsset(asset)
		playbackControls.isUserInteractionEnabled = true
		
		if self.currentAsset != nil {
			ActivitySpinner.shared.show(on: self.view)
			
			let videos = timelineView.videoAssets.compactMap { $0.getTrimmedAsset() }
			let audios = timelineView.audioAssets.compactMap { $0.getTrimmedAsset() }
			
			VideoEditor.merge(videoAssets: videos, audioAssets: audios, videoContainer: videoContainerView) { (mergedAsset) in
				self.currentAsset = mergedAsset
				self.setupPlayer(mergedAsset)
				
				ActivitySpinner.shared.hide()
			}
		} else {
			self.currentAsset = asset
			self.setupPlayer(asset)
		}
	}
	
	private func processAudio(_ asset: AVAsset) {
		if self.currentAsset != nil {
			ActivitySpinner.shared.show(on: self.view)
			timelineView.addAudioAsset(asset)
			
			let videos = timelineView.videoAssets.compactMap { $0.getTrimmedAsset() }
			let audios = timelineView.audioAssets.compactMap { $0.getTrimmedAsset() }
			
			VideoEditor.merge(videoAssets: videos, audioAssets: audios, videoContainer: videoContainerView) { (mergedAsset) in
				self.currentAsset = mergedAsset
				self.setupPlayer(mergedAsset)
				
				ActivitySpinner.shared.hide()
			}
		} else {
			let alert = UIAlertController(title: "Pick a video first", message: nil, preferredStyle: .alert)
			alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
			self.present(alert, animated: true, completion: nil)
		}
	}
	
	@objc func add() {
		let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
		alert.addAction(UIAlertAction(title: "Video", style: .default, handler: { _ in
			self.selectVideos()
		}))
		alert.addAction(UIAlertAction(title: "Audio", style: .default, handler: { _ in
			self.selectAudio()
		}))
		
		if let view = alert.popoverPresentationController {
			view.barButtonItem = addButton
		}
		
		self.present(alert, animated: true, completion: nil)
	}
	
	private func selectAudio() {
		let mediaPickerController = MPMediaPickerController(mediaTypes: .any)
		mediaPickerController.delegate = self
		mediaPickerController.prompt = "Select Audio"
		present(mediaPickerController, animated: true, completion: nil)
	}
	
	private func selectVideos() {
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
	
	@objc func export() {
		guard let currentAsset = self.currentAsset else { return }
		
		ActivitySpinner.shared.show(on: self.view)
		
		VideoEditor.exportVideo(currentAsset) { (error) in
			let success = error == nil
			let message = success ? "Video saved" : "Failed to save video"
			
			ActivitySpinner.shared.hide()
			
			let alert = UIAlertController(
				title: "Export Video",
				message: message,
				preferredStyle: .alert)
			alert.addAction(UIAlertAction(
								title: "OK",
								style: UIAlertAction.Style.cancel,
								handler: nil))
			self.present(alert, animated: true, completion: nil)
		}
	}
	
	@objc func trim() {
		timelineView.applyTrim()
	}
	
	@objc func cancel() {
		timelineView.cancelTrim()
	}
	
	@objc func trimEnable() {
		timelineView.enableTrimView()
	}
	
	@objc func deleteVideo() {
		
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
		if let currentTime = player?.currentTime(), let duration = player?.currentItem?.asset.duration {
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
		if let totalDuration = player?.currentItem?.asset.duration {
			let seekTime = CMTimeGetSeconds(totalDuration) * position
			let seekCmTime = CMTimeMake(value: CMTimeValue(seekTime * 1000), timescale: 1000)
			
			player?.seek(to: seekCmTime)
		}
	}
	
	func trimStateChanged(state: TimelineViewState) {
		switch state {
		case .normal:
			self.navigationItem.rightBarButtonItems = [exportButton]
			self.navigationItem.leftBarButtonItem = addButton
		case .trim:
			self.navigationItem.rightBarButtonItems = [trimButton]
			self.navigationItem.leftBarButtonItem = cancelButton
		case .select:
			self.navigationItem.rightBarButtonItems = [trimEnableButton, deleteButton]
			self.navigationItem.leftBarButtonItem = cancelButton
		}
	}
}

extension ViewController: UINavigationControllerDelegate, UIImagePickerControllerDelegate {
	func imagePickerController(_ picker: UIImagePickerController,
		didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
		dismiss(animated: true, completion: nil)
		
		guard let mediaType = info[UIImagePickerController.InfoKey.mediaType] as? String, mediaType == (kUTTypeMovie as String), let url = info[UIImagePickerController.InfoKey.mediaURL] as? URL else { return }
		
		let avAsset = AVAsset(url: url)
		processVideo(avAsset)
		
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

extension ViewController: MPMediaPickerControllerDelegate {
	func mediaPicker(_ mediaPicker: MPMediaPickerController, didPickMediaItems mediaItemCollection: MPMediaItemCollection) {
		dismiss(animated: true) {
			let selectedSongs = mediaItemCollection.items
			guard let song = selectedSongs.first else { return }
			
			let title: String
			let message: String
			if let url = song.value(forProperty: MPMediaItemPropertyAssetURL) as? URL {
				let audioAsset = AVAsset(url: url)
				self.processAudio(audioAsset)
				title = "Asset Loaded"
				message = "Audio Loaded"
			} else {
				title = "Asset Not Available"
				message = "Audio Not Loaded"
			}
			
			let alert = UIAlertController(
				title: title,
				message: message,
				preferredStyle: .alert)
			alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
			self.present(alert, animated: true, completion: nil)
		}
	}
	
	func mediaPickerDidCancel(_ mediaPicker: MPMediaPickerController) {
		dismiss(animated: true, completion: nil)
	}
}

extension ViewController: PlaybackControlDelegate {
	func play() {
		playVideo()
	}
	
	func pause() {
		pauseVideo()
	}
	
	func forward() {
		forwardVideo(by: 5)
	}
	
	func reverse() {
		rewindVideo(by: 5)
	}
}
