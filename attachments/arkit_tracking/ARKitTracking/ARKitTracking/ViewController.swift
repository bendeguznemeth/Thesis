//
//  ViewController.swift
//  ARKitTracking
//
//  Created by Németh Bendegúz on 2019. 04. 10..
//  Copyright © 2019. Németh Bendegúz. All rights reserved.
//

import UIKit
import ARKit

class ViewController: UIViewController, ARSessionDelegate {

    @IBOutlet weak var arscnView: ARSCNView!
    @IBOutlet weak var label: UILabel!
    
    var previousPosition: simd_float4?
    var resultCount = 0
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let configuration = ARWorldTrackingConfiguration()
        arscnView.session.run(configuration)
        
        arscnView.session.delegate = self
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        arscnView.session.pause()
    }

    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        resultCount += 1
        
        if resultCount >= 30 {
            DispatchQueue.main.async {
                let currentPosition = frame.camera.transform.columns.3
                
                if let previousPosition = self.previousPosition {
                    self.label.text = "\(Int(distance(previousPosition, currentPosition) * 1000)) mm"
                }
                
                self.resultCount = 0
                self.previousPosition = currentPosition
            }
        }
    }
}
