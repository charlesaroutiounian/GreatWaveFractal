import SwiftUI
import PlaygroundSupport

// MARK: - Great Wave Fractal Model
// 神奈川沖浪裏 La Grande Vague de Kanagawa

/* An arc segment is a portion of a circle's circumference.
    Any point on it at angle θ is defined by the polar equation:
    
    P(θ) = (cx + r·cos(θ), cy + r·sin(θ))
 
    cx and cy are the center coordinates of the circle:
    cx = x-coordinate of the center
    cy = y-coordinate of the center
 
    r = radius
    θ = angle (0 to 2π)*/

struct ArcSegment {
    let center: CGPoint   // center of the full circle this arc belongs to
    let radius: CGFloat   // r — distance from center to arc
    let startAngle: CGFloat  // θ_s in radians
    let endAngle: CGFloat    // θ_e in radians; arc length = r · |endAngle − startAngle|
    let depth: Int           // recursion depth, used for line-width scaling
}

func buildFractal(from arc: ArcSegment, maxDepth: Int) -> [ArcSegment] {
    
    var result = [arc]

    guard arc.depth < maxDepth else { return result }

    // span is the signed angular width of this arc (positive = counterclockwise)
    let span = arc.endAngle - arc.startAngle

    // Spawn children at the start, 1/3, 2/3, and end of the parent arc.
    // f=0 is the very beginning of the arc; f=1 is the very end.
    let fractions: [CGFloat] = [0, 1/3, 2/3, 3/3]

    for fraction in fractions {
        // θ_f: the angle on the parent circle at fraction f along the arc
        let angle = arc.startAngle + span * fraction

        // Spawn point: the (x,y) coordinate on the parent arc at angle θ_f
        // This is the parametric circle equation: P = center + r·(cos θ, sin θ)
        let px = arc.center.x + arc.radius * cos(angle)
        let py = arc.center.y + arc.radius * sin(angle)

        // Child radius is 1/3 of parent. Since arc length = r·|span| and span is
        // inherited unchanged, the child's arc length is also 1/3 of the parent's.
        let childRadius = arc.radius / 3

        // Rotate the child's start direction by δ = π/180 (1°) from the radial direction.
        // The radial direction at the spawn point is simply the angle θ_f itself
        // (it points outward from the parent center toward the spawn point).
        let radialAngle = angle
        let δ: CGFloat = .pi / 180
        let childStart = radialAngle + δ
        let childEnd   = childStart + span  // same span → same shape, just smaller

              
        // Back-calculate the child's center so its arc begins exactly at (px, py).
        // From:  px = child_cx + r_child · cos(childStart)
        // →      child_cx = px − r_child · cos(childStart)
        let cx = px - childRadius * cos(childStart)
        let cy = py - childRadius * sin(childStart)

        let child = ArcSegment(
            center: CGPoint(x: cx, y: cy),
            radius: childRadius,
            startAngle: childStart,
            endAngle: childEnd,
            depth: arc.depth + 1
        )
        result += buildFractal(from: child, maxDepth: maxDepth)
    }

    return result
}

// MARK: - SwiftUI View

struct FractalView: View {
    
    let maxDepth: Int

    var arcs: [ArcSegment] {
        // Root arc: 9 o'clock (π) → 12 o'clock (3π/2) in SwiftUI's y-down coordinate system.
        // SwiftUI's y-axis points down, so angles increase clockwise visually,
        // but addArc(clockwise: false) still sweeps counterclockwise mathematically.
        let root = ArcSegment(
            center: CGPoint(x: 500, y: 500),
            radius: 350,
            startAngle: .pi,        // 9 o'clock (π)
            endAngle: 3 * .pi / 2,  // 12 o'clock (3π/2)
            depth: 0
        )
        return buildFractal(from: root, maxDepth: maxDepth)
    }

    var body: some View {
        Canvas { ctx, size in
            for arc in arcs {
                // Thinner lines at deeper depths so detail stays visible
                let lineWidth: CGFloat = max(0.4, 2.0 - CGFloat(arc.depth) * 0.35)

                var path = Path()
                path.addArc(
                    center: arc.center,
                    radius: arc.radius,
                    startAngle: .radians(arc.startAngle),
                    endAngle: .radians(arc.endAngle),
                    clockwise: false
                )
                ctx.stroke(path, with: .color(.black), lineWidth: lineWidth)
            }
        }
        .frame(width: 900, height: 900)
        .background(Color.white)
    }
}

struct ContentView: View {
    @State private var depth = 4

    var body: some View {
        VStack(spacing: 5) {

            FractalView(maxDepth: depth)

            HStack {
                // At depth 4 there are (3^6−1)/3 = 242 arcs total
                Slider(value: Binding(
                    get: { Double(depth) },
                    set: { depth = Int($0) }
                ), in: 0...5, step: 1)
                .frame(width: 1000)
            }
        }
        .padding()
        .background(Color.white)
    }
}

PlaygroundPage.current.setLiveView(ContentView())
