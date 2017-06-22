import UIKit
import SceneKit

// Floating boxes that appear around you
class Alien: SCNNode {
    override init() {
        super.init()
        let box = SCNBox(width: 0.5, height: 0.5, length: 0.5, chamferRadius: 0.1)
        self.geometry = box
        let shape = SCNPhysicsShape(geometry: box, options: nil)
        self.physicsBody = SCNPhysicsBody(type: .dynamic, shape: shape)
        self.physicsBody?.isAffectedByGravity = false
        
        // see http://texnotes.me/post/5/ for details on collisions and bit masks
        self.physicsBody?.categoryBitMask = CollisionCategory.alien.rawValue
        self.physicsBody?.contactTestBitMask = CollisionCategory.bullets.rawValue
        
        // add texture
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.blue
        self.geometry?.materials  = [material, material, material, material, material, material]
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
