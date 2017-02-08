//
//  CameraButton.swift
//  Camera
//
//  Created by Doug Diego on 1/26/17.
//  Copyright © 2017 Doug Diego. All rights reserved.
// 


import UIKit

@IBDesignable
class CameraButton: UIButton {
    
    var pathLayer:CAShapeLayer!
    let animationDuration = 0.4

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setup()
    }
    
    //common set up code
    func setup() {
        //add a shape layer for the inner shape to be able to animate it
        self.pathLayer = CAShapeLayer()
        
        //show the right shape for the current state of the control
        self.pathLayer.path = self.innerCirclePath().cgPath
        
        //don't use a stroke color, which would give a ring around the inner circle
        self.pathLayer.strokeColor = nil
        
        //set the color for the inner shape
        self.pathLayer.fillColor = UIColor.white.cgColor
        
        //add the path layer to the control layer so it gets drawn
        self.layer.addSublayer(self.pathLayer)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        //lock the size to match the size of the camera button
        self.addConstraint(NSLayoutConstraint(item: self,
                                              attribute:.width,
                                              relatedBy:.equal,
                                              toItem:nil,
                                              attribute:.width,
                                              multiplier:1,
                                              constant:66.0))
        self.addConstraint(NSLayoutConstraint(item: self,
                                              attribute:.height,
                                              relatedBy:.equal,
                                              toItem:nil,
                                              attribute:.width,
                                              multiplier:1,
                                              constant:66.0))
        
        //clear the title
        self.setTitle("", for:UIControlState.normal)
        
        //add out target for event handling
        self.addTarget(self, action: #selector(touchUpInside), for: UIControlEvents.touchUpInside)
        self.addTarget(self, action: #selector(touchDown), for: UIControlEvents.touchDown)
    }
    
    override func prepareForInterfaceBuilder() {
        //clear the title
        self.setTitle("", for:UIControlState.normal)
    }
    
    override func draw(_ rect: CGRect) {
        //always draw the outer ring, the inner control is drawn during the animations
        let outerRing = UIBezierPath(ovalIn: CGRect(x:3, y:3, width:60, height:60))
        outerRing.lineWidth = 6
        UIColor.white.setStroke()
        outerRing.stroke()
    }
    
    func touchUpInside(sender:UIButton) {
                //Create the animation to restore the color of the button
                let colorChange = CABasicAnimation(keyPath: "fillColor")
                colorChange.duration = animationDuration;
                colorChange.toValue = UIColor.white.cgColor
        
                //make sure that the color animation is not reverted once the animation is completed
                colorChange.fillMode = kCAFillModeForwards
                colorChange.isRemovedOnCompletion = false
        
                //indicate which animation timing function to use, in this case ease in and ease out
                colorChange.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        
                //add the animation
                self.pathLayer.add(colorChange, forKey:"darkColor")
    }
    
    func touchDown(sender:UIButton) {
        //when the user touches the button, the inner shape should change transparency
        //create the animation for the fill color
        let morph = CABasicAnimation(keyPath: "fillColor")
        morph.duration = animationDuration;
        
        //set the value we want to animate to
        morph.toValue = UIColor(colorLiteralRed: 1, green: 1, blue: 1, alpha: 0.5).cgColor
        
        //ensure the animation does not get reverted once completed
        morph.fillMode = kCAFillModeForwards
        morph.isRemovedOnCompletion = false
        
        morph.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        self.pathLayer.add(morph, forKey:"")
    }
    
    func innerCirclePath () -> UIBezierPath {
        return UIBezierPath(roundedRect: CGRect(x:8, y:8, width:50, height:50), cornerRadius: 25)
    }

}
