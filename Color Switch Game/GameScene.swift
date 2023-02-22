//
//  GameScene.swift
//  Color Switch Game
//
//  Created by Nephilim  on 2/22/23.
//

import SpriteKit

class GameScene: SKScene {
    enum ObjectType:String {
      case player
      case colorChanger
    }

    struct PhysicsCategory {
      static let Player: UInt32 = 1
      static let Obstacle: UInt32 = 2
      static let ColorChanger: UInt32 = 3
      static let Edge: UInt32 = 4
    }

    let colors = [SKColor.yellow, SKColor.red, SKColor.blue, SKColor.purple]
    let player = SKShapeNode(circleOfRadius: 40)
    var obstacles: [SKNode] = []
    let obstacleSpacing: CGFloat = 900
    let changerSpacing: CGFloat = 1350
    let cameraNode = SKCameraNode()
    let scoreLabel = SKLabelNode()
    let highestScore = SKLabelNode()
    var score = 0
    var colorChangers = [SKNode]()


    override func didMove(to view: SKView) {
      setupPlayerAndObstacles()

      let playerBody = SKPhysicsBody(circleOfRadius: 10)
      playerBody.mass = 1.5
      playerBody.categoryBitMask = PhysicsCategory.Player
      playerBody.collisionBitMask = 4
      player.physicsBody = playerBody

      let ledge = SKNode()
      ledge.position = CGPoint(x: size.width/2, y: 160)
      let ledgeBody = SKPhysicsBody(rectangleOf: CGSize(width: 200, height: 10))
      ledgeBody.isDynamic = false
      ledgeBody.categoryBitMask = PhysicsCategory.Edge
      ledge.physicsBody = ledgeBody
      addChild(ledge)

      physicsWorld.gravity.dy = -22
      physicsWorld.contactDelegate = self

      addChild(cameraNode)
      camera = cameraNode
      cameraNode.position = CGPoint(x: size.width/2, y: size.height/2)

      scoreLabel.position = CGPoint(x: -350, y: -900)
      scoreLabel.fontColor = .white
      scoreLabel.fontSize = 150
      scoreLabel.text = String(score)
      cameraNode.addChild(scoreLabel)



      highestScore.position = CGPoint(x:150, y: 850)
      highestScore.fontColor = .white
      highestScore.fontSize = 70


      let highScore = UserDefaults.standard.integer(forKey: "highestScore")
      highestScore.text = "Highest score: \(highScore)"

      cameraNode.addChild(highestScore)
    }

    func setupPlayerAndObstacles() {
      addPlayer()
      addObstacle()
      addColorChanger()
    }

    func addPlayer() {
      player.name = ObjectType.player.rawValue
      setPlayerRandomColor()
      player.position = CGPoint(x: size.width/2, y: 200)

      addChild(player)
    }

    func setPlayerRandomColor() {
      player.fillColor = colors.randomElement()!
      player.strokeColor = player.fillColor
    }

    func addObstacle() {
      let choice = Int(arc4random_uniform(2))
      switch choice {
      case 0:
        addCircleObstacle()
      case 1:
        addSquareObstacle()
      default:
        print("something went wrong")
      }
    }

    func addColorChanger() {
      let colorChanger = SKNode()
      colorChanger.name = ObjectType.colorChanger.rawValue

      let sprite = SKSpriteNode(imageNamed: "ColorChanger")

      let colorChangerBody = SKPhysicsBody(rectangleOf: sprite.size)
      colorChangerBody.categoryBitMask = PhysicsCategory.ColorChanger
      colorChangerBody.collisionBitMask = 0
      colorChangerBody.contactTestBitMask = PhysicsCategory.Player
      colorChangerBody.affectedByGravity = false
      sprite.physicsBody = colorChangerBody

      colorChanger.addChild(sprite)

      colorChangers.append(colorChanger)
      colorChanger.position = CGPoint(x: size.width/2, y: changerSpacing * CGFloat(colorChangers.count))

      addChild(colorChanger)

      let rotateAction = SKAction.rotate(byAngle: 2.0 * CGFloat.pi, duration: 4.0)
      colorChanger.run(SKAction.repeatForever(rotateAction))

    }

