//
//  ViewController.swift
//  imageToVideo
//
//  Created by Dhruv Singh on 08/06/16.
//  Copyright © 2016 Dhruv Singh. All rights reserved.
//

import UIKit
import AVFoundation
import MobileCoreServices
import AssetsLibrary
import MediaPlayer
import CoreMedia

class ViewController: UIViewController ,UIWebViewDelegate{
    
    var firstAsset: AVAsset?
    var secondAsset: AVAsset?
    var audioAsset: AVAsset?
    var loadingAssetOne = false
    //  MARK:- Add textlayer
   // var assetExport: AVAssetExportSession?
    
    
    //MARK:-    Action
    
    @IBAction func btnPrssAddtextToVideo(sender: AnyObject) {
        
        let videoPath = NSBundle.mainBundle().pathForResource("Movie.m4v", ofType: "")
        let videoURL = NSURL(fileURLWithPath: videoPath!)
        let videoAsset = AVURLAsset.init(URL: videoURL)
        let mixComposition = AVMutableComposition()
        let compositionVideoTrack = mixComposition.addMutableTrackWithMediaType(AVMediaTypeVideo, preferredTrackID: Int32(kCMPersistentTrackID_Invalid))
        do {
            try compositionVideoTrack.insertTimeRange(CMTimeRangeMake(kCMTimeZero, videoAsset.duration), ofTrack: videoAsset.tracksWithMediaType(AVMediaTypeVideo)[0], atTime: kCMTimeZero)
        } catch _ {
            print("Failed to load first track")
        }
        
        // parent layer
        compositionVideoTrack.preferredTransform = videoAsset.tracksWithMediaType(AVMediaTypeVideo)[0].preferredTransform
        let videoTrack: AVAssetTrack = videoAsset.tracksWithMediaType(AVMediaTypeVideo)[0]
        let videoSize: CGSize = videoTrack.naturalSize
        let parentLayer: CALayer = CALayer()
        let videoLayer: CALayer = CALayer()
        parentLayer.frame = CGRectMake(0, 0, videoSize.width, videoSize.height)
        videoLayer.frame = CGRectMake(0, 0, videoSize.width, videoSize.height)
        parentLayer.addSublayer(videoLayer)
        
        // create text Layer
        let titleLayer: CATextLayer = CATextLayer()
        titleLayer.backgroundColor = UIColor.clearColor().CGColor
        titleLayer.string = "Helllo World, Displaying text on the video."
        titleLayer.font = CFBridgingRetain("Helvetica")
        titleLayer.fontSize = 28
        titleLayer.shadowOpacity = 0.5
        titleLayer.alignmentMode = kCAAlignmentCenter
        titleLayer.frame = CGRectMake(0, 50, videoSize.width, videoSize.height / 6)
        parentLayer.addSublayer(titleLayer)
        
        //create the composition and add the instructions to insert the layer:
        let videoComp: AVMutableVideoComposition = AVMutableVideoComposition()
        videoComp.renderSize = videoSize
        videoComp.frameDuration = CMTimeMake(1, 30)
        videoComp.animationTool = AVVideoCompositionCoreAnimationTool.init(postProcessingAsVideoLayer: videoLayer, inLayer: parentLayer)
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRangeMake(kCMTimeZero, mixComposition.duration)
        let mixVideoTrack: AVAssetTrack = mixComposition.tracksWithMediaType(AVMediaTypeVideo)[0]
        let layerInstruction = AVMutableVideoCompositionLayerInstruction.init(assetTrack: mixVideoTrack)
        instruction.layerInstructions = [layerInstruction]
        videoComp.instructions = [instruction]
        // export video
        let assetExport = AVAssetExportSession.init(asset: mixComposition, presetName: AVAssetExportPresetMediumQuality)
        assetExport!.videoComposition = videoComp;
        // export video
        let videoName: String = "NewWatermarkedVideo3.mov"
        let exportPath: String = NSTemporaryDirectory().stringByAppendingString(videoName)
        let exportUrl: NSURL = NSURL.fileURLWithPath(exportPath)
        // export video
        let manager = NSFileManager.defaultManager()
        if (manager.fileExistsAtPath(exportPath)) {
            do {
                try manager.removeItemAtURL(exportUrl)
            } catch let error as NSError {
                print("Error: \(error)")
            }
        }
        assetExport!.outputFileType = AVFileTypeQuickTimeMovie
        assetExport!.outputURL = exportUrl
        assetExport!.shouldOptimizeForNetworkUse = true
         print("Output url = \(exportUrl)")
        assetExport!.exportAsynchronouslyWithCompletionHandler({() -> Void in
            //Final code here
            switch assetExport!.status {
            case .Unknown:
                print("Unknown")
            case .Waiting:
                print("Waiting")
            case .Exporting:
                print("Exporting")
            case .Completed:
                print("Created new video with text !")
            case .Failed:
                print("Failed- \(assetExport!.error)")
            case .Cancelled:
                NSLog("Cancelled")
            }
            
        })

    }
    
