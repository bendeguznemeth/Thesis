//
//  ViewController.swift
//  Optical Flow
//
//  Created by Németh Bendegúz on 2018. 07. 21..
//  Copyright © 2018. Németh Bendegúz. All rights reserved.
//

import UIKit
import AVKit
import Vision

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    //UIElements
    @IBOutlet weak var exportButton: UIButton!
    @IBOutlet weak var label: UILabel!
    
    //wrapper for using c++
    let openCVWrapper = OpenCVWrapper()
    
    //variable for checking if it is the first capture or not (we can not calculate optical flow on the first run)
    var first = true
    
    let captureSession = AVCaptureSession()
    
    //CSV
    let fileName = "data.csv"
    var csvText = "time,p1t0x,p1t0y,p2t0x,p2t0y,p3t0x,p3t0y,p4t0x,p4t0y,p5t0x,p5t0y,p6t0x,p6t0y,p1t1x,p1t1y,p2t1x,p2t1y,p3t1x,p3t1y,p4t1x,p4t1y,p5t1x,p5t1y,p6t1x,p6t1y\n"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //captureSession setup
        captureSession.sessionPreset = .hd1280x720
        guard let captureDevice = AVCaptureDevice.default(for: .video) else { return }
        guard let input = try? AVCaptureDeviceInput(device: captureDevice) else { return }
        captureSession.addInput(input)
        captureSession.startRunning()
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        view.layer.addSublayer(previewLayer)
        previewLayer.frame = view.frame
        
        //UIElelments to front
        view.bringSubview(toFront: exportButton)
        view.bringSubview(toFront: label)
        
        //captureSession setup
        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "captureQueue"))
        captureSession.addOutput(dataOutput)
        
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        if (!first) {
            let date = Date()
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm:ss.SSS"
            csvText.append("\(formatter.string(from: date)),")
        }
        
        var inputforLastString = ""
        var inputforLastInts: [Double] = []
        
        guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        guard let model = try? VNCoreMLModel(for: squeezenet().model) else { return }
        
        let request = VNCoreMLRequest(model: model) { (finishedReq, err) in
            
            guard let results = finishedReq.results as? [VNClassificationObservation] else { return }
            
            guard let firstObservation = results.first else { return }
            
            //print(firstObservation.identifier, firstObservation.confidence, Date())
            
            DispatchQueue.main.async {
                self.label.text = "\(firstObservation.identifier) \(firstObservation.confidence * 100)"
            }
            
            //for last prediction
            inputforLastString = firstObservation.identifier
            
            //self.printDate(string: "")
            
        }
        
        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
        
        if (!first) {
            let array = openCVWrapper.opticalFlowTracker(sampleBuffer)
            
            for row in array! {
                let points = row as! NSMutableArray
                for anyPoint in points {
                    let point = anyPoint as! NSArray
                    csvText.append("\(point[0]),\(point[1]),")
                    
                    //for last prediction
                    inputforLastInts.append(point[0] as! Double)
                    inputforLastInts.append(point[1] as! Double)
                    
                }
            }
            
            csvText.append("\n")
            //print(csvText)
            
            //last prediction
            let regressionModel = regression()
            guard let output = try? regressionModel.prediction(object: inputforLastString, p1t0x: inputforLastInts[0], p1t0y: inputforLastInts[1], p2t0x: inputforLastInts[2], p2t0y: inputforLastInts[3], p3t0x: inputforLastInts[4], p3t0y: inputforLastInts[5], p4t0x: inputforLastInts[6], p4t0y: inputforLastInts[7], p5t0x: inputforLastInts[8], p5t0y: inputforLastInts[9], p6t0x: inputforLastInts[10], p6t0y: inputforLastInts[11], p1t1x: inputforLastInts[12], p1t1y: inputforLastInts[13], p2t1x: inputforLastInts[14], p2t1y: inputforLastInts[15], p3t1x: inputforLastInts[16], p3t1y: inputforLastInts[17], p4t1x: inputforLastInts[18], p4t1y: inputforLastInts[19], p5t1x: inputforLastInts[20], p5t1y: inputforLastInts[21], p6t1x: inputforLastInts[22], p6t1y: inputforLastInts[23]) else {
                                                                                                fatalError("Unexpected runtime error.")}
            print(output.target)
            
        } else {
            openCVWrapper.cornerDetector(sampleBuffer)
            first = false
        }
        
    }
    
    @IBAction func exportCSV(_ sender: UIButton) {
        if (captureSession.isRunning) {
            captureSession.stopRunning()
            let path = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
            do {
                //puts file in the path
                try csvText.write(to: path!, atomically: true, encoding: String.Encoding.utf8)
                //Displays export options
                let vc = UIActivityViewController(activityItems: [path!], applicationActivities: [])
                present(vc, animated: true, completion: nil)
            } catch {
                print("Failed to create file")
                print("\(error)")
            }
        } else {
            first = true
            csvText = "time,p1t0x,p1t0y,p2t0x,p2t0y,p3t0x,p3t0y,p4t0x,p4t0y,p5t0x,p5t0y,p6t0x,p6t0y,p1t1x,p1t1y,p2t1x,p2t1y,p3t1x,p3t1y,p4t1x,p4t1y,p5t1x,p5t1y,p6t1x,p6t1y\n"
            captureSession.startRunning()
        }
    }
    
//    func printDate(string: String) {
//        let date = Date()
//        let formatter = DateFormatter()
//        formatter.dateFormat = "HH:mm:ss.SSS"
//        print(string + formatter.string(from: date))
//    }
    
}

