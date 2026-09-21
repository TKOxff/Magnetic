//
//  Magnetic.swift
//  Magnetic
//
//  Created by Lasha Efremidze on 3/8/17.
//  Copyright © 2017 efremidze. All rights reserved.
//

import SpriteKit

@objc public protocol MagneticDelegate: AnyObject {
    // by user's action
    func magnetic(_ magnetic: Magnetic, didSelect node: Node)
    func magnetic(_ magnetic: Magnetic, didDeselect node: Node)
    @objc optional func magnetic(_ magnetic: Magnetic, didRemove node: Node)
    
    // by logic
    // TK: 선택 애니메이션 종료 후 호출
    func magnetic(_ magnetic: Magnetic, didSelectEnd node: Node)
    // TK: 리셋 이후 콜
    @objc optional func magnetic(_ magnetic: Magnetic, removed node: Node)
}

@objcMembers open class Magnetic: SKScene {
    
    /**
     The field node that accelerates the nodes.
     */
    open lazy var magneticField: SKFieldNode = { [unowned self] in
        let field = SKFieldNode.radialGravityField()
        self.addChild(field)
        return field
    }()
    
    /**
     Controls whether you can select multiple nodes.
     */
    open var allowsMultipleSelection: Bool = true
    
    
    /**
    Controls whether an item can be removed by holding down
     */
    open var removeNodeOnLongPress: Bool = false
    
    // TK: 누르기 애니메이션 처리 삭제
    open var longPressAnimationAndRemove: Bool = false
    var touchedNode: Node?
    var touchingLocation: CGPoint?
  
    /**
     The length of time (in seconds) the node must be held on to trigger a remove event
     */
    open var longPressDuration: TimeInterval = 0.35
    
    open var isDragging: Bool = false
    
    /**
     The selected children.
     */
    open var selectedChildren: [Node] {
        return children.compactMap { $0 as? Node }.filter { $0.isSelected }
    }
    
    /**
     The object that acts as the delegate of the scene.
     
     The delegate must adopt the MagneticDelegate protocol. The delegate is not retained.
     */
    open weak var magneticDelegate: MagneticDelegate?
    
    private var touchStarted: TimeInterval?
    
    override open var size: CGSize {
        didSet {
            configure()
        }
    }
    
    override public init(size: CGSize) {
        super.init(size: size)
        
        commonInit()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        commonInit()
    }
    
    func commonInit() {
        backgroundColor = .white
        scaleMode = .aspectFill
        accessibilityContainerType = .list
        configure()
    }
    
    func configure() {
        let strength = Float(max(size.width, size.height))
        let radius = strength.squareRoot() * 100
        
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        physicsBody = SKPhysicsBody(edgeLoopFrom: { () -> CGRect in
            var frame = self.frame
            frame.size.width = CGFloat(radius)
            frame.origin.x -= frame.size.width / 2
            return frame
        }())
        
        magneticField.region = SKRegion(radius: radius)
        magneticField.minimumRadius = radius
        // moving speed
        magneticField.strength = strength * 2
        magneticField.position = CGPoint(x: size.width / 2, y: size.height / 2)
    }
    
    override open func addChild(_ node: SKNode) {
        var x = -node.frame.width // left
        if children.count % 2 == 0 {
            x = frame.width + node.frame.width // right
        }
        let y = CGFloat.random(node.frame.height, frame.height - node.frame.height)
        node.position = CGPoint(x: x, y: y)
        super.addChild(node)
    }
    
}

extension Magnetic {
    
    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
      
        // TK: 누르고 있기 처리인가
        guard removeNodeOnLongPress || longPressAnimationAndRemove,
                let touch = touches.first else { return }
        touchStarted = touch.timestamp

