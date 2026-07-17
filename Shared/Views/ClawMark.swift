import SwiftUI

/// A tiny three-stroke "claw" mark for the menu bar glyph. An original
/// shape (not Anthropic's logo) chosen so the icon reads clearly at menu
/// bar size and doesn't get mistaken for the macOS battery indicator the
/// way a bare percentage does.
struct ClawMark: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let count = 3
        let spacing = rect.width / CGFloat(count + 1)
        for i in 1...count {
            let x = spacing * CGFloat(i)
            let start = CGPoint(x: x - rect.width * 0.09, y: rect.height * 0.08)
            let end = CGPoint(x: x + rect.width * 0.09, y: rect.height * 0.92)
            let control = CGPoint(x: x + rect.width * 0.03, y: rect.height * 0.5)
            path.move(to: start)
            path.addQuadCurve(to: end, control: control)
        }
        return path
    }
}

extension ClawMark {
    static func glyph(size: CGFloat = 13, lineWidth: CGFloat = 1.6) -> some View {
        ClawMark()
            .stroke(Color.primary, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            .frame(width: size, height: size)
    }
}

#Preview {
    ClawMark.glyph(size: 40, lineWidth: 4)
        .padding()
}
