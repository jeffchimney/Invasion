import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate, SCNPhysicsContactDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var creepsLabel: UILabel!
    @IBOutlet weak var leftIndicator: UIImageView!
    @IBOutlet weak var rightIndicator: UIImageView!
    
    var aliens: [Alien] = []
    var spawnTime: TimeInterval = 10
    var spawnCoolDown: TimeInterval = 10
    
    private var userScore: Int = 0 {
        didSet {
            // ensure UI update runs on main thread
            DispatchQueue.main.async {
                self.scoreLabel.text = String(self.userScore)
            }
        }
    }
    
    private var creepsOnScreen: Int = 0 {
        didSet {
            // ensure UI update runs on main thread
            DispatchQueue.main.async {
                self.creepsLabel.text = String(self.creepsOnScreen)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new empty scene
        let scene = SCNScene()
        
        // Set the scene to the view
        sceneView.scene = scene
        sceneView.scene.physicsWorld.contactDelegate = self
        
        leftIndicator.isHidden = true
        rightIndicator.isHidden = true
        
        self.addAlien()
        
        self.userScore = 0
        self.creepsOnScreen = aliens.count
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.configureSession()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    // MARK: - ARSCNViewDelegate
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        print("Session failed with error: \(error.localizedDescription)")
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
    
/*
     // ARKit detects planes in the Real World to serve as anchors--we can add a node manually to visualize them.
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        
        // This visualization covers only detected planes.
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        print("flat plane detected")
        
        // Create a SceneKit plane to visualize the node using its position and extent.
        let plane = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))
        let planeNode = SCNNode(geometry: plane)
        planeNode.position = SCNVector3Make(planeAnchor.center.x, 0, planeAnchor.center.z)
        
        // SCNPlanes are vertically oriented in their local coordinate space.
        // Rotate it to match the horizontal orientation of the ARPlaneAnchor.
        planeNode.transform = SCNMatrix4MakeRotation(-Float.pi / 2, 1, 0, 0)
        
        // ARKit owns the node corresponding to the anchor, so make the plane a child node.
        node.addChildNode(planeNode)
    }
 */
    
    @IBAction func didTapScreen(_ sender: UITapGestureRecognizer) { // fire bullet in direction camera is facing
        let bulletsNode = Bullet()
        
        let (direction, position) = self.getUserVector()
        bulletsNode.position = position // SceneKit/AR coordinates are in meters
        
        let bulletDirection = direction
        bulletsNode.physicsBody?.applyForce(bulletDirection, asImpulse: true)
        sceneView.scene.rootNode.addChildNode(bulletsNode)
        
    }
    
    func configureSession() {
        if ARWorldTrackingSessionConfiguration.isSupported {
            let configuration = ARWorldTrackingSessionConfiguration()
            configuration.planeDetection = ARWorldTrackingSessionConfiguration.PlaneDetection.horizontal
            
            sceneView.session.run(configuration)
        } else {
            let configuration = ARSessionConfiguration()
            
            sceneView.session.run(configuration)
        }
    }
    
    func addAlien() {
        let alienNode = Alien()
        
        let posX = floatBetween(-10, and: 10)
        let posY = floatBetween(0, and: 10)
        let posZ = floatBetween(-10, and: -10)
        alienNode.position = SCNVector3(posX, posY, posZ) // SceneKit/AR coordinates are in meters
        
        aliens.append(alienNode)
        sceneView.scene.rootNode.addChildNode(alienNode)
        creepsOnScreen = aliens.count
    }
    
    func removeNodeWithAnimation(_ node: SCNNode, explosion: Bool) {
        if explosion {
            let particleSystem = SCNParticleSystem(named: "explosion", inDirectory: nil)
            let systemNode = SCNNode()
            systemNode.addParticleSystem(particleSystem!)
            // place explosion where node is
            systemNode.position = node.position
            sceneView.scene.rootNode.addChildNode(systemNode)
        }
        
        // remove node
        node.removeFromParentNode()
    }
    
    func getUserVector() -> (SCNVector3, SCNVector3) { // (direction, position)
        if let frame = self.sceneView.session.currentFrame {
            let mat = SCNMatrix4FromMat4(frame.camera.transform) // 4x4 transform matrix describing camera in world space
            let dir = SCNVector3(-15 * mat.m31, -15 * mat.m32, -15 * mat.m33) // orientation of camera in world space
            let pos = SCNVector3(mat.m41, mat.m42, mat.m43) // location of camera in world space
            
            return (dir, pos)
        }
        return (SCNVector3(0, 0, -1), SCNVector3(0, 0, -0.2))
    }
    
    func floatBetween(_ first: Float,  and second: Float) -> Float { // random float between upper and lower bound (inclusive)
        return (Float(arc4random()) / Float(UInt32.max)) * (first - second) + second
    }
    
    // MARK: - Contact Delegate
    
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        //print("did begin contact", contact.nodeA.physicsBody!.categoryBitMask, contact.nodeB.physicsBody!.categoryBitMask)
        if contact.nodeA.physicsBody?.categoryBitMask == CollisionCategory.alien.rawValue || contact.nodeB.physicsBody?.categoryBitMask == CollisionCategory.alien.rawValue { // this conditional is not required--we've used the bit masks to ensure only one type of collision takes place--will be necessary as soon as more collisions are created/enabled
            print("Hit an alien!")
            self.removeNodeWithAnimation(contact.nodeB, explosion: false) // remove bullet
            self.userScore += 1
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: { // remove alien
                let index = self.aliens.index(of: contact.nodeA as! Alien)
                self.aliens.remove(at: index!)
                self.removeNodeWithAnimation(contact.nodeA, explosion: true)
                self.creepsOnScreen = self.aliens.count
            })
            //self.addAlien()
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        if aliens.count > 0 {
            let firstAlien = aliens.first
            let (userPosition, _) = getUserVector()
            
            let v = CGPoint(x: CGFloat(firstAlien!.position.x - userPosition.x), y: CGFloat(firstAlien!.position.y - userPosition.y))
            let angle = atan2(v.y, v.x) // Note: order of arguments
            
            let projectPoint = sceneView.projectPoint(firstAlien!.position)
            let projectedPoint = CGPoint(x: CGFloat(projectPoint.x), y: CGFloat(projectPoint.y))
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                let isInView = self.sceneView.frame.contains(projectedPoint)
                
                if !isInView {
                    if angle < 0 { // to the left
                        self.leftIndicator.isHidden = true
                        self.rightIndicator.isHidden = false
                    } else { // to the right
                        self.leftIndicator.isHidden = false
                        self.rightIndicator.isHidden = true
                    }
                } else {
                    self.leftIndicator.isHidden = true
                    self.rightIndicator.isHidden = true
                }
            })
        }
        
        for alien in aliens {
            if alien.position.x > 0.1 {
                alien.position.x -= 0.01
            } else if alien.position.x < -0.1 {
                alien.position.x += 0.01
            }
            
            if alien.position.y > 0.1 {
                alien.position.y -= 0.01
            } else if alien.position.y < -0.1 {
                alien.position.y += 0.01
            }
            
            if alien.position.z > 0.1 {
                alien.position.z -= 0.01
            } else if alien.position.z < -0.1 {
                alien.position.z += 0.01
            }
            
            if (alien.position.x < 0.1 && alien.position.x > -0.1 && alien.position.y < 0.1 && alien.position.y > -0.1 && alien.position.z < 0.1 && alien.position.z > -0.1)
                && (alien.position.y < 0.1 && alien.position.y > -0.1)
                && (alien.position.z < 0.1 && alien.position.z > -0.1){
                print("You lost!")
                
//                let index = self.aliens.index(of: alien)
//                self.aliens.remove(at: index!)
//                
//                alien.removeFromParentNode()
            }
            
//            print("X: \(alien.position.x)")
//            print("Y: \(alien.position.y)")
//            print("Z: \(alien.position.z)")
//            print("")
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
            if time > self.spawnTime {
                self.addAlien()
                // 2
                if (self.spawnCoolDown >= 2.0) {
                    self.spawnTime = time + self.spawnCoolDown
                    self.spawnCoolDown -= 0.5
                } else {
                    self.spawnTime = time + 2
                }
            }
        })
    }
    
    func randomBetweenNumbers(firstNum: CGFloat, secondNum: CGFloat) -> CGFloat{
        return CGFloat(arc4random()) / CGFloat(UINT32_MAX) * abs(firstNum - secondNum) + min(firstNum, secondNum)
    }
}

struct CollisionCategory: OptionSet {
    let rawValue: Int
    
    static let bullets  = CollisionCategory(rawValue: 1 << 0) // 00...01
    static let alien = CollisionCategory(rawValue: 1 << 1) // 00..10
}

extension utsname {
    func hasAtLeastA9() -> Bool { // checks if device has at least A9 chip for configuration
        var systemInfo = self
        uname(&systemInfo)
        let str = withUnsafePointer(to: &systemInfo.machine.0) { ptr in
            return String(cString: ptr)
        }
        switch str {
        case "iPhone8,1", "iPhone8,2", "iPhone8,4", "iPhone9,1", "iPhone9,2", "iPhone9,3", "iPhone9,4": // iphone with at least A9 processor
            return true
        case "iPad6,7", "iPad6,8", "iPad6,3", "iPad6,4", "iPad6,11", "iPad6,12": // ipad with at least A9 processor
            return true
        default:
            return false
        }
    }
}
