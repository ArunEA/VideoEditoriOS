//
//  VideoPicker.swift
//  VideoEditorSample
//
//  Created by KnilaDev on 11/03/21.
//

import UIKit
import MobileCoreServices
import Photos

struct VideoPicker {
	static func requestPermission(completion: @escaping (Bool)->()) -> Bool {
		if PHPhotoLibrary.authorizationStatus() != .authorized {
			PHPhotoLibrary.requestAuthorization { status in
				completion(status == .authorized)
			}
			
			return false
		}
		
		return true
	}
	
	static func savedPhotosAvailable(_ controller: UIViewController) -> Bool {
		guard !UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum) else { return true }
		
		let alert = UIAlertController(title: "Not Available", message: "No Saved Album found", preferredStyle: .alert)
		alert.addAction(UIAlertAction( title: "OK", style: .cancel, handler: nil))
		controller.present(alert, animated: true, completion: nil)
		return false
	}
	
	static func startMediaBrowser(delegate: UIViewController & UINavigationControllerDelegate & UIImagePickerControllerDelegate,
		sourceType: UIImagePickerController.SourceType
	) {
		guard UIImagePickerController.isSourceTypeAvailable(sourceType)
		else { return }
		
		let mediaUI = UIImagePickerController()
		mediaUI.sourceType = sourceType
		mediaUI.mediaTypes = [kUTTypeMovie as String]
		mediaUI.allowsEditing = true
		mediaUI.delegate = delegate
		delegate.present(mediaUI, animated: true, completion: nil)
	}
}
