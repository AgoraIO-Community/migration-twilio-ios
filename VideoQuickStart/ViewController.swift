//
//  ViewController.swift
//  VideoQuickStart
//
//  Copyright © 2016-2019 Twilio, Inc. All rights reserved.
//

import UIKit

import AgoraRtcKit

class ViewController: UIViewController {

    // MARK:- View Controller Members
    
    // Configure access token manually for testing, if desired! Create one manually in the console
    // at https://www.twilio.com/console/video/runtime/testing-tools
    var accessToken = "TWILIO_ACCESS_TOKEN"
  
    // Configure remote URL to fetch token from
    var tokenUrl = "http://localhost:8000/token.php"
    
    // Video SDK components
    var remoteView: UIView?
    var audioEnabled = true
    
    var agoraKit: AgoraRtcEngineKit!
    let AppID = "appID"
    
    // MARK:- UI Element Outlets and handles
    
    // `VideoView` created from a storyboard
    @IBOutlet weak var previewView: UIView!

    @IBOutlet weak var connectButton: UIButton!
    @IBOutlet weak var disconnectButton: UIButton!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var roomTextField: UITextField!
    @IBOutlet weak var roomLine: UIView!
    @IBOutlet weak var roomLabel: UILabel!
    @IBOutlet weak var micButton: UIButton!
    
    deinit {

    }

    // MARK:- UIViewController
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "QuickStart"
        self.messageLabel.adjustsFontSizeToFitWidth = true;
        self.messageLabel.minimumScaleFactor = 0.75;
        
        initializeAgoraEngine()
        setupVideo()
        setupLocalVideo(uid: 0)

        if PlatformUtils.isSimulator {
            self.previewView.removeFromSuperview()
        } else {
            // Preview our local camera track in the local video preview view.
            startPreview()
        }
        
        // Disconnect and mic button will be displayed when the Client is connected to a Room.
        self.disconnectButton.isHidden = true
        self.micButton.isHidden = true
        
