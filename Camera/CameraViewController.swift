//
//  CameraViewController.swift
//  Camera
//
//  Created by Doug Diego on 1/25/17.
//  Copyright © 2017 Doug Diego. All rights reserved.
//

import UIKit
import AVFoundation
import Photos

private enum AVCamManualSetupResult: Int {
    case success
    case cameraNotAuthorized
    case sessionConfigurationFailed
}

private var SessionRunningContext = 0

@objc(CameraViewController)
class CameraViewController: UIViewController {
    
    @IBOutlet var previewView: CameraPreviewView!
    @IBOutlet weak var photoButton: UIButton!
    
    var session: AVCaptureSession!
    var stillImageOutput: AVCapturePhotoOutput!
    
    // Session management.
    private var sessionQueue: DispatchQueue!
    private var setupResult: AVCamManualSetupResult = .success
    private var isSessionRunning: Bool = false
    dynamic var photoOutput: AVCapturePhotoOutput?
    dynamic var videoDeviceInput: AVCaptureDeviceInput?
    dynamic var videoDevice: AVCaptureDevice?
    
    private var inProgressPhotoCaptureDelegates: [Int64: CameraPhotoCaptureDelegateType] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Disable UI. The UI is enabled if and only if the session starts running.
        self.photoButton.isEnabled = false
        
        // Create the AVCaptureSession.
        session = AVCaptureSession()
        
        // Setup the preview view.
        self.previewView.session = self.session
        
        // Communicate with the session and other session objects on this queue.
        self.sessionQueue = DispatchQueue(label: "session queue", attributes: [])
        
        self.setupResult = .success
        
        self.sessionQueue.async {
            self.configureSession()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.sessionQueue.async {
            switch self.setupResult {
            case .success:
                // Only setup observers and start the session running if setup succeeded.
                self.addObservers()
                self.session.startRunning()
                self.isSessionRunning = self.session.isRunning
            case .cameraNotAuthorized:
                DispatchQueue.main.async {
                    let message = NSLocalizedString("Camera doesn't have permission to use the camera, please change privacy settings", comment: "Alert message when the user has denied access to the camera" )
                    let alertController = UIAlertController(title: "Camera", message: message, preferredStyle: .alert)
                    let cancelAction = UIAlertAction(title: NSLocalizedString("OK", comment: "Alert OK button"), style: .cancel, handler: nil)
                    alertController.addAction(cancelAction)
                    // Provide quick access to Settings.
                    let settingsAction = UIAlertAction(title: NSLocalizedString("Settings", comment: "Alert button to open Settings"), style: .default) {action in
                        if #available(iOS 10.0, *) {
                            UIApplication.shared.open(URL(string: UIApplicationOpenSettingsURLString)!)
                        } else {
                            UIApplication.shared.openURL(URL(string: UIApplicationOpenSettingsURLString)!)
                        }
                    }
                    alertController.addAction(settingsAction)
                    self.present(alertController, animated: true, completion: nil)
                }
            case .sessionConfigurationFailed:
                DispatchQueue.main.async {
                    let message = NSLocalizedString("Unable to capture media", comment: "Alert message when something goes wrong during capture session configuration")
                    let alertController = UIAlertController(title: "Camera", message: message, preferredStyle: .alert)
                    let cancelAction = UIAlertAction(title: NSLocalizedString("OK", comment: "Alert OK button"), style: .cancel, handler: nil)
                    alertController.addAction(cancelAction)
                    self.present(alertController, animated: true, completion: nil)
                }
            }
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        self.sessionQueue.async {
            if self.setupResult == .success {
                self.session.stopRunning()
                self.removeObservers()
            }
        }
        
        super.viewDidDisappear(animated)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        let deviceOrientation = UIDevice.current.orientation
        
        if UIDeviceOrientationIsPortrait(deviceOrientation) || UIDeviceOrientationIsLandscape(deviceOrientation) {
            let previewLayer = self.previewView.layer as! AVCaptureVideoPreviewLayer
            previewLayer.connection.videoOrientation = AVCaptureVideoOrientation(rawValue: deviceOrientation.rawValue)!
        }
    }
    