        // TK: 터치가 시작된 위치에 노드가 있다면 들고 있는다
        let location = touch.location(in: self)
        if let node = node(at: location) {
          touchedNode = node
          touchingLocation = location
//          print("touchesBegan2 touchedNode:\(node.text!)")
          
          DispatchQueue.main.asyncAfter(deadline: .now() + longPressDuration) { [weak self, weak touchedNode] in
            // 커지는 애니메이션 시작전에, 일정 시간지난 후 손가락이 노드에서 벗어난 것 체크
            if let node = touchedNode, let location = self?.touchingLocation {
              if let currentNode = self?.node(at: location) {
                if node == currentNode {
                  node.selectedAnimation()
                }
              }
            }
          }
        }
    }
    
    // 손가락 터치후 아주 미세하게만 움직여도 호출된다..
    override open func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
      
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let previous = touch.previousLocation(in: self)

        // 0은 손가락을 이동하지 않고, 같은 위치에서 미세한 움직임에도 발생한다.
        // 1 이상이 확실히 손가락 위치가 변경되었을때
        let distance = location.distance(from: previous)
        guard distance != 0 else { return }

        // 거리값이 너무 미세하게 반응하기 때문에 실시간으로 판단하기가 어렵다.
        // TK: 실시간으로 위치만 갱신해 두고 사용한다.
        touchingLocation = location
        isDragging = true
        
        moveNodes(location: location, previous: previous)
    }
  
    // TK: 드래깅 상태는 무시하게 하고, 대신 같은 노드인지로 판단.
    func tkTouchedEnded(_ touches: Set<UITouch>) -> Bool {
      guard let touchedNode = self.touchedNode else { return false }
      guard let touch = touches.first else { return false }
      let location = touch.location(in: self)

      guard let node = node(at: location) else { return false }
      if node != touchedNode {
//        print("touchesEnded3 is not touchedNode:\(touchedNode.text!)")
        return  false
      } else {
//        print("touchesEnded3 is touchedNode:\(touchedNode.text!)")
      }
      
      guard let touchStarted = touchStarted else { return false }
      let touchEnded = touch.timestamp
      let timeDiff = touchEnded - touchStarted
//      print("longPress timeDiff:\(timeDiff)")
      
      if (timeDiff >= longPressDuration) {
//          print("touchesEnded3 Remove touchedNode:\(touchedNode.text!)")
          node.removedAnimation {
              self.magneticDelegate?.magnetic?(self, didRemove: node)
          }
        
        return true // it is long pressed!
      }
      return false
    }
  
    override open func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        // TK: 드래깅 상태는 무시하게 하고, 대신 같은 노드인지로 판단.
        defer { touchedNode = nil; touchingLocation = nil }
        if longPressAnimationAndRemove {
          if tkTouchedEnded(touches) {
            return
          }
        }
      
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        defer { isDragging = false }
        guard !isDragging, let node = node(at: location) else { return }
        
        // TK: 기존 처리는 기존 플래그 일때만 동작
        if removeNodeOnLongPress && !longPressAnimationAndRemove && !node.isSelected {
            guard let touchStarted = touchStarted else { return }
            let touchEnded = touch.timestamp
            let timeDiff = touchEnded - touchStarted
            
            if (timeDiff >= longPressDuration) {
                node.removedAnimation {
                    self.magneticDelegate?.magnetic?(self, didRemove: node)
                }
                return
            }
        }
        
        if node.isSelected {
            node.isSelected = false
            magneticDelegate?.magnetic(self, didDeselect: node)
        } else {
            if !allowsMultipleSelection, let selectedNode = selectedChildren.first {
                selectedNode.isSelected = false
                magneticDelegate?.magnetic(self, didDeselect: selectedNode)
            }
            node.isSelected = true
            magneticDelegate?.magnetic(self, didSelect: node)
        }
    }
    
    override open func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        isDragging = false
    }
    
}

extension Magnetic {
    
    open func moveNodes(location: CGPoint, previous: CGPoint) {
        let x = location.x - previous.x
        let y = location.y - previous.y
        
        for node in children {
            let distance = node.position.distance(from: location)
            let acceleration: CGFloat = 3 * pow(distance, 1/2)
            let direction = CGVector(dx: x * acceleration, dy: y * acceleration)
            node.physicsBody?.applyForce(direction)
        }
    }
    