    func addCircleObstacle() {
      let path = UIBezierPath()
      path.move(to: CGPoint(x: 0, y: -200))
      path.addLine(to: CGPoint(x: 0, y: -160))
      path.addArc(withCenter: CGPoint.zero,
                  radius: 160,
                  startAngle: CGFloat(3.0 * .pi/2),
                  endAngle: CGFloat(0),
                  clockwise: true)
      path.addLine(to: CGPoint(x: 200, y: 0))
      path.addArc(withCenter: CGPoint.zero,
                  radius: 200,
                  startAngle: CGFloat(0.0),
                  endAngle: CGFloat(3.0 * .pi/2),
                  clockwise: false)

      let obstacle = obstacleByDuplicatingPath(path, clockwise: true)
      obstacles.append(obstacle)
      obstacle.position = CGPoint(x: size.width/2, y: obstacleSpacing * CGFloat(obstacles.count))
      addChild(obstacle)

      let rotateAction = SKAction.rotate(byAngle: 2.0 * CGFloat.pi, duration: 4.0)
      obstacle.run(SKAction.repeatForever(rotateAction))
    }

    func addSquareObstacle() {
      let path = UIBezierPath(roundedRect: CGRect.init(x: -200, y: -200,
                                                       width: 400, height: 40),
                              cornerRadius: 20)

      let obstacle = obstacleByDuplicatingPath(path, clockwise: false)
      obstacles.append(obstacle)
      obstacle.position = CGPoint(x: size.width/2, y: obstacleSpacing * CGFloat(obstacles.count))

      addChild(obstacle)

      let rotateAction = SKAction.rotate(byAngle: -2.0 * CGFloat.pi, duration: 4.0)
      obstacle.run(SKAction.repeatForever(rotateAction))
    }

    func obstacleByDuplicatingPath(_ path: UIBezierPath, clockwise: Bool) -> SKNode {
      let container = SKNode()

      var rotationFactor = CGFloat.pi/2
      if !clockwise {
        rotationFactor *= -1
      }

      for i in 0...3 {
        let section = SKShapeNode(path: path.cgPath)
        section.fillColor = colors[i]
        section.strokeColor = colors[i]
        section.zRotation = rotationFactor * CGFloat(i);

        let sectionBody = SKPhysicsBody(polygonFrom: path.cgPath)
        sectionBody.categoryBitMask = PhysicsCategory.Obstacle
        sectionBody.collisionBitMask = 0
        sectionBody.contactTestBitMask = PhysicsCategory.Player
        sectionBody.affectedByGravity = false
        section.physicsBody = sectionBody

        container.addChild(section)
      }
      return container
    }

    func dieAndRestart() {
      print("boom")
      player.physicsBody?.velocity.dy = 0
      player.removeFromParent()

      for node in obstacles {
        node.removeFromParent()
      }
      for node in colorChangers {
        node.removeFromParent()
      }
      colorChangers.removeAll()
      obstacles.removeAll()

      setupPlayerAndObstacles()
      cameraNode.position = CGPoint(x: size.width/2, y: size.height/2)
      score = 0
      scoreLabel.text = String(score)

    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
      player.physicsBody?.velocity.dy = 800.0
    }

    override func update(_ currentTime: TimeInterval) {

      if player.position.y > obstacleSpacing * CGFloat(obstacles.count) {
        print("score")
        score += 1
        scoreLabel.text = String(score)

        let highScore = UserDefaults.standard.integer(forKey: "highestScore")
        let theHighestScore = score > highScore ? score : highScore
        highestScore.text = "Highest score: \(theHighestScore)"

        addObstacle()
        addColorChanger()
      }

      let playerPositionInCamera = cameraNode.convert(player.position, from: self)
      if playerPositionInCamera.y > 0 {
        cameraNode.position.y = player.position.y
      }

      if playerPositionInCamera.y < -size.height/2 {
        dieAndRestart()
      }
    }

  }

  extension GameScene: SKPhysicsContactDelegate {

    func didBegin(_ contact: SKPhysicsContact) {

      if let nodeA = contact.bodyA.node as? SKShapeNode, let nodeB = contact.bodyB.node as? SKShapeNode {
        if nodeA.fillColor != nodeB.fillColor {
          dieAndRestart()
        }
      } else {
        contact.bodyA.node?.removeFromParent()
        setPlayerRandomColor()

      }


    }
}
