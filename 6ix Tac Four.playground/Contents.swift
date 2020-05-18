/* copyright 2020 Alex Bangu
 all rights reserved */

import UIKit
import PlaygroundSupport
import AVFoundation

let kBoardWidth = 6
let kBoardHeight = kBoardWidth
let kWinningLength = 4

var xTurn = true
var isGameOver = false
var player: AVAudioPlayer?

enum LineDirection {
    case top
    case left
    case bottom
    case right
    case topleft
    case topright
    case bottomleft
    case bottomright
}

func playSound(soundName: String, fileType: String) {
    let url = Bundle.main.url(forResource: soundName, withExtension: fileType)!
    
    do {
        player = try AVAudioPlayer(contentsOf: url)
        guard let player = player else { return }
        
        player.prepareToPlay()
        player.play()
    } catch let error {
        print(error.localizedDescription)
    }
}

class GameController: UIView {
    var board = Array(repeating: Array(repeating: Tile(), count: kBoardWidth), count: kBoardHeight)
    var isAIEnabled = false
    var aiSwitch: UISwitch?
    var aiLabel: UILabel?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
    
    convenience init() {
        let viewFrame = CGRect(x: 0, y: 0, width: 500, height: 550)
        self.init(frame: viewFrame)
        
        self.aiSwitch = UISwitch(frame: CGRect(x: 225, y: 509, width: 50, height: 50))
        self.aiSwitch!.addTarget(self, action: #selector(GameController.aiSwitchToggled(_:)), for: UIControl.Event.valueChanged)
        
        self.aiLabel = UILabel(frame: CGRect(x:200, y:514, width: 50, height: 22))
        self.aiLabel!.text = "AI"
        
        self.backgroundColor = .white
        resetBoard(initial: true)
        
        self.addSubview(self.aiSwitch!)
        self.addSubview(self.aiLabel!)
    }

    @objc func resetBoard(initial: Bool) {
        if !initial {
            playSound(soundName: "Page Flip", fileType: "wav")
        }
        
        for view in self.subviews {
            if view == self.aiSwitch || view == self.aiLabel{
                continue
            }
            
            UIView.transition(with: self, duration: 0.3, options: [.transitionCurlUp, .curveEaseOut], animations: {
                view.removeFromSuperview()
            }, completion: nil )
        }
        
        for row in 0..<kBoardWidth {
            for col in 0..<kBoardHeight {
                board[row][col] = Tile(boardWidth: self.frame.width, row: row, col: col)
                self.addSubview(board[row][col])
            }
        }
        
        xTurn = true
        isGameOver = false
    }
    
    @objc public func aiSwitchToggled(_ sender: UISwitch) {
        self.isAIEnabled = sender.isOn
        
        if self.isAIEnabled && !xTurn && !isGameOver {
            self.runAI()
        }
    }
    
    func runAI() {
        var row = Int.random(in: 0..<kBoardWidth)
        var col = Int.random(in: 0..<kBoardHeight)
        
        while board[row][col].getSelection() != "empty" {
            row = Int.random(in: 0..<kBoardWidth)
            col = Int.random(in: 0..<kBoardHeight)
        }
        
        board[row][col].setSelection(change: (xTurn ? "x" : "o"))
        checkForWin(row: row, col: col)
        
        xTurn = !xTurn
    }
    
    func getWinningSpots(row: Int, col: Int, direction: LineDirection) -> [[Int]] {
        print("getWinningSpots(\(row), \(col), \(direction)")
        
        guard row >= 0 && row < kBoardWidth && col >= 0 && col < kBoardHeight else {
            print("row/col is not within board")
            return []
        }
        
        guard board[row][col].getSelection() == (xTurn ? "x" : "o") else {
            print("row/col (\(board[row][col].getSelection())) is not the current user's selection: \(xTurn ? "x" : "o")")
            return []
        }
        
        print("Checking direction \(direction)")
        
        /* algorithm that checks for winning scenario*/
        var newCol = col
        var newRow = row
        
        if [LineDirection.top, LineDirection.topleft, LineDirection.topright].contains(direction) {
            newCol -= 1
        }
        if [LineDirection.bottom, LineDirection.bottomright, LineDirection.bottomleft].contains(direction) {
            newCol += 1
        }
        if [LineDirection.left, LineDirection.topleft, LineDirection.bottomleft].contains(direction) {
            newRow -= 1
        }
        if [LineDirection.right, LineDirection.bottomright, LineDirection.topright].contains(direction)  {
            newRow += 1
        }
        
        var result = [[Int]]()
        result = self.getWinningSpots(row: newRow, col: newCol, direction: direction)
        result += [[row, col]]
        
        print("Returning result: \(result)")
        return result
    }
    
    func checkForWin(row: Int, col: Int) {
        print("Pressed square: \(row), \(col)")
        
        var winningSpots = [[Int]]()
        var fullCount = 0
        
        var verticalSpots = getWinningSpots(row: row, col: col, direction: .top)
        verticalSpots += getWinningSpots(row: row, col: col+1, direction: .bottom)
        if verticalSpots.count >= kWinningLength {
            winningSpots += verticalSpots
            print("We won vertically: \(winningSpots)")
        } else {
            print("We did not win vertically: \(verticalSpots)")
        }
            
        var horizontalSpots = getWinningSpots(row: row, col: col, direction: .left)
        horizontalSpots += getWinningSpots(row: row+1, col: col, direction: .right)
        if horizontalSpots.count >= kWinningLength {
            winningSpots += horizontalSpots
            print("We won horizontally: \(winningSpots)")
        } else {
            print("We did not win horizontally: \(horizontalSpots)")
        }
            
        var topLeftSpots = getWinningSpots(row: row, col: col, direction: .topleft)
        topLeftSpots += getWinningSpots(row: row+1, col: col+1, direction: .bottomright)
        if topLeftSpots.count >= kWinningLength {
            winningSpots += topLeftSpots
            print("We won top left diagnally: \(winningSpots)")
        } else {
            print("We did not win top left diagnally: \(topLeftSpots)")
        }
            
        var topRightSpots = getWinningSpots(row: row, col: col, direction: .topright)
        topRightSpots += getWinningSpots(row: row-1, col: col+1, direction: .bottomleft)
        if topRightSpots.count >= kWinningLength {
            winningSpots += topRightSpots
            print("We won top right diagnally: \(winningSpots)")
        } else {
            print("We did not win top right diagnally: \(topRightSpots)")
        }
            
        // Check to see if there's a draw
        if winningSpots.count == 0 {
            for tiles in board {
                for tile in tiles {
                    if tile.getSelection() == "x" || tile.getSelection() == "o" {
                        fullCount += 1
                    }
                }
            }
        }
        
        for spot in winningSpots {
            board[spot[0]][spot[1]].setWin(x: !xTurn)
        }
        
        if !winningSpots.isEmpty || fullCount == (kBoardWidth * kBoardHeight) {
            isGameOver = true
            
            Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(resetBoard), userInfo: nil, repeats: false)
            
            for tiles in board {
                for tile in tiles {
                    tile.isUserInteractionEnabled = false
                }
            }
            
            if fullCount == (kBoardWidth * kBoardHeight) {
                playSound(soundName: "Snap", fileType: "wav")
            } else {
                playSound(soundName: "Ding", fileType: "wav")
            }
        }
    }
}

