> **이 저장소는 [efremidze/Magnetic](https://github.com/efremidze/Magnetic)의 포크입니다.**
>
> `marumaru` 브랜치는 upstream **3.3.3** 위에 [KanjiMaru(MaruMaru)](https://github.com/TKOxff/MaruMaru)
> 앱이 의존하는 수정분 221줄(3파일)을 올린 것입니다. 원본 패치와 근거는 앱 저장소의
> `.ai-workflow/docs/patches/`에 있습니다.
>
> | 구분 | 추가된 심볼 |
> | --- | --- |
> | 프로토콜 | `magnetic(_:didSelectEnd:)` (필수), `magnetic(_:removed:)` (`@objc optional`) |
> | 동작 플래그 | `longPressAnimationAndRemove`, `longPressDuration` |
> | 터치 판정 교체 | `touchedNode` / `touchingLocation` + `tkTouchedEnded()` — 드래그 무시, 동일 노드 판정 |
> | 기능 | `Magnetic.removeTargets(targetSet:)` |
> | 기능 | `Node.removeFromParentEx(exAction:)`, `Node.parentMagnetic` |
> | 기능 | `SKMultilineLabelNode.phonetic` (후리가나), `isSelected` |
>
> `touchesBegan` / `touchesEnded`는 upstream 동작을 **교체**합니다. upstream이 터치 처리를 바꾸면
> 수동 병합이 필요합니다. 해당 영역은 2022년 이후 변경되지 않았습니다.
>
> 태그는 `<upstream 버전>-marumaru.<패치 리비전>` 형식입니다 (예: `3.3.3-marumaru.1`).

---

# Magnetic

[![CI](https://github.com/efremidze/Magnetic/actions/workflows/ci.yml/badge.svg)](https://github.com/efremidze/Magnetic/actions/workflows/ci.yml)
[![CocoaPods](https://img.shields.io/cocoapods/v/Magnetic.svg)](https://cocoapods.org/pods/Magnetic)
[![Carthage](https://img.shields.io/badge/Carthage-compatible-brightgreen.svg)](https://github.com/Carthage/Carthage)
[![SPM](https://img.shields.io/badge/SPM-compatible-brightgreen.svg)](https://swift.org/package-manager/)
[![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org)
[![License](https://img.shields.io/github/license/efremidze/Magnetic.svg)](https://github.com/efremidze/Magnetic/blob/master/LICENSE)

**Magnetic** is a customizable bubble picker like the Apple Music genre selection.

<img src="/Images/demo2.gif" width="250" />

```
$ pod try Magnetic
```

## Features

- [x] Adding/Removing Nodes
- [x] Selection/Deselection/Removed Animations
- [x] Multiple Selection
- [x] Images
- [x] Multiline Label
- [x] [Documentation](https://efremidze.github.io/Magnetic)

## Requirements

- iOS 13.0+ (Magnetic 3.3.x), iOS 9.0+ (Magnetic 3.2.1)
- Swift 5 (Magnetic 3.x), Swift 4 (Magnetic 2.x), Swift 3 (Magnetic 1.x)

## Usage

A `Magnetic` object is an [SKScene](https://developer.apple.com/reference/spritekit/skscene).

To display, you present it from an [SKView](https://developer.apple.com/reference/spritekit/skview) object.

```swift
import Magnetic

class ViewController: UIViewController {

    var magnetic: Magnetic?
    
    override func loadView() {
        super.loadView()
        
        let magneticView = MagneticView(frame: self.view.bounds)
        magnetic = magneticView.magnetic
        self.view.addSubview(magneticView)
    }

}
```

#### Properties

```swift
var magneticDelegate: MagneticDelegate? // magnetic delegate
var allowsMultipleSelection: Bool // controls whether you can select multiple nodes. defaults to true
var selectedChildren: [Node] // returns selected chidren
```

### Nodes

A `Node` object is a SKShapeNode subclass.

#### Interaction

```swift
// add circular node
let node = Node(text: "Italy", image: UIImage(named: "italy"), color: .red, radius: 30)
magnetic.addChild(node)

// add custom node
let node = Node(text: "France", image: UIImage(named: "france"), color: .blue, path: path, marginScale: 1.1)
magnetic.addChild(node)

// remove node
node.removeFromParent()
```

#### Properties

```swift
var text: String? // node text
var image: UIImage? // node image
var color: UIColor // node color
```

#### Animations

```swift
override func selectedAnimation() {
    // override selected animation
}

override func deselectedAnimation() {
    // override deselected animation
}

override func removedAnimation(completion: @escaping () -> Void) {
    // override removed animation
}
```

### Delegation

The `MagneticDelegate` protocol provides a number of functions for observing the current state of nodes.

```swift
func magnetic(_ magnetic: Magnetic, didSelect node: Node) {
    // handle node selection
}

func magnetic(_ magnetic: Magnetic, didDeselect node: Node) {
    // handle node deselection
}
```

### Customization

Subclass the Node for customization.

For example, a node with an image by default:

```swift
class ImageNode: Node {
    override var image: UIImage? {
        didSet {
            texture = image.map { SKTexture(image: $0) }
        }
    }
    override func selectedAnimation() {}
    override func deselectedAnimation() {}
}
```

## Installation

### CocoaPods
To install with [CocoaPods](http://cocoapods.org/), simply add this in your `Podfile`:
```ruby
use_frameworks!
pod "Magnetic"
```

### Carthage
To install with [Carthage](https://github.com/Carthage/Carthage), simply add this in your `Cartfile`:
```ruby
github "efremidze/Magnetic"
```

## Mentions

- [Natasha The Robot's Newsleter 126](https://swiftnews.curated.co/issues/126#start)

## Communication

- If you **found a bug**, open an issue.
- If you **have a feature request**, open an issue.
- If you **want to contribute**, submit a pull request.

## Credits

https://github.com/igalata/Bubble-Picker

## License

Magnetic is available under the MIT license. See the LICENSE file for more info.