    @IBAction func btnPrssimgToVideo(sender: AnyObject) {
        
        // Convert image to mp4
        self.build(outputSize: outputSize)
        
    }
    
    
    @IBAction func btnPrssVideoMerge(sender: AnyObject) {
        self.mergeAndSave()
    }
    
    
    
    @IBOutlet weak var webView: UIImageView!
    
    var choosenPhotos: [UIImage] = [UIImage(named:"black")!,UIImage(named:"black")!,
                                    UIImage(named:"black")!,
                                    UIImage(named:"black")!]
    var outputSize = CGSizeMake(1280, 720)
  
    func build(outputSize outputSize: CGSize) {
        let fileManager = NSFileManager.defaultManager()
        let urls = fileManager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        guard let documentDirectory: NSURL = urls.first else {
            fatalError("documentDir Error")
        }
        
        let videoOutputURL = documentDirectory.URLByAppendingPathComponent("OutputVideo.mp4")
        
        if NSFileManager.defaultManager().fileExistsAtPath(videoOutputURL.path!) {
            do {
                try NSFileManager.defaultManager().removeItemAtPath(videoOutputURL.path!)
            } catch {
                fatalError("Unable to delete file: \(error) : \(#function).")
            }
        }
        
        guard let videoWriter = try? AVAssetWriter(URL: videoOutputURL, fileType: AVFileTypeMPEG4) else {
            fatalError("AVAssetWriter error")
        }
        
        let outputSettings = [AVVideoCodecKey : AVVideoCodecH264, AVVideoWidthKey : NSNumber(float: Float(outputSize.width)), AVVideoHeightKey : NSNumber(float: Float(outputSize.height))]
        
        guard videoWriter.canApplyOutputSettings(outputSettings, forMediaType: AVMediaTypeVideo) else {
            fatalError("Negative : Can't apply the Output settings...")
        }
        
        let videoWriterInput = AVAssetWriterInput(mediaType: AVMediaTypeVideo, outputSettings: outputSettings)
        let sourcePixelBufferAttributesDictionary = [kCVPixelBufferPixelFormatTypeKey as String : NSNumber(unsignedInt: kCVPixelFormatType_32ARGB), kCVPixelBufferWidthKey as String: NSNumber(float: Float(outputSize.width)), kCVPixelBufferHeightKey as String: NSNumber(float: Float(outputSize.height))]
        let pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: videoWriterInput, sourcePixelBufferAttributes: sourcePixelBufferAttributesDictionary)
        
        if videoWriter.canAddInput(videoWriterInput) {
            videoWriter.addInput(videoWriterInput)
        }
        