    open func node(at point: CGPoint) -> Node? {
        return nodes(at: point).compactMap { $0 as? Node }.filter { $0.path!.contains(convert(point, to: $0)) }.first
    }
    
    /// Resets the `MagneticView` by making all visible `Node` objects vanish to a point.
    open func reset() {
        let speed = physicsWorld.speed
        physicsWorld.speed = 0
        let actions = removalActions()
        run(.sequence(actions)) { [unowned self] in
            self.physicsWorld.speed = speed
        }
    }
  
    /// TK
    open func removeTargets(targetSet: Set<String>) {
        let speed = physicsWorld.speed
        /// 애니메이션에 들어간 노드들의 시작 위치가 고정되기 때문에, 다른 것들도 안 움직이는 것이 자연스럽다?
        physicsWorld.speed = 0
        let actions = removalActionsTargets(targetSet: targetSet)
        run(.sequence(actions)) { [unowned self] in
            self.physicsWorld.speed = speed
        }
    }
}

/// An extension to handle the reset animation.
extension Magnetic {
    /// Retrieves an array of `Node` objects softed by distance.
    ///
    /// - Returns: `[Node]`
    ///
    func sortedNodes() -> [Node] {
        return children.compactMap { $0 as? Node }.sorted { node, nextNode in
            let distance = node.position.distance(from: magneticField.position)
            let nextDistance = nextNode.position.distance(from: magneticField.position)
            return distance < nextDistance && node.isSelected
        }
    }
    
    /// Retrieves an array of `SKAction`s that are setup for reset animation.
    ///
    /// - Returns: `[SKAction]`
    ///
    func removalActions() -> [SKAction] {
        var actions = [SKAction]()
        for (index, node) in sortedNodes().enumerated() {
            node.physicsBody = nil
            let action = SKAction.run { [unowned self, unowned node] in
                if node.isSelected {
                    let point = CGPoint(x: self.size.width / 2, y: self.size.height + 40)
                    let movingXAction = SKAction.moveTo(x: point.x, duration: 0.2)
                    let movingYAction = SKAction.moveTo(y: point.y, duration: 0.4)
                    let resize = SKAction.scale(to: 0.3, duration: 0.4)
                    let throwAction = SKAction.group([movingXAction, movingYAction, resize])
                    node.run(throwAction) { [unowned node] in
                        node.removeFromParent()
                        // TK: 리셋 이후 콜
                        self.magneticDelegate?.magnetic?(self, removed: node)
                    }
                } else {
                    node.removeFromParent()
                    // TK: 리셋 이후 콜
                    self.magneticDelegate?.magnetic?(self, removed: node)
                }
            }
            actions.append(action)
            let delay = SKAction.wait(forDuration: TimeInterval(index) * 0.002)
            actions.append(delay)
        }
        return actions
    }
  
  /// TK
  func removalActionsTargets(targetSet: Set<String>) -> [SKAction] {
        var actions = [SKAction]()
        var index = 0
        for node in sortedNodes() {
            if !targetSet.contains(node.text!) {
              continue /// 대상이 아닌 것은 스킵
            }
            node.physicsBody = nil
            let action = SKAction.run { [unowned self, unowned node] in
              
                let point = CGPoint(x: self.size.width / 2, y: self.size.height + 40)
                let movingXAction = SKAction.moveTo(x: point.x, duration: 0.2)
                let movingYAction = SKAction.moveTo(y: point.y, duration: 0.4)
                let resize = SKAction.scale(to: 0.3, duration: 0.4)
                /// 화면 중앙상단으로 빨려들어가는 듯한 액션을 조합한다.
                let throwAction = SKAction.group([movingXAction, movingYAction, resize])
                node.run(throwAction) { [unowned node] in
                    node.removeFromParent()
                    // TK: 리셋 이후 콜
                    self.magneticDelegate?.magnetic?(self, removed: node)
                }
            }
            actions.append(action)
            let delay = SKAction.wait(forDuration: TimeInterval(index) * 0.004)
            actions.append(delay)
            index += 1
        }
        return actions
    }
}
