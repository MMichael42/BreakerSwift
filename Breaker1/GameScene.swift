//
//  GameScene.swift
//  Breaker1
//
//  Created by Michael Johnson on 12/4/17.
//  Copyright © 2017 Shalapps. All rights reserved.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    // score and banner variables
    let bannerHeight : CGFloat = 100;
    let bannerColor = UIColor.black
    var scoreCountLabel = SKLabelNode(fontNamed: "emulogic")
    var highScoreLabel = SKLabelNode(fontNamed: "emulogic")
    var tapStartLabel = SKLabelNode(fontNamed: "emulogic")
    var scoreCount : Int = 0
    var highScore : Int = 0
    let fontColor = SKColor.white
    let fontSize : CGFloat = 28
    
    // user defaults for saving highscore
    let usrDefaults = UserDefaults.standard
    
    // fade actions
    let fadeIn = SKAction.fadeIn(withDuration: 1.0)
    let fadeOut = SKAction.fadeOut(withDuration: 1.0)
    
    // Game state variables
    var isBallLaunched = false
    var isGameOver = false
    var isPositionsReset = false
    var repeatAction = SKAction()
    
    // physics variables
    let startImpulseX : Int = (Int(arc4random_uniform(20)) - 10)
    let startImpulseY : Int = 90
    let velocityFloor : CGFloat = 900
    let velocityTop   : CGFloat = 1032
    let xVelocityMax  : CGFloat = 300
    
    // Brick variables
    var brickArr = [SKShapeNode]()

    // Paddle variables
    let paddleSprite = SKSpriteNode()
    let paddleSize = CGSize(width: 200, height: 40)
    let paddlePos = CGPoint(x: 0, y: -500)
    let paddleColor = UIColor.white
    var isFingerOnpaddle = false
    
    // Ball variables
    let ball = SKShapeNode(circleOfRadius: 20)
    let ballColor = UIColor.red
    let ballPos = CGPoint(x: 0, y: -500 + 41)
    let ballSpawnOffset : CGFloat = 41
    
    // Collision masks
    let edgeMask    : UInt32 = 0b00001
    let paddleMask  : UInt32 = 0b00010
    let ballMask    : UInt32 = 0b00100
    let brickMask   : UInt32 = 0b01000
    let bannerMask  : UInt32 = 0b10000
    
    // z positions
    let scoreZ  : CGFloat = 30
    let bannerZ : CGFloat = 20
    let paddleZ : CGFloat = 10
    let ballZ   : CGFloat = 10
    let brickZ  : CGFloat = 10
    
    
    override func didMove(to view: SKView) {
        physicsWorld.contactDelegate = self
        self.backgroundColor = UIColor.black
    
        // saving info, setting the highscore to the userdefaults
        highScore = usrDefaults.integer(forKey: "highscore")

        // score banner stuff
        let banner = SKShapeNode(rect: CGRect(x: self.frame.minX, y: self.frame.maxY - bannerHeight, width: self.frame.width, height: bannerHeight))
        // need SKNode attached to banner shapeNode so we can attach it a physics body
        let bannerBody = SKNode()
        // position that SKNode on top of the shapeNode
        bannerBody.position = CGPoint(x: 0, y: self.frame.maxY - (bannerHeight / 2))
        // add the SKNode as a child to the banner shapeNode
        banner.addChild(bannerBody)
        
        let bannerPhysics = SKPhysicsBody(rectangleOf: CGSize(width: self.frame.width, height: bannerHeight))
        bannerPhysics.affectedByGravity = false
        bannerPhysics.isDynamic = true
        bannerPhysics.allowsRotation = false
        bannerPhysics.restitution = 1
        bannerPhysics.friction = 0
        bannerPhysics.categoryBitMask = bannerMask
        bannerPhysics.collisionBitMask = 0
        bannerPhysics.contactTestBitMask = ballMask
        bannerBody.physicsBody = bannerPhysics
        banner.fillColor = bannerColor
        banner.strokeColor = bannerColor
        banner.zPosition = bannerZ
        self.addChild(banner)
        
        
        // score labels:
        // current score
        scoreCountLabel.text = String(scoreCount)
        scoreCountLabel.fontColor = fontColor
        scoreCountLabel.fontSize = fontSize
        scoreCountLabel.position = CGPoint(x: self.frame.maxX - 40, y: self.frame.maxY - 60)
        scoreCountLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.right
        scoreCountLabel.zPosition = scoreZ
        self.addChild(scoreCountLabel)
        // high score
        highScoreLabel.text = "highscore: \(highScore)"
        highScoreLabel.fontColor = fontColor
        highScoreLabel.fontSize = fontSize
        highScoreLabel.position = CGPoint(x: self.frame.minX + 20, y: self.frame.maxY - 60)
        highScoreLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        highScoreLabel.zPosition = scoreZ
        self.addChild(highScoreLabel)
        // tap to start label
        tapStartLabel.text = "tap paddle to start"
        tapStartLabel.fontColor = fontColor
        tapStartLabel.fontSize = fontSize
        tapStartLabel.position = CGPoint(x: 0, y: 0)
        tapStartLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.center
        tapStartLabel.zPosition = scoreZ
        tapStartLabel.alpha = 0.0
        self.addChild(tapStartLabel)
        tapStartLabel.run(fadeIn)
        
        // Edge boundry config
        let edgePhysics = SKPhysicsBody(edgeLoopFrom: self.frame)
        edgePhysics.restitution = 1
        edgePhysics.friction = 0
        edgePhysics.categoryBitMask = edgeMask
        edgePhysics.collisionBitMask = ballMask | paddleMask
        edgePhysics.contactTestBitMask = ballMask | paddleMask
        self.physicsBody = edgePhysics
        
        // Paddle config
        let paddlePhysics = SKPhysicsBody(rectangleOf: paddleSize)
        paddlePhysics.affectedByGravity = false
        paddlePhysics.isDynamic = true
        paddlePhysics.allowsRotation = false
        paddlePhysics.restitution = 1
        paddlePhysics.friction = 0
        paddlePhysics.categoryBitMask = paddleMask
        paddlePhysics.collisionBitMask = 0
        paddlePhysics.contactTestBitMask = ballMask | brickMask | edgeMask
        paddleSprite.physicsBody = paddlePhysics
        paddleSprite.position = paddlePos
        paddleSprite.size = paddleSize
        paddleSprite.color = paddleColor
        paddleSprite.zPosition = paddleZ
        paddleSprite.name = "paddle"
        paddleSprite.alpha = 0.0
        self.addChild(paddleSprite)
        paddleSprite.run(fadeIn)
        
        // Ball config code
        let ballPhysics = SKPhysicsBody(circleOfRadius: 25)
        ballPhysics.affectedByGravity = true
        ballPhysics.isDynamic = true
        ballPhysics.restitution = 1
        ballPhysics.friction = 0
        ballPhysics.linearDamping = 0
        ballPhysics.angularDamping = 0
        ballPhysics.categoryBitMask = ballMask
        ballPhysics.collisionBitMask = paddleMask | edgeMask | brickMask | bannerMask
        ballPhysics.contactTestBitMask = paddleMask | edgeMask | brickMask | bannerMask
        ball.fillColor = ballColor
        ball.strokeColor = ballColor
        ball.position = ballPos
        ball.zPosition = ballZ
        ball.isAntialiased = true
        ball.physicsBody = ballPhysics
        ball.name = "ball"
        ball.alpha = 0.0
        self.addChild(ball)
        ball.run(fadeIn)
    
        // Spawning actions, aren't run till the ball is launched on touch
        let waitAction = SKAction.wait(forDuration: 3.0)
        let spawnAction = SKAction.run({self.spawnRow()})
        let spawnSeq = SKAction.sequence([spawnAction, waitAction])
        repeatAction = SKAction.repeatForever(spawnSeq)
    }
    
    // touch functions for paddle
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first
        let touchLocation = touch!.location(in: self)
        
        if let body = physicsWorld.body(at: touchLocation) {
            // if you're touching the paddle, do the following...
            if body.node?.physicsBody?.categoryBitMask == paddleMask {
                print("touched paddle")
                isFingerOnpaddle = true
                
                // launch ball if it hasn't been launched
                if isBallLaunched == false {
                    print("launching ball")
                    isGameOver = false
                    isPositionsReset = false
                    ball.physicsBody?.applyImpulse(CGVector(dx: startImpulseX, dy: startImpulseY))
                    isBallLaunched = true
                    // fade out tap to start label
                    tapStartLabel.run(fadeOut)
                    // launch the brick spawning action
                    self.run(repeatAction, withKey: "brickSpawn")
                    
                }
            }
        }
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isFingerOnpaddle == true {
            for touch in touches {
                let location = touch.location(in: self)
                paddleSprite.position.x = location.x
            }
        }
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
    }
    
    
    func didBegin(_ contact: SKPhysicsContact) {
        var ballNode : SKNode?
        var otherNode : SKNode?
        
        // create contact mask between bodyA and bodyB
        let contactMask = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        
        // compare those masks to find what two bodies have collided, and act if needed
        switch contactMask {
        case ballMask | brickMask:
            // update score on brick collision
            scoreCount = scoreCount + 1
            scoreCountLabel.text = String(scoreCount)
            // if the current score is higher than the high score, reset the highscore
            if scoreCount > highScore {
                highScore = scoreCount
                highScoreLabel.text = "highscore: \(highScore)"
                // save the new highscore to the user defaults
                usrDefaults.set(highScore, forKey: "highscore")
            }
        case ballMask | paddleMask:
            let xModifier = calculatePaddleCollisionPoint(contactPointX: contact.contactPoint.x)
            ball.physicsBody?.velocity.dx = 0
            ball.physicsBody?.applyImpulse(CGVector(dx: xModifier * 60, dy: 0))
        case paddleMask | brickMask:
            isGameOver = true
        case ballMask | edgeMask:
            print("ball + edge hit")
        case paddleMask | edgeMask:
            print("paddle + edge")
        default:
            print("unknown collision")
        }
    
        if contact.bodyA.categoryBitMask == ballMask {
            ballNode = contact.bodyA.node
            otherNode = contact.bodyB.node
        } else if contact.bodyB.categoryBitMask == ballMask {
            ballNode = contact.bodyB.node
            otherNode = contact.bodyA.node
        } else {
            return
        }
        
        let xPos = contact.contactPoint.x
        let yPos = contact.contactPoint.y
        
        let dx = ball.physicsBody?.velocity.dx
        let dy = ball.physicsBody?.velocity.dy
        
        // if the ball has hit a brick, remove that brick
        if otherNode?.physicsBody?.categoryBitMask == brickMask {
            otherNode?.removeFromParent()
        }
        
        // print("dy velocity = \(dy!)")
        // reigh in or increase y velocity if it somehow gets too low or too high
        if dy! > CGFloat(0) && dy! < velocityFloor {
            // ball.physicsBody?.applyImpulse(CGVector(dx: 0, dy: startImpulseY))
            ball.physicsBody?.velocity.dy = velocityTop
        } else if dy! < CGFloat(0) && dy! > -velocityFloor {
            // ball.physicsBody?.applyImpulse(CGVector(dx: 0, dy: -startImpulseY))
            ball.physicsBody?.velocity.dy = -velocityTop
        }
        
        // now do the same for x velocity, except we only care if the x velocity goes beyond the upperbounds in either direction
        if dx! > xVelocityMax {
            ball.physicsBody?.velocity.dx = xVelocityMax
        } else if dx! < -xVelocityMax {
            ball.physicsBody?.velocity.dx = -xVelocityMax
        }
        
        // this code keeps the ball from riding the sides of the screen
        if xPos >= self.frame.maxX - 13 && dx! >= CGFloat(0) {
           ballNode?.physicsBody?.applyImpulse(CGVector(dx: -20, dy: 0))
        } else if xPos <= self.frame.minX + 13 && dx! <= CGFloat(0) {
            ballNode?.physicsBody?.applyImpulse(CGVector(dx: 20, dy: 0))
        }
        if yPos >= self.frame.maxY - 13 && dy! >= CGFloat(0) {
            ballNode?.physicsBody?.applyImpulse(CGVector(dx: 0, dy: -startImpulseY))
        } else if yPos <= self.frame.minY + 13 {
            print("Ball hit bottom, trigger game over")
            isGameOver = true
        }
    }
    
    func calculatePaddleCollisionPoint(contactPointX: CGFloat) -> CGFloat {
        let currentPaddlePosX = paddleSprite.position.x
        
        if contactPointX > currentPaddlePosX {
            let difference = contactPointX - currentPaddlePosX
            return (difference / paddleSize.width)
        } else if contactPointX < currentPaddlePosX {
            let difference = currentPaddlePosX - contactPointX
            return -(difference / paddleSize.width)
        } else {
            // collision has occured dead center on paddle
            return 0
        }
    }
    
    func spawnRow() {
        // number of bricks across screenw width
        let brickTotal = 4
        // current brick spawned in the line
        var brickNum = 0
        
        let screenWidth = self.frame.width
        let screenHeight = self.frame.height
        
        var xPos = -(screenWidth/2)
        let yPos = screenHeight/2
        
        let brickWidth  : CGFloat = screenWidth/4
        let brickHeight : CGFloat = 61
        let brickSize   : CGSize = CGSize(width: brickWidth, height: brickHeight)
        
        // color array to be chosen from randomly
        let colorArr = [UIColor.red, UIColor.green, UIColor.blue]
        
        let moveDownAction = SKAction.moveBy(x: 0, y: -2000, duration: 100)
        
        repeat {
            
            let selectedColor = Int(arc4random_uniform(3))
            
            // let brick = SKSpriteNode(color: colorArr[selectedColor], size: brickSize)
            let brick = SKShapeNode(rectOf: brickSize, cornerRadius: 0.0)
            brick.fillColor = colorArr[selectedColor]
            brick.strokeColor = UIColor.brown
            
            // add each of these bricks to an array I can destory when game over state hits?
            brick.position = CGPoint(x: xPos + brickWidth/2, y: yPos)
            
            let brickPhysics = SKPhysicsBody(rectangleOf: brickSize)
            brickPhysics.affectedByGravity = false
            brickPhysics.isDynamic = false
            brickPhysics.categoryBitMask = brickMask
            brickPhysics.collisionBitMask = ballMask | paddleMask
            brickPhysics.contactTestBitMask = ballMask | paddleMask
            brick.physicsBody = brickPhysics
            brick.zPosition = brickZ
            brick.name = "brick"
            brickArr.append(brick)
            self.addChild(brick)
            
            brick.run(moveDownAction)
            
            xPos += brickWidth
            brickNum += 1
        } while brickNum < brickTotal
    }

    func gameOver() {
        // remove all actions to stop the brick spawning
        self.removeAllActions()
        // remove all bricks from the brick array
        for brick in brickArr {
            // here is where we could do a an explosion effect
            brick.removeFromParent()
        }
        
        // hide ball and paddle via alpha
        ball.alpha = 0.0
        paddleSprite.alpha = 0.0
        
        // game is over, reset paddle position...
        paddleSprite.position = paddlePos
        // ...and stop the ball..
        ball.physicsBody?.velocity.dx = 0
        ball.physicsBody?.velocity.dy = 0
        // ...and place it just above where ever the paddle is
        ball.position = CGPoint(x: paddleSprite.position.x, y: paddleSprite.position.y + ballSpawnOffset)
        
        // fade back in ball and paddle
        ball.run(fadeIn)
        paddleSprite.run(fadeIn)
        
        // fade in tap to start label
        tapStartLabel.run(fadeIn)
        
        // reset the current score
        scoreCount = 0
        scoreCountLabel.text = String(scoreCount)

        // set the ball launched state to false so we know not to spawn the bricks
        isBallLaunched = false
        isPositionsReset = true
        isFingerOnpaddle = false
    }
    
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    
        // if game over mode is triggered, but positions haven't been reset...
        if isGameOver == true && isPositionsReset == false {
            gameOver()
        }
        
        // check if any bricks are off the bottom of the screen, and if they are, remove them
        for brick in brickArr {
            if brick.position.y < self.frame.minY - 60 {
                brick.removeFromParent()
            }
        }
    }
}