        if videoWriter.startWriting() {
            videoWriter.startSessionAtSourceTime(kCMTimeZero)
            assert(pixelBufferAdaptor.pixelBufferPool != nil)
            
            let media_queue = dispatch_queue_create("mediaInputQueue", nil)
            
            videoWriterInput.requestMediaDataWhenReadyOnQueue(media_queue, usingBlock: { () -> Void in
                let fps: Int32 = 1
                let frameDuration = CMTimeMake(1, fps)
                
                var frameCount: Int64 = 0
                var appendSucceeded = true
                
                while (!self.choosenPhotos.isEmpty) {
                    if (videoWriterInput.readyForMoreMediaData) {
                        let nextPhoto = self.choosenPhotos.removeAtIndex(0)
                        let lastFrameTime = CMTimeMake(frameCount, fps)
                        let presentationTime = frameCount == 0 ? lastFrameTime : CMTimeAdd(lastFrameTime, frameDuration)
                        
                        var pixelBuffer: CVPixelBuffer? = nil
                        let status: CVReturn = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pixelBufferAdaptor.pixelBufferPool!, &pixelBuffer)
                        
                        if let pixelBuffer = pixelBuffer where status == 0 {
                            let managedPixelBuffer = pixelBuffer
                            
                            CVPixelBufferLockBaseAddress(managedPixelBuffer, 0)
                            
                            let data = CVPixelBufferGetBaseAddress(managedPixelBuffer)
                            let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
                            let context = CGBitmapContextCreate(data, Int(self.outputSize.width), Int(self.outputSize.height), 8, CVPixelBufferGetBytesPerRow(managedPixelBuffer), rgbColorSpace, CGImageAlphaInfo.PremultipliedFirst.rawValue)
                            
                            CGContextClearRect(context, CGRectMake(0, 0, CGFloat(self.outputSize.width), CGFloat(self.outputSize.height)))
                            
                            let horizontalRatio = CGFloat(self.outputSize.width) / nextPhoto.size.width
                            let verticalRatio = CGFloat(self.outputSize.height) / nextPhoto.size.height
                            //aspectRatio = max(horizontalRatio, verticalRatio) // ScaleAspectFill
                            let aspectRatio = min(horizontalRatio, verticalRatio) // ScaleAspectFit
                            
                            let newSize:CGSize = CGSizeMake(nextPhoto.size.width * aspectRatio, nextPhoto.size.height * aspectRatio)
                            
                            let x = newSize.width < self.outputSize.width ? (self.outputSize.width - newSize.width) / 2 : 0
                            let y = newSize.height < self.outputSize.height ? (self.outputSize.height - newSize.height) / 2 : 0
                            
                            CGContextDrawImage(context, CGRectMake(x, y, newSize.width, newSize.height), nextPhoto.CGImage)
                            
                            CVPixelBufferUnlockBaseAddress(managedPixelBuffer, 0)
                            
                            appendSucceeded = pixelBufferAdaptor.appendPixelBuffer(pixelBuffer, withPresentationTime: presentationTime)
                        } else {
                            print("Failed to allocate pixel buffer")
                            appendSucceeded = false
                        }
                    }
                    if !appendSucceeded {
                        break
                    }
                    frameCount += 1
                }
                videoWriterInput.markAsFinished()
                videoWriter.finishWritingWithCompletionHandler { () -> Void in
                    print("FINISHED!!!!!")
                }
            })
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let startVid: String = NSBundle.mainBundle().pathForResource("StartVid", ofType: "mp4")!
        let stopVid: String = NSBundle.mainBundle().pathForResource("vid3", ofType: "mp4")!

        // Create First Asset For Video 1
        let firstUrl: NSURL = NSURL.fileURLWithPath(startVid)
        firstAsset = AVAsset.init(URL: firstUrl)
        
