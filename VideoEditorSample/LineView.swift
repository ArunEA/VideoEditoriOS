//
//  LineView.swift
//  VideoEditorSample
//
//  Created by KnilaDev on 10/03/21.
//

import UIKit

class LineView: UIView {
	override init(frame: CGRect) {
		super.init(frame: frame)
		
		commonInit()
	}
	
	required init?(coder: NSCoder) {
		super.init(coder: coder)
		
		commonInit()
	}
	
	private func commonInit() {
		backgroundColor = .red
	}
}
