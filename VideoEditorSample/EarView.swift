//
//  EarView.swift
//  VideoEditorSample
//
//  Created by KnilaDev on 09/03/21.
//

import UIKit

class EarView: UIView {
	internal lazy var imageView: UIImageView = {
		let imageView = UIImageView()
		imageView.translatesAutoresizingMaskIntoConstraints = false
		imageView.contentMode = .scaleAspectFit
		addSubview(imageView)
		
		return imageView
	}()
	
	required init?(coder: NSCoder) {
		super.init(coder: coder)
	}
	
	init(image: String) {
		super.init(frame: .zero)
		
		self.layer.borderWidth = 1.0
		self.layer.borderColor = UIColor.label.cgColor
		self.backgroundColor = UIColor(named: "EarColor")
		self.imageView.image = UIImage(named: image)
		
		let constraints = [
			imageView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 5),
			imageView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -5),
			imageView.topAnchor.constraint(equalTo: self.topAnchor, constant: 20),
			imageView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -20),
		]
		
		constraints.forEach { $0.priority = .defaultHigh }
		
		NSLayoutConstraint.activate(constraints)
	}
}