        let lastUrl: NSURL = NSURL.fileURLWithPath(stopVid)
        secondAsset = AVAsset.init(URL: lastUrl)
        
    

    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func mergeAndSave(){
        if let firstAsset = firstAsset, secondAsset = secondAsset {
            
            // 1 - Create AVMutableComposition object. This object will hold your AVMutableCompositionTrack instances.
            let mixComposition = AVMutableComposition()
            
            // 2 - Create two video tracks
            let firstTrack = mixComposition.addMutableTrackWithMediaType(AVMediaTypeVideo, preferredTrackID: Int32(kCMPersistentTrackID_Invalid))
            do {
                try firstTrack.insertTimeRange(CMTimeRangeMake(kCMTimeZero, firstAsset.duration), ofTrack: firstAsset.tracksWithMediaType(AVMediaTypeVideo)[0], atTime: kCMTimeZero)
            } catch _ {
                print("Failed to load first track")
            }
            
            let secondTrack = mixComposition.addMutableTrackWithMediaType(AVMediaTypeVideo, preferredTrackID: Int32(kCMPersistentTrackID_Invalid))
            do {
                try secondTrack.insertTimeRange(CMTimeRangeMake(kCMTimeZero, secondAsset.duration), ofTrack: secondAsset.tracksWithMediaType(AVMediaTypeVideo)[0], atTime: firstAsset.duration)
            } catch _ {
                print("Failed to load second track")
            }
            
            // 2.1
            let mainInstruction = AVMutableVideoCompositionInstruction()
            mainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeAdd(firstAsset.duration, secondAsset.duration))
            
            // 2.2
            let firstInstruction = videoCompositionInstructionForTrack(firstTrack, asset: firstAsset)
            firstInstruction.setOpacity(0.0, atTime: firstAsset.duration)
            let secondInstruction = videoCompositionInstructionForTrack(secondTrack, asset: secondAsset)
            
            // 2.3
            mainInstruction.layerInstructions = [firstInstruction, secondInstruction]
            let mainComposition = AVMutableVideoComposition()
            mainComposition.instructions = [mainInstruction]
            mainComposition.frameDuration = CMTimeMake(1, 30)
            mainComposition.renderSize = CGSize(width: UIScreen.mainScreen().bounds.width, height: UIScreen.mainScreen().bounds.height)
            
            // 3 - Audio track
            if let loadedAudioAsset = audioAsset {
                let audioTrack = mixComposition.addMutableTrackWithMediaType(AVMediaTypeAudio, preferredTrackID: 0)
                do {
                    try audioTrack.insertTimeRange(CMTimeRangeMake(kCMTimeZero, CMTimeAdd(firstAsset.duration, secondAsset.duration)),
                                                   ofTrack: loadedAudioAsset.tracksWithMediaType(AVMediaTypeAudio)[0] ,
                                                   atTime: kCMTimeZero)
                } catch _ {
                    print("Failed to load Audio track")
                }
            }
            
            // 4 - Get path
            let documentDirectory = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateStyle = .LongStyle
            dateFormatter.timeStyle = .ShortStyle
            let date = dateFormatter.stringFromDate(NSDate())
            let savePath = (documentDirectory as NSString).stringByAppendingPathComponent("mergeVideo-\(date).mov")
            let url = NSURL(fileURLWithPath: savePath)
            
            // 5 - Create Exporter
            guard let exporter = AVAssetExportSession(asset: mixComposition, presetName: AVAssetExportPresetHighestQuality) else { return }
            exporter.outputURL = url
            exporter.outputFileType = AVFileTypeQuickTimeMovie
            exporter.shouldOptimizeForNetworkUse = true
            exporter.videoComposition = mainComposition
            
            // 6 - Perform the Export
            exporter.exportAsynchronouslyWithCompletionHandler() {
                dispatch_async(dispatch_get_main_queue()) { _ in
                 //   self.exportDidFinish(exporter)
                    
                }
            }
        }
    }

    }
    
    func orientationFromTransform(transform: CGAffineTransform) -> (orientation: UIImageOrientation, isPortrait: Bool) {
        var assetOrientation = UIImageOrientation.Up
        var isPortrait = false
        if transform.a == 0 && transform.b == 1.0 && transform.c == -1.0 && transform.d == 0 {
            assetOrientation = .Right
            isPortrait = true
        } else if transform.a == 0 && transform.b == -1.0 && transform.c == 1.0 && transform.d == 0 {
            assetOrientation = .Left
            isPortrait = true
        } else if transform.a == 1.0 && transform.b == 0 && transform.c == 0 && transform.d == 1.0 {
            assetOrientation = .Up
        } else if transform.a == -1.0 && transform.b == 0 && transform.c == 0 && transform.d == -1.0 {
            assetOrientation = .Down
        }
        return (assetOrientation, isPortrait)
    }
    
    func videoCompositionInstructionForTrack(track: AVCompositionTrack, asset: AVAsset) -> AVMutableVideoCompositionLayerInstruction {
        let instruction = AVMutableVideoCompositionLayerInstruction(assetTrack: track)
        let assetTrack = asset.tracksWithMediaType(AVMediaTypeVideo)[0]
        
        let transform = assetTrack.preferredTransform
        let assetInfo = orientationFromTransform(transform)
        
        var scaleToFitRatio = UIScreen.mainScreen().bounds.width / assetTrack.naturalSize.width
        if assetInfo.isPortrait {
            scaleToFitRatio = UIScreen.mainScreen().bounds.width / assetTrack.naturalSize.height
            let scaleFactor = CGAffineTransformMakeScale(scaleToFitRatio, scaleToFitRatio)
            instruction.setTransform(CGAffineTransformConcat(assetTrack.preferredTransform, scaleFactor),
                                     atTime: kCMTimeZero)
        } else {
            let scaleFactor = CGAffineTransformMakeScale(scaleToFitRatio, scaleToFitRatio)
            var concat = CGAffineTransformConcat(CGAffineTransformConcat(assetTrack.preferredTransform, scaleFactor), CGAffineTransformMakeTranslation(0, UIScreen.mainScreen().bounds.width / 2))
            if assetInfo.orientation == .Down {
                let fixUpsideDown = CGAffineTransformMakeRotation(CGFloat(M_PI))
                let windowBounds = UIScreen.mainScreen().bounds
                let yFix = assetTrack.naturalSize.height + windowBounds.height
                let centerFix = CGAffineTransformMakeTranslation(assetTrack.naturalSize.width, yFix)
                concat = CGAffineTransformConcat(CGAffineTransformConcat(fixUpsideDown, centerFix), scaleFactor)
            }
            instruction.setTransform(concat, atTime: kCMTimeZero)
        }
        
        return instruction
    }

