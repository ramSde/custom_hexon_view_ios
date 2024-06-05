import UIKit

class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Create and center the WaterView
        let hexagonSize: CGFloat = 200
        let waterView = WaterView(frame: CGRect(x: (view.bounds.width - hexagonSize) / 2, y: (view.bounds.height - hexagonSize) / 2, width: hexagonSize, height: hexagonSize))
        view.addSubview(waterView)
    }
}

class WaterView: UIView {
    // Define the hexagonal path
    var path: UIBezierPath!
    
    // Define the wave animation layer
    var waveLayer: CAShapeLayer!
    
    // Define the wave animation
    var waveDisplayLink: CADisplayLink?
    var waveHeight: CGFloat = 0.0
    var wavePhase: CGFloat = 0.0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .clear
        setupView()
    }
    
    public func roundedPolygonPath(rect: CGRect, lineWidth: CGFloat, sides: Int, cornerRadius: CGFloat, rotationOffset: CGFloat = 0) -> UIBezierPath {
        let path = UIBezierPath()
        let theta: CGFloat = CGFloat(2.0 * .pi) / CGFloat(sides) // How much to turn at every corner
        let offset: CGFloat = cornerRadius * tan(theta / 2.0)     // Offset from which to start rounding corners
        let width = min(rect.size.width, rect.size.height)        // Width of the square

        let center = CGPoint(x: rect.origin.x + width / 2.0, y: rect.origin.y + width / 2.0)

        // Radius of the circle that encircles the polygon
        // Notice that the radius is adjusted for the corners, that way the largest outer
        // dimension of the resulting shape is always exactly the width - linewidth
        let radius = (width - lineWidth + cornerRadius - (cos(theta) * cornerRadius)) / 2.0

        // Start drawing at a point, which by default is at the right hand edge
        // but can be offset
        var angle = CGFloat(rotationOffset)

        let corner = CGPoint(x: center.x + (radius - cornerRadius) * cos(angle), y: center.y + (radius - cornerRadius) * sin(angle))
        path.move(to: CGPoint(x: corner.x + cornerRadius * cos(angle + theta), y: corner.y + cornerRadius * sin(angle + theta)))

        for _ in 0..<sides {
            angle += theta

            let corner = CGPoint(x: center.x + (radius - cornerRadius) * cos(angle), y: center.y + (radius - cornerRadius) * sin(angle))
            let tip = CGPoint(x: center.x + radius * cos(angle), y: center.y + radius * sin(angle))
            let start = CGPoint(x: corner.x + cornerRadius * cos(angle - theta), y: corner.y + cornerRadius * sin(angle - theta))
            let end = CGPoint(x: corner.x + cornerRadius * cos(angle + theta), y: corner.y + cornerRadius * sin(angle + theta))

            path.addLine(to: start)
            path.addQuadCurve(to: end, controlPoint: tip)
        }

        path.close()

        // Move the path to the correct origins
        let bounds = path.bounds
        let transform = CGAffineTransform(translationX: -bounds.origin.x + rect.origin.x + lineWidth / 2.0, y: -bounds.origin.y + rect.origin.y + lineWidth / 2.0)
        path.apply(transform)

        return path
    }
    
    func setupView() {
        // Create the hexagonal path rotated by 90 degrees
        path = roundedPolygonPath(rect: bounds, lineWidth: 2, sides: 6, cornerRadius: 10, rotationOffset: .pi / 2)
        
        // Create the wave animation layer
        waveLayer = CAShapeLayer()
        waveLayer.fillColor = UIColor.blue.withAlphaComponent(0.5).cgColor
        
        // Add the waveLayer
        layer.addSublayer(waveLayer)
        
        // Create a mask for the wave layer to fit inside the hexagon
        let maskLayer = CAShapeLayer()
        maskLayer.path = path.cgPath
        waveLayer.mask = maskLayer
        
        // Setup display link for wave animation
        waveDisplayLink = CADisplayLink(target: self, selector: #selector(updateWave))
        waveDisplayLink?.add(to: .main, forMode: .common)
        
        // Initialize the wave height to fill the hexagon
        waveHeight = bounds.height
    }
    
    @objc func updateWave() {
        wavePhase += 0.1
        if waveHeight > 0 {
            waveHeight -= 0.5 // Decrease the water level over time
        }
        
        let wavePath = UIBezierPath()
        wavePath.move(to: CGPoint(x: 0, y: bounds.height - waveHeight))
        
        for x in stride(from: 0, through: bounds.width, by: 1) {
            let y = sin((CGFloat(x) / bounds.width * 2 * .pi) + wavePhase) * 10 + (bounds.height - waveHeight)
            wavePath.addLine(to: CGPoint(x: CGFloat(x), y: y))
        }
        
        wavePath.addLine(to: CGPoint(x: bounds.width, y: bounds.height))
        wavePath.addLine(to: CGPoint(x: 0, y: bounds.height))
        wavePath.close()
        
        waveLayer.path = wavePath.cgPath
        setNeedsDisplay()
    }
    
    override func draw(_ rect: CGRect) {
        // Ensure the background is clear
        UIColor.clear.setFill()
        UIRectFill(rect)
        
        // Draw the hexagonal border
        UIColor.black.setStroke()
        path.lineWidth = 2
        path.stroke()
        
        // Fill the hexagonal path with a clear color initially
        UIColor.clear.setFill()
        path.fill()
    }
}
