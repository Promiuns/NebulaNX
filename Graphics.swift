import SwiftUI
import Combine

struct Graphics: View {
    @EnvironmentObject var v: Variable
    var body: some View {
        Canvas { context, size in
            for command in v.renderCommands {
                switch command {
                case let .circle(x, y, r, color, hollowOrFilled, rotation):
                    context.translateBy(x: x, y: y)
                    context.rotate(by: .degrees(rotation))
                    context.translateBy(x: -x, y: -y)
                    let rect = CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)
                    let path = Path(ellipseIn: rect)
                    if hollowOrFilled {
                        context.stroke(path, with: .color(color), lineWidth: 2)
                    } else {
                        context.fill(path, with: .color(color))
                    }

                case let .rect(x, y, w, h, color, hollowOrFilled, rotation):
                    context.translateBy(x: x, y: y)
                    context.rotate(by: .degrees(rotation))
                    context.translateBy(x: -x, y: -y)
                    let rect = CGRect(x: x - w/2, y: y - h/2, width: w, height: h)
                    if hollowOrFilled {
                        context.stroke(Path(rect), with: .color(color), lineWidth: 2)
                    } else {
                        context.fill(Path(rect), with: .color(color))
                    }

                case let .line(x1, y1, x2, y2, color):
                    var path = Path()
                    path.move(to: CGPoint(x: x1, y: y1))
                    path.addLine(to: CGPoint(x: x2, y: y2))
                    context.stroke(path, with: .color(color), lineWidth: 2)

                case let .text(x, y, text, color, rotation):
                    context.rotate(by: .degrees(rotation))
                    let resolved = context.resolve(
                        Text(text)
                            .font(.system(size: 20))
                            .foregroundStyle(color)
                    )
                    context.draw(resolved, at: CGPoint(x: x, y: y), anchor: .center)
                }
            }
        }
        .background(Color.clear.contentShape(Rectangle())) // ensures it’s hittable
        .coordinateSpace(name: "canvasSpace")
        .gesture(
            DragGesture(minimumDistance: 0)
                .onEnded { value in
                    // Get the tap position *inside* the Canvas
                    let point = value.location
                    print("Tapped inside canvas at \(point.x), \(point.y)")
                    
                    // Example: check hits
                    for (key, command) in v.graphicsInfo {
                        switch command {
                        case let .rect(x, y, w, h, _, _, _):
                            let rect = CGRect(x: x - w/2, y: y - h/2, width: w, height: h)
                            if rect.contains(point) { v.graphicsClicked[key] = true }

                        case let .circle(x, y, r, _, _, _):
                            let dx = point.x - x
                            let dy = point.y - y
                            if sqrt(dx*dx + dy*dy) <= r { v.graphicsClicked[key] = true }

                        default:
                            break
                        }
                    }
                }
        )
        .coordinateSpace(name: "canvas")
        .background(Color.clear.contentShape(Rectangle()))
        .gesture(
            DragGesture(minimumDistance: 0)
                .onEnded { value in
                    let point = value.location
                    for (key, command) in v.graphicsInfo {
                        switch command {
                        case let .rect(x, y, w, h, _, _, _):
                            let rect = CGRect(x: x - w/2, y: y - h/2, width: w, height: h)
                            if rect.contains(point) { v.graphicsClicked[key] = true }

                        case let .circle(x, y, r, _, _, _):
                            let dx = point.x - x
                            let dy = point.y - y
                            if sqrt(dx*dx + dy*dy) <= r { v.graphicsClicked[key] = true }

                        default: break
                        }
                    }
                }
        )
    }
}

extension Double {
    func degToRad() -> Double {
        return self * .pi / 180
    }
}