func exportDidFinish(session: AVAssetExportSession)  {
    
   
    
    if session.status == AVAssetExportSessionStatus.Completed {
        let outputURL = session.outputURL
        let library = ALAssetsLibrary()
        if library.videoAtPathIsCompatibleWithSavedPhotosAlbum(outputURL) {
            library.writeVideoAtPathToSavedPhotosAlbum(outputURL,
                                                       completionBlock: { (assetURL:NSURL!, error:NSError!) -> Void in
                                                        var title = ""
                                                        var message = ""
                                                        if error != nil {
                                                            title = "Error"
                                                            message = "Failed to save video"
                                                        } else {
                                                            title = "Success"
                                                            message = "Video saved"
                                                        }
                                                        //                                                            let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
                                                        //                                                            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel, handler: nil))
                                                        //                                                            self.presentViewController(alert, animated: true, completion: nil)
            })
        }
    }
    
    // firstAsset = nil
    // secondAsset = nil

    
}

func someMethod() {
    
    let videoPath = NSBundle.mainBundle().pathForResource("Movie.m4v", ofType: "")
    let videoURL = NSURL(fileURLWithPath: videoPath!)
    let videoAsset = AVURLAsset.init(URL: videoURL)
    let mixComposition = AVMutableComposition()
    let compositionVideoTrack = mixComposition.addMutableTrackWithMediaType(AVMediaTypeVideo, preferredTrackID: Int32(kCMPersistentTrackID_Invalid))
    do {
        try compositionVideoTrack.insertTimeRange(CMTimeRangeMake(kCMTimeZero, videoAsset.duration), ofTrack: videoAsset.tracksWithMediaType(AVMediaTypeVideo)[0], atTime: kCMTimeZero)
    } catch _ {
        print("Failed to load first track")
    }

    // parent layer
    compositionVideoTrack.preferredTransform = videoAsset.tracksWithMediaType(AVMediaTypeVideo)[0].preferredTransform
    let videoTrack: AVAssetTrack = videoAsset.tracksWithMediaType(AVMediaTypeVideo)[0]
    let videoSize: CGSize = videoTrack.naturalSize
    let parentLayer: CALayer = CALayer()
    let videoLayer: CALayer = CALayer()
    parentLayer.frame = CGRectMake(0, 0, videoSize.width, videoSize.height)
    videoLayer.frame = CGRectMake(0, 0, videoSize.width, videoSize.height)
    parentLayer.addSublayer(videoLayer)
    
    // create text Layer
    let titleLayer: CATextLayer = CATextLayer()
    titleLayer.backgroundColor = UIColor.clearColor().CGColor
    titleLayer.string = "Dummy text for displaying on video"
    titleLayer.font = CFBridgingRetain("Helvetica")
    titleLayer.fontSize = 28
    titleLayer.shadowOpacity = 0.5
    titleLayer.alignmentMode = kCAAlignmentCenter
    titleLayer.frame = CGRectMake(0, 50, videoSize.width, videoSize.height / 6)
    parentLayer.addSublayer(titleLayer)
   
    //create the composition and add the instructions to insert the layer:
    let videoComp: AVMutableVideoComposition = AVMutableVideoComposition()
    videoComp.renderSize = videoSize
    videoComp.frameDuration = CMTimeMake(1, 30)
    videoComp.animationTool = AVVideoCompositionCoreAnimationTool.init(postProcessingAsVideoLayer: videoLayer, inLayer: parentLayer)
    let instruction = AVMutableVideoCompositionInstruction()
    instruction.timeRange = CMTimeRangeMake(kCMTimeZero, mixComposition.duration)
    let mixVideoTrack: AVAssetTrack = mixComposition.tracksWithMediaType(AVMediaTypeVideo)[0]
    let layerInstruction = AVMutableVideoCompositionLayerInstruction.init(assetTrack: mixVideoTrack)
    instruction.layerInstructions = [layerInstruction]
    videoComp.instructions = [instruction]
    // export video
    let assetExport = AVAssetExportSession.init(asset: mixComposition, presetName: AVAssetExportPresetMediumQuality)
    assetExport!.videoComposition = videoComp;
    // export video
    let videoName: String = "NewWatermarkedVideo.mov"
    let exportPath: String = NSTemporaryDirectory().stringByAppendingString(videoName)
    let exportUrl: NSURL = NSURL.fileURLWithPath(exportPath)
   
    // export video
    let manager = NSFileManager.defaultManager()
    if (manager.fileExistsAtPath(exportPath)) {
        do {
            try manager.removeItemAtURL(exportUrl)
        } catch let error as NSError {
            print("Error: \(error)")
        }
    }
    assetExport!.outputFileType = AVFileTypeQuickTimeMovie
    assetExport!.outputURL = exportUrl
    assetExport!.shouldOptimizeForNetworkUse = true
    assetExport!.exportAsynchronouslyWithCompletionHandler({() -> Void in
        //Final code here
        switch assetExport!.status {
        case .Unknown:
            print("Unknown")
        case .Waiting:
            print("Waiting")
        case .Exporting:
            print("Exporting")
        case .Completed:
            print("Created new video with text !")
        case .Failed:
            print("Failed- \(assetExport!.error)")
        case .Cancelled:
            NSLog("Cancelled")
        }
        
    })

    
    
}







