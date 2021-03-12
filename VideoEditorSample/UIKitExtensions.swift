//
//  UIKitExtensions.swift
//  VideoEditorSample
//
//  Created by KnilaDev on 10/03/21.
//

import CoreMedia

extension CMTime {
	static func + (left: CMTime, right: CMTime) -> CMTime {
		return CMTimeAdd(left, right)
	}
	
	static func - (minuend: CMTime, subtrahend: CMTime) -> CMTime {
		return CMTimeSubtract(minuend, subtrahend)
	}
}

func getDocumentsDirectory() -> URL {
	let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
	let documentsDirectory = paths[0]
	return documentsDirectory
}
