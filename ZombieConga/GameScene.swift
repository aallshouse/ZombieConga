import SpriteKit

class GameScene: SKScene {
    let zombie = SKSpriteNode(imageNamed: "zombie1")
    var lastUpdateTime: TimeInterval = 0
    var dt: TimeInterval = 0
    let zombieMovePointsPerSec: CGFloat = 480.0
    var velocity = CGPoint.zero
    let playableRect: CGRect
    var lastTouchLocation = CGPoint.zero
    let zombieRotateRadiansPerSec:CGFloat = 4.0 * π
    let zombieAnimation: SKAction
    let zombieAnimationKey: String = "zombieAnimation"
    
    override init(size: CGSize) {
        let maxAspectRatio:CGFloat = 16.0 / 9.0
        let playableHeight = size.width / maxAspectRatio
        let playableMargin = (size.height - playableHeight) / 2.0
        playableRect = CGRect(x: 0, y: playableMargin,
                              width: size.width,
                              height: playableHeight)
        //1
        var textures:[SKTexture] = []
        //2
        for i in 1...4 {
            textures.append(SKTexture(imageNamed: "zombie\(i)"))
        }
        //3
        textures.append(textures[2])
        textures.append(textures[1])
        //4
        zombieAnimation = SKAction.animate(with: textures, timePerFrame: 0.1)
        super.init(size: size)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func debugDrawPlayableArea() {
        let shape = SKShapeNode()
        let path = CGMutablePath()
        path.addRect(playableRect)
        shape.path = path
        shape.strokeColor = SKColor.red
        shape.lineWidth = 4.0
        addChild(shape)
    }
    
    override func didMove(to view: SKView) {
        backgroundColor = SKColor.black
        let background = SKSpriteNode(imageNamed: "background1")
        background.anchorPoint = CGPoint(x: 0.5, y: 0.5) //default
        background.position = CGPoint(x: size.width/2, y: size.height/2)
        //background.zRotation = CGFloat(M_PI) / 8
        background.zPosition = -1
        addChild(background)
        
        zombie.position = CGPoint(x: 400, y: 400)
        addChild(zombie)
        //zombie.run(SKAction.repeatForever(zombieAnimation))
        run(SKAction.repeatForever(
            SKAction.sequence([SKAction.run() {
                    [weak self] in self?.spawnEnemy()
                },
                SKAction.wait(forDuration: 2.0)])))
        run(SKAction.repeatForever(
            SKAction.sequence([SKAction.run() {
                                [weak self] in self?.spawnCat()
                              },
                              SKAction.wait(forDuration: 1.0)])))
        debugDrawPlayableArea()
    }
    
    override func update(_ currentTime: TimeInterval) {
        if lastUpdateTime > 0 {
            dt = currentTime - lastUpdateTime
        } else {
            dt = 0
        }
        lastUpdateTime = currentTime
        //print("\(dt*1000) milliseconds since last update")
        
        let lengthToMove = zombieMovePointsPerSec * CGFloat(dt)
        let touchDistance = (zombie.position - lastTouchLocation).length()
        if(touchDistance <= lengthToMove) {
            zombie.position = lastTouchLocation
            velocity = CGPoint.zero
            stopZombieAnimation()
        } else {
            move(sprite: zombie, velocity: velocity)
            rotate(sprite: zombie, direction: velocity)
        }
        boundsCheckZombie()
    }
    
    func move(sprite: SKSpriteNode, velocity: CGPoint) {
        // 1
        let amountToMove = velocity * CGFloat(dt)
        //print("Amount to move: \(amountToMove)")
        // 2
        sprite.position += amountToMove
    }
    
    func moveZombieToward(location: CGPoint) {
        startZombieAnimation()
        let offset = location - zombie.position
        let direction = offset.normalized()
        velocity = direction * zombieMovePointsPerSec
    }
    
    func startZombieAnimation() {
        if zombie.action(forKey: zombieAnimationKey) == nil {
            zombie.run(
                SKAction.repeatForever(zombieAnimation),
                withKey: zombieAnimationKey)
        }
    }
    
    func stopZombieAnimation() {
        zombie.removeAction(forKey: zombieAnimationKey)
    }
    
    func sceneTouched(touchLocation:CGPoint) {
        lastTouchLocation = touchLocation
        moveZombieToward(location: touchLocation)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else {
            return
        }
        let touchLocation = touch.location(in: self)
        sceneTouched(touchLocation: touchLocation)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else {
            return
        }
        let touchLocation = touch.location(in: self)
        sceneTouched(touchLocation: touchLocation)
    }
    
    func boundsCheckZombie() {
        let bottomLeft = CGPoint(x: 0, y: playableRect.minY)
        let topRight = CGPoint(x: size.width, y: playableRect.maxY)
        if zombie.position.x <= bottomLeft.x {
            zombie.position.x = bottomLeft.x
            velocity.x = -velocity.x
        }
        if zombie.position.x >= topRight.x {
            zombie.position.x = topRight.x
            velocity.x = -velocity.x
        }
        if zombie.position.y <= bottomLeft.y {
            zombie.position.y = bottomLeft.y
            velocity.y = -velocity.y
        }
        if zombie.position.y >= topRight.y {
            zombie.position.y = topRight.y
            velocity.y = -velocity.y
        }
    }
    
    func rotate(sprite: SKSpriteNode, direction: CGPoint) {
        //sprite.zRotation = direction.angle
        let shortest = shortestAngleBetween(angle1: sprite.zRotation, angle2: direction.angle)
        var amountToRotate = zombieRotateRadiansPerSec * CGFloat(dt)
        if(abs(shortest) <= amountToRotate){
            amountToRotate = shortest
        }
        sprite.zRotation += amountToRotate * amountToRotate.sign()
    }
    
    func spawnCat() {
        //1
        let cat = SKSpriteNode(imageNamed: "cat")
        cat.position = CGPoint(
            x: CGFloat.random(min: playableRect.minX,
                              max: playableRect.maxX),
            y: CGFloat.random(min: playableRect.minY,
                              max: playableRect.maxY))
        cat.setScale(0)
        addChild(cat)
        //2
        let appear = SKAction.scale(to: 1.0, duration: 0.5)
        
        //let wait = SKAction.wait(forDuration: 10.0)
        cat.zRotation = -π / 16.0
        let leftWiggle = SKAction.rotate(byAngle: π/8.0, duration: 0.5)
        let rightWiggle = leftWiggle.reversed()
        let fullWiggle = SKAction.sequence([leftWiggle, rightWiggle])
        
        let scaleUp = SKAction.scale(by: 1.2, duration: 0.25)
        let scaleDown = scaleUp.reversed()
        let fullScale = SKAction.sequence([scaleUp, scaleDown, scaleUp, scaleDown])
        let group = SKAction.group([fullScale, fullWiggle])
        let groupWait = SKAction.repeat(group, count: 10)
        
        //let wiggleWait = SKAction.repeat(fullWiggle, count: 10)
        
        let disappear = SKAction.scale(to: 0, duration: 0.5)
        let removeFromParent = SKAction.removeFromParent()
        let actions = [appear, groupWait, disappear, removeFromParent]
        cat.run(SKAction.sequence(actions))
    }
    
    func spawnEnemy() {
        let enemy = SKSpriteNode(imageNamed: "enemy")
        enemy.position = CGPoint(x: size.width + enemy.size.width/2,
                                 y: CGFloat.random(
                                    min: playableRect.minY + enemy.size.height/2,
                                    max: playableRect.maxY - enemy.size.height/2))
        addChild(enemy)
        
        let actionMove =
            SKAction.moveTo(x: -enemy.size.width/2, duration: 2.0)
        let actionRemove = SKAction.removeFromParent()
        enemy.run(SKAction.sequence([actionMove, actionRemove]))
    }
}
