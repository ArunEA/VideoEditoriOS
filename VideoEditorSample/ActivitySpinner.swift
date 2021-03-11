//
//  ActivitySpinner.swift
//  VideoEditorSample
//
//  Created by KnilaDev on 11/03/21.
//

import UIKit

public class ActivitySpinner {
	public static let shared = ActivitySpinner()
	
	var container: UIView = UIView()
	var loadingView: UIView = UIView()
	var activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView()
	
	/*
	Show customized activity indicator,
	actually add activity indicator to passing view
	
	@param uiView - add activity indicator to this view
	*/
	func show(on view: UIView, showBlur: Bool = true) {
		container.frame = view.frame
		container.center = view.center
		let blur = showBlur ? 0.3 : 0.0
		container.backgroundColor = UIColorFromHex(rgbValue: 0xffffff, alpha: blur)
		
		loadingView.frame = CGRect(x: 0, y: 0, width: 80, height: 80)
		loadingView.center = view.center
		loadingView.backgroundColor = UIColorFromHex(rgbValue: 0x444444, alpha: 0.7)
		loadingView.clipsToBounds = true
		loadingView.layer.cornerRadius = 10
		
		activityIndicator.frame = CGRect(x: 0.0, y: 0.0, width: 40.0, height: 40.0);
		activityIndicator.style = UIActivityIndicatorView.Style.whiteLarge
		activityIndicator.center = CGPoint(x: loadingView.frame.size.width / 2, y: loadingView.frame.size.height / 2);
		
		loadingView.addSubview(activityIndicator)
		container.addSubview(loadingView)
		view.addSubview(container)
		activityIndicator.startAnimating()
	}
	
	/*
	Hide activity indicator
	Actually remove activity indicator from its super view
	
	@param uiView - remove activity indicator from this view
	*/
	func hide() {
		activityIndicator.stopAnimating()
		container.removeFromSuperview()
	}
	
	/*
	Define UIColor from hex value
	
	@param rgbValue - hex color value
	@param alpha - transparency level
	*/
	func UIColorFromHex(rgbValue:UInt32, alpha:Double=1.0)->UIColor {
		let red = CGFloat((rgbValue & 0xFF0000) >> 16)/256.0
		let green = CGFloat((rgbValue & 0xFF00) >> 8)/256.0
		let blue = CGFloat(rgbValue & 0xFF)/256.0
		return UIColor(red:red, green:green, blue:blue, alpha:CGFloat(alpha))
	}
}