class Tile: UIView {
    var selection = "empty"
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    convenience init(boardWidth: CGFloat, row: Int, col: Int) {
        let width = boardWidth / CGFloat(kBoardWidth)
        let x = CGFloat(row) * width
        let y = CGFloat(col) * width
        let frame = CGRect(x: x, y: y, width: width, height: width)
        self.init(frame: frame)
        setupTile(row: row, col: col)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(Tile.didTap(_:)))
        self.addGestureRecognizer(tap)
    }
    
    func setupTile(row: Int, col: Int) {
        if row % 2 == col % 2 {
            self.backgroundColor = #colorLiteral(red: 1, green: 0.6666666667, blue: 0.6470588235, alpha: 1)
        }
        else {
            self.backgroundColor = #colorLiteral(red: 0, green: 1, blue: 0.3095569349, alpha: 1)
        }
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    func setSelection(change: String) {
        if selection == "empty" {
            let selectionFrame = CGRect(x: self.frame.width / 4, y: self.frame.width / 4, width: self.frame.width / 2, height: self.frame.height / 2)
            
            let selectionView = UIView(frame: selectionFrame)
            
            if change == "x" {
                selection = "x"
                selectionView.backgroundColor = #colorLiteral(red: 0.9254902005, green: 0.2352941185, blue: 0.1019607857, alpha: 1)
                selectionView.layer.cornerRadius = selectionFrame.width / 6
                playSound(soundName: "Pop", fileType: "wav")
            }
            else {
                selection = "o"
                selectionView.backgroundColor = #colorLiteral(red: 0.2196078449, green: 0.007843137719, blue: 0.8549019694, alpha: 1)
                selectionView.layer.cornerRadius = selectionFrame.width / 2
                playSound(soundName: "Pop 2", fileType: "wav")
            }
            
            UIView.transition(with: self, duration: 0.30, options: [.transitionFlipFromTop, .curveEaseOut], animations: {
                self.addSubview(selectionView)
            }, completion: nil )
            
        }
        else {
            print("Slot is taken!")
        }
    }
    
    func setWin(x: Bool) {
        let selectionFrame = CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height)

        let winFrame = UIView(frame: selectionFrame)

        if (x) {
            winFrame.backgroundColor = #colorLiteral(red: 0.9098039269, green: 0.4784313738, blue: 0.6431372762, alpha: 0.7391909247)
        } else {
            winFrame.backgroundColor = #colorLiteral(red: 0.9764705896, green: 0.850980401, blue: 0.5490196347, alpha: 0.6474743151)
        }

        UIView.transition(with: self, duration: 0.30, options: [.transitionFlipFromTop, .curveEaseOut], animations: {
            self.addSubview(winFrame)
        }, completion: nil)
    }
    
    func getSelection() -> String {
        return selection
    }
    
    @objc func didTap(_ sender: UITapGestureRecognizer) {
        let controller = PlaygroundPage.current.liveView as! GameController
        
        let row = Int(sender.location(in: controller).x / self.frame.width)
        let col = Int(sender.location(in: controller).y / self.frame.width)
        
        let changeTurn = (selection == "empty")
        
        if xTurn {
            setSelection(change: "x")
        } else {
            setSelection(change: "o")
        }
        
        controller.checkForWin(row: row, col: col)
        
        if changeTurn && !isGameOver {
            xTurn = !xTurn
        }
        
        if controller.isAIEnabled && !xTurn{
            controller.runAI()
        }
    }
}

PlaygroundPage.current.liveView = GameController()
