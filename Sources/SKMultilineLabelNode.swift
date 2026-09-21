//
//  SKMultilineLabelNode.swift
//  Magnetic
//
//  Created by Lasha Efremidze on 5/11/17.
//  Copyright © 2017 efremidze. All rights reserved.
//

import SpriteKit

@objcMembers open class SKMultilineLabelNode: SKNode {
    
    open var text: String? { didSet { update() } }
    // TK:발음 기호, 있다면 선택시만 표시 하도록
    open var phonetic: String? { didSet { update() } }
    open var isSelected: Bool = false { didSet { update() } }
  
    open var fontName: String? { didSet { update() } }
    open var fontSize: CGFloat = 32 { didSet { update() } }
    open var fontColor: UIColor? { didSet { update() } }
    
    open var separator: String? { didSet { update() } }
    
    open var verticalAlignmentMode: SKLabelVerticalAlignmentMode = .baseline { didSet { update() } }
    open var horizontalAlignmentMode: SKLabelHorizontalAlignmentMode = .center { didSet { update() } }
    
    open var lineHeight: CGFloat? { didSet { update() } }
    
    open var width: CGFloat! { didSet { update() } }
    
    func update() {
        self.removeAllChildren()
        
        guard let text = text else { return }
        
        var stack = Stack<String>()
        let words = separator.map { text.components(separatedBy: $0) } ?? text.map { String($0) }
        for (index, word) in words.enumerated() {
            // TK: 길이에 상관없이 구분자가 있으면 무조건 개행
            if index > 0 {
                stack.add(toStack: word)
            } else {
                stack.add(toCurrent: word)
            }
        }

        //TK: 선택되었을 때만 나타나도록, 수치는 계산되어 나오도록 해야겠는데..
        if let kana = phonetic, isSelected {
          let label = SKLabelNode(fontNamed: fontName)
          label.text = kana
          label.fontSize = fontSize * 0.4
          label.fontColor = fontColor
          label.verticalAlignmentMode = verticalAlignmentMode
          label.horizontalAlignmentMode = horizontalAlignmentMode
//          let y = (CGFloat(index) - (CGFloat(2.0) / 2) + 0.5) * -(lineHeight ?? fontSize)
          let y = 25
          label.position = CGPoint(x: 0, y: y)
          self.addChild(label)
        }
      
        let lines = stack.values.map { $0.joined(separator: separator ?? "") }
        for (index, line) in lines.enumerated() {
            let label = SKLabelNode(fontNamed: fontName)
            label.text = line
            label.fontSize = fontSize
            label.fontColor = fontColor
            label.verticalAlignmentMode = verticalAlignmentMode
            label.horizontalAlignmentMode = horizontalAlignmentMode
            let y = (CGFloat(index) - (CGFloat(lines.count) / 2) + 0.5) * -(lineHeight ?? fontSize)
            label.position = CGPoint(x: 0, y: y)
            self.addChild(label)
        }
    }
    
    private func makeSizingLabel() -> SKLabelNode {
        let label = SKLabelNode(fontNamed: fontName)
        label.fontSize = fontSize
        return label
    }
    
}

private struct Stack<U> {
    typealias T = (stack: [[U]], current: [U])
    private var value: T
    var values: [[U]] {
        return value.stack + [value.current]
    }
    init() {
        self.value = (stack: [], current: [])
    }
    mutating func add(toStack element: U) {
        self.value = (stack: value.stack + [value.current], current: [element])
    }
    mutating func add(toCurrent element: U) {
        self.value = (stack: value.stack, current: value.current + [element])
    }
}

private func +=(lhs: inout String?, rhs: String) {
    lhs = (lhs ?? "") + rhs
}
