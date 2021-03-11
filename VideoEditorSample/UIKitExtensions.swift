//
//  UIKitExtensions.swift
//  VideoEditorSample
//
//  Created by KnilaDev on 10/03/21.
//

import UIKit.UIPanGestureRecognizer

enum PanDirection {
	case vertical
	case horizontal
}

class PanDirectionGestureRecognizer: UIPanGestureRecognizer {
	
	let direction: PanDirection
	
	init(direction: PanDirection, target: AnyObject, action: Selector) {
		self.direction = direction
		super.init(target: target, action: action)
	}
	
	override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
		super.touchesMoved(touches, with: event)
		
		if state == .began {
			let vel = velocity(in: view)
			switch direction {
			case .horizontal where abs(vel.y) > abs(vel.x):
				state = .cancelled
			case .vertical where abs(vel.x) > abs(vel.y):
				state = .cancelled
			default:
				break
			}
		}
	}
}
