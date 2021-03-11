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
		backgroundColor = .clear
		setConstraints()
	}
	
	private lazy var actualLineView: UIView = {
		let view = UIView()
		view.translatesAutoresizingMaskIntoConstraints = false
		view.backgroundColor = .red
		
		return view
	}()
	
	private func setConstraints() {
		addSubview(actualLineView)
		
		let constraints = [
			actualLineView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 5),
			actualLineView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -5),
			actualLineView.topAnchor.constraint(equalTo: self.topAnchor),
			actualLineView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
			actualLineView.widthAnchor.constraint(equalToConstant: CGFloat(Constants.lineViewWidth))
		]
		
		NSLayoutConstraint.activate(constraints)
	}
}
