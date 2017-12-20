//
//  ViewController.swift
//  MonstAR
//
//  Copyright © 2017 Yuma. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {
    // MARK: - Variables
    @IBOutlet var sceneView: ARSCNView!
    var visNode: SCNNode!
    var mainContainer: SCNNode!
    var gameHasStarted = false
    var foundSurface = false
    var gamePos = SCNVector3Make(0.0, 0.0, 0.0)
    var scoreLbl: UILabel!
    
    var score = 0 {
        didSet {
            scoreLbl.text = "\(score)"
        }
    }
    
    // MARK: - View Controller Handling
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Scene
        sceneView.delegate = self
        sceneView.showsStatistics = true
        
        let scene = SCNScene(named: "art.scnassets/scene.scn")!
        sceneView.scene = scene
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let configuration = ARWorldTrackingConfiguration()
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        sceneView.session.pause()
    }
    
    // MARK: - Custom functions
    func randomPos() -> SCNVector3 {
        let randX = (Float(arc4random_uniform(200)) / 100.0) - 1.0
        let randY = (Float(arc4random_uniform(200)) / 100.0) + 1.5
        
        return SCNVector3Make(randX, randY, -5.0)
    }
    
    @objc func addPlane() {
        let plane = sceneView.scene.rootNode.childNode(withName: "plane", recursively: false)?.copy() as! SCNNode
        plane.position = randomPos()
        plane.isHidden = false
        
        mainContainer.addChildNode(plane)
        
        let randSpeed = Float(arc4random_uniform(3) + 3)
        let planeAnimation = SCNAction.sequence([SCNAction.wait(duration: 10.0), SCNAction.fadeOut(duration: 1.0), SCNAction.removeFromParentNode()])
        plane.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        plane.physicsBody?.isAffectedByGravity = false
        plane.physicsBody?.applyForce(SCNVector3Make(0.0, 0.0, randSpeed), asImpulse: true)
        plane.runAction(planeAnimation)
        
        Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(addPlane), userInfo: nil, repeats: false)
    }
    
    // MARK: - Scene Handling
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if gameHasStarted {
            guard let touch = touches.first else { return }
            let touchLocation = touch.location(in: view)
            
            guard let hitTestTouch = sceneView.hitTest(touchLocation, options: nil).first else { return }
            let touchedNode = hitTestTouch.node
            
            guard touchedNode.name == "plane" else { return }
            touchedNode.physicsBody?.isAffectedByGravity = true
            touchedNode.physicsBody?.applyTorque(SCNVector4Make(0.0, 0.3, 1.0, 1.0), asImpulse: true)
            score += 1
            
            let explosion = SCNParticleSystem(named: "Explosion.scnp", inDirectory: nil)!
            touchedNode.addParticleSystem(explosion)
        } else {
            guard foundSurface else { return }
            
            gameHasStarted = true
            visNode.removeFromParentNode()
            
            // Score Lbl
            scoreLbl = UILabel(frame: CGRect(x: 0.0, y: view.frame.height * 0.05, width: view.frame.width, height: view.frame.height * 0.1))
            scoreLbl.textColor = .yellow
            scoreLbl.font = UIFont(name: "Arial", size: view.frame.width * 0.1)
            scoreLbl.text = "0"
            scoreLbl.textAlignment = .center
            
            view.addSubview(scoreLbl)
            
            // Main Container
            mainContainer = sceneView.scene.rootNode.childNode(withName: "mainContainer", recursively: false)!
            mainContainer.isHidden = false
            mainContainer.position = gamePos
            
            // Lighting (Ambient)
            let ambientLight = SCNLight()
            ambientLight.type = .ambient
            ambientLight.color = UIColor.white
            ambientLight.intensity = 300.0
            
            let ambientLightNode = SCNNode()
            ambientLightNode.light = ambientLight
            ambientLightNode.position.y = 2.0
            
            mainContainer.addChildNode(ambientLightNode)
            
            // Lighting (Omnidirectional)
            let omniLight = SCNLight()
            omniLight.type = .omni
            omniLight.color = UIColor.white
            omniLight.intensity = 1000.0
            
            let omniLightNode = SCNNode()
            omniLightNode.light = omniLight
            omniLightNode.position.y = 3.0
            
            mainContainer.addChildNode(omniLightNode)
            
            addPlane()
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        guard !gameHasStarted else { return }
        guard let hitTest = sceneView.hitTest(CGPoint(x: view.frame.midX, y: view.frame.midY), types: [.existingPlane, .featurePoint, .estimatedHorizontalPlane]).last else { return }
        
        let transform = SCNMatrix4(hitTest.worldTransform)
        gamePos = SCNVector3Make(transform.m41, transform.m42, transform.m43)
        
        if visNode == nil {
            let visPlane = SCNPlane(width: 0.3, height: 0.3)
            visPlane.firstMaterial?.diffuse.contents = #imageLiteral(resourceName: "trackerDuck")
            
            visNode = SCNNode(geometry: visPlane)
            visNode.eulerAngles.x = .pi * -0.5
            
            sceneView.scene.rootNode.addChildNode(visNode)
        }
        
        visNode.position = gamePos
        foundSurface = true
    }
}
