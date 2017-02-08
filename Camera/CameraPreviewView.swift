//
//  CameraPreviewView.swift
//  Camera
//
//  Created by Doug Diego on 1/25/17.
//  Copyright © 2017 Doug Diego. All rights reserved.
//

import UIKit
import AVFoundation

@objc(CameraPreviewView)
class CameraPreviewView: UIView {

    //var session: AVCaptureSession

    override class var layerClass : AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
    
    var session: AVCaptureSession? {
        get {
            let previewLayer = self.layer as! AVCaptureVideoPreviewLayer
            return previewLayer.session
        }
        
        set {
            let previewLayer = self.layer as! AVCaptureVideoPreviewLayer
            previewLayer.session = newValue
        }
    }
    
}