    override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.all
    }
    
    override var shouldAutorotate : Bool {
        // Disable autorotation of the interface when recording is in progress.
        //return !(self.movieFileOutput?.isRecording ?? false);
        return true
    }
    
    override var prefersStatusBarHidden : Bool {
        return true
    }
    
    // Should be called on the session queue
    private func configureSession() {
        self.session.beginConfiguration()
        
        self.session.sessionPreset = AVCaptureSessionPresetPhoto
        
        let videoDevice = AVCaptureDevice.defaultDevice(withDeviceType: .builtInWideAngleCamera, mediaType:AVMediaTypeVideo, position: .unspecified)
        
        let videoDeviceInput: AVCaptureDeviceInput
        do {
            videoDeviceInput = try AVCaptureDeviceInput(device:videoDevice)
        } catch {
            NSLog("Could not create video device input: \(error)")
            self.setupResult = .sessionConfigurationFailed
            self.session.commitConfiguration()
            return
        }
        
        if self.session.canAddInput(videoDeviceInput) {
            self.session.addInput(videoDeviceInput)
            self.videoDeviceInput = videoDeviceInput
            self.videoDevice = videoDevice
            
            DispatchQueue.main.async {
                /*
                 Why are we dispatching this to the main queue?
                 Because AVCaptureVideoPreviewLayer is the backing layer for AVCamManualPreviewView and UIView
                 can only be manipulated on the main thread.
                 Note: As an exception to the above rule, it is not necessary to serialize video orientation changes
                 on the AVCaptureVideoPreviewLayer’s connection with other session manipulation.
                 
                 Use the status bar orientation as the initial video orientation. Subsequent orientation changes are
                 handled by -[AVCamManualCameraViewController viewWillTransitionToSize:withTransitionCoordinator:].
                 */
                let statusBarOrientation = UIApplication.shared.statusBarOrientation
                var initialVideoOrientation = AVCaptureVideoOrientation.portrait
                if statusBarOrientation != UIInterfaceOrientation.unknown {
                    initialVideoOrientation = AVCaptureVideoOrientation(rawValue: statusBarOrientation.rawValue)!
                }
                
                let previewLayer = self.previewView.layer as! AVCaptureVideoPreviewLayer
                previewLayer.connection.videoOrientation = initialVideoOrientation
            }
        } else {
            NSLog("Could not add video device input to the session")
            self.setupResult = .sessionConfigurationFailed
            self.session.commitConfiguration()
            return
        }
        
        // Add photo output
        let photoOutput = AVCapturePhotoOutput()
        if self.session.canAddOutput(photoOutput) {
            self.session.addOutput(photoOutput)
            self.photoOutput = photoOutput
            photoOutput.isHighResolutionCaptureEnabled = true
            
            //self.inProgressPhotoCaptureDelegates = [:]
        } else {
            NSLog("Could not add photo output to the session")
            self.setupResult = .sessionConfigurationFailed
            self.session.commitConfiguration()
            return
        }
        
        self.session.commitConfiguration()
    }
    private func currentPhotoSettings() -> AVCapturePhotoSettings? {
        guard let photoOutput = self.photoOutput else {
            return nil
        }
        let photoSettings = AVCapturePhotoSettings()
        photoSettings.flashMode = .auto
        photoSettings.isAutoStillImageStabilizationEnabled = true
        photoSettings.isHighResolutionPhotoEnabled = true
        
        photoSettings.flashMode = photoOutput.supportedFlashModes.contains(AVCaptureFlashMode.auto.rawValue as NSNumber) ? .auto : .off
        
        
        if !(photoSettings.availablePreviewPhotoPixelFormatTypes.isEmpty ) {
            photoSettings.previewPhotoFormat = [kCVPixelBufferPixelFormatTypeKey as String: photoSettings.availablePreviewPhotoPixelFormatTypes[0]] // The first format in the array is the preferred format
        }
        
        return photoSettings
    }
    
    @IBAction func capturePhoto(_: Any) {
        NSLog("capture photo")
        
        // Retrieve the video preview layer's video orientation on the main queue before entering the session queue
        // We do this to ensure UI elements are accessed on the main thread and session configuration is done on the session queue
        let previewLayer = self.previewView.layer as! AVCaptureVideoPreviewLayer
        let videoPreviewLayerVideoOrientation = previewLayer.connection.videoOrientation
        
        let settings = self.currentPhotoSettings()
        self.sessionQueue.async {
            
            // Update the orientation on the photo output video connection before capturing
            let photoOutputConnection = self.photoOutput?.connection(withMediaType: AVMediaTypeVideo)
            photoOutputConnection?.videoOrientation = videoPreviewLayerVideoOrientation
            
            // Use a separate object for the photo capture delegate to isolate each capture life cycle.
            let photoCaptureDelegate = CameraPhotoCaptureDelegate(requestedPhotoSettings: settings!, willCapturePhotoAnimation: {
                // Perform a shutter animation.
                DispatchQueue.main.async {
                    self.previewView.layer.opacity = 0.0
                    UIView.animate(withDuration: 0.25) {
                        self.previewView.layer.opacity = 1.0
                    }
                }
            }, completed: {photoCaptureDelegate in
                // When the capture is complete, remove a reference to the photo capture delegate so it can be deallocated.
                self.sessionQueue.async {
                    self.inProgressPhotoCaptureDelegates[photoCaptureDelegate.requestedPhotoSettings.uniqueID] = nil
                }
            })
            
            /*
             The Photo Output keeps a weak reference to the photo capture delegate so
             we store it in an array to maintain a strong reference to this object
             until the capture is completed.
             */
            self.inProgressPhotoCaptureDelegates[photoCaptureDelegate.requestedPhotoSettings.uniqueID] = photoCaptureDelegate
            self.photoOutput?.capturePhoto(with: settings!, delegate: photoCaptureDelegate)
        }
    }
    
    private func addObservers() {
        self.addObserver(self, forKeyPath: "session.running", options: .new, context: &SessionRunningContext)
    }
    
    private func removeObservers() {
        NotificationCenter.default.removeObserver(self)
        
        self.removeObserver(self, forKeyPath: "session.running", context: &SessionRunningContext)
    }
    
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        let oldValue = change![.oldKey]
        let newValue = change![.newKey]
        
        guard let context = context else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: nil)
            return
        }
        
        switch context {
        case &SessionRunningContext:
            NSLog("SessionRunningContext")
            var isRunning = false
            if let value = newValue as? Bool {
                isRunning = value
            }
            DispatchQueue.main.async {
                self.photoButton.isEnabled = isRunning
            }
        default:
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
        
    }

}