        self.roomTextField.autocapitalizationType = .none
        self.roomTextField.delegate = self
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(ViewController.dismissKeyboard))
        self.view.addGestureRecognizer(tap)
    }
    
    func initializeAgoraEngine() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        agoraKit = AgoraRtcEngineKit.sharedEngine(withAppId: appDelegate.AppID, delegate: self)
    }
    
    func setupVideo() {
        agoraKit.enableVideo()
        agoraKit.setVideoEncoderConfiguration(AgoraVideoEncoderConfiguration(size: AgoraVideoDimension640x360, frameRate: .fps15, bitrate: AgoraVideoBitrateStandard, orientationMode: .adaptative) ) // Default video profile is 360P
        
    }
    
    func startPreview() {
        if PlatformUtils.isSimulator {
            return
        }

        previewView.backgroundColor = UIColor.orange
        
        let videoCanvas = AgoraRtcVideoCanvas()
        videoCanvas.uid = 0
        videoCanvas.view = previewView
        videoCanvas.renderMode = .hidden
        agoraKit.setupLocalVideo(videoCanvas)
    }
    
    func setupLocalVideo(uid: UInt) {
        
        previewView.tag = Int(uid)
        previewView.backgroundColor = UIColor.orange
        
        let videoCanvas = AgoraRtcVideoCanvas()
        videoCanvas.uid = uid
        videoCanvas.view = previewView
        videoCanvas.renderMode = .hidden
        agoraKit.setupLocalVideo(videoCanvas)
        
    }
    
    @IBAction func toggleMic(sender: AnyObject) {
        
        agoraKit.muteLocalAudioStream(audioEnabled)
        audioEnabled = !audioEnabled
        
        // Update the button title
        if (audioEnabled) {
            self.micButton.setTitle("Mute", for: .normal)
        } else {
            self.micButton.setTitle("Unmute", for: .normal)
        }
        
    }

    // MARK:- Private
    
    @objc func flipCamera() {
        agoraKit.switchCamera()
    }

    // Update our UI based upon if we are in a Room or not
    func showRoomUI(inRoom: Bool) {
        self.connectButton.isHidden = inRoom
        self.roomTextField.isHidden = inRoom
        self.roomLine.isHidden = inRoom
        self.roomLabel.isHidden = inRoom
        self.micButton.isHidden = !inRoom
        self.disconnectButton.isHidden = !inRoom
        self.navigationController?.setNavigationBarHidden(inRoom, animated: true)
        UIApplication.shared.isIdleTimerDisabled = inRoom

        // Show / hide the automatic home indicator on modern iPhones.
        self.setNeedsUpdateOfHomeIndicatorAutoHidden()
    }
    
    @objc func dismissKeyboard() {
        if (self.roomTextField.isFirstResponder) {
            self.roomTextField.resignFirstResponder()
        }
    }
    
    func logMessage(messageText: String) {
        NSLog(messageText)
        messageLabel.text = messageText
    }
    
    @IBAction func connect(sender: AnyObject) {

        let channelName = self.roomTextField.text ?? "default"
        
        // Connect to the channel using the channel name provided.
        agoraKit.setDefaultAudioRouteToSpeakerphone(true)
        agoraKit.joinChannel(byToken: nil, channelId: channelName, info:nil, uid:0) {(sid, uid, elapsed) -> Void in
            print("successfully joined channel")
        }
        UIApplication.shared.isIdleTimerDisabled = true
        
        logMessage(messageText: "Attempting to connect to channel \(channelName)")
        
        self.showRoomUI(inRoom: true)
        self.dismissKeyboard()
    }
    
    @IBAction func disconnect(sender: AnyObject) {
        agoraKit.leaveChannel(nil)
    }
    
    func setupRemoteVideoView(uid: UInt) {
        // Creating `VideoView` programmatically
        self.remoteView = UIView()
        remoteView?.tag = Int(uid)
        remoteView?.backgroundColor = UIColor.purple
        
        let videoCanvas = AgoraRtcVideoCanvas()
        videoCanvas.uid = uid
        videoCanvas.view = remoteView
        videoCanvas.renderMode = .hidden
        agoraKit.setupRemoteVideo(videoCanvas)
        
        self.view.insertSubview(self.remoteView!, at: 0)
        
        // `VideoView` supports scaleToFill, scaleAspectFill and scaleAspectFit
        // scaleAspectFit is the default mode when you create `VideoView` programmatically.
        self.remoteView!.contentMode = .scaleAspectFit;

        let centerX = NSLayoutConstraint(item: self.remoteView!,
                                         attribute: NSLayoutConstraint.Attribute.centerX,
                                         relatedBy: NSLayoutConstraint.Relation.equal,
                                         toItem: self.view,
                                         attribute: NSLayoutConstraint.Attribute.centerX,
                                         multiplier: 1,
                                         constant: 0);
        self.view.addConstraint(centerX)
        let centerY = NSLayoutConstraint(item: self.remoteView!,
                                         attribute: NSLayoutConstraint.Attribute.centerY,
                                         relatedBy: NSLayoutConstraint.Relation.equal,
                                         toItem: self.view,
                                         attribute: NSLayoutConstraint.Attribute.centerY,
                                         multiplier: 1,
                                         constant: 0);
        self.view.addConstraint(centerY)
        let width = NSLayoutConstraint(item: self.remoteView!,
                                       attribute: NSLayoutConstraint.Attribute.width,
                                       relatedBy: NSLayoutConstraint.Relation.equal,
                                       toItem: self.view,
                                       attribute: NSLayoutConstraint.Attribute.width,
                                       multiplier: 1,
                                       constant: 0);
        self.view.addConstraint(width)
        let height = NSLayoutConstraint(item: self.remoteView!,
                                        attribute: NSLayoutConstraint.Attribute.height,
                                        relatedBy: NSLayoutConstraint.Relation.equal,
                                        toItem: self.view,
                                        attribute: NSLayoutConstraint.Attribute.height,
                                        multiplier: 1,
                                        constant: 0);
        self.view.addConstraint(height)
    }
}

// MARK:- UITextFieldDelegate
extension ViewController : UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.connect(sender: textField)
        return true
    }
}

extension ViewController: AgoraRtcEngineDelegate {
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinedOfUid uid: UInt, elapsed: Int) {
        setupRemoteVideoView(uid: uid)
    }
    
    internal func rtcEngine(_ engine: AgoraRtcEngineKit, didOfflineOfUid uid:UInt, reason:AgoraUserOfflineReason) {
        
        self.remoteView?.removeFromSuperview()
        self.remoteView = nil
    }
    
}
