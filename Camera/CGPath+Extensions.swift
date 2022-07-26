//
//  CGPath+Extensions.swift
//  Camera
//
//  Created by Antonio Granados Moscoso on 26/7/22.
//

import Foundation
import CoreGraphics

extension CGPath {
    var center: CGPoint {
        class Context {
            var sumX: CGFloat = 0
            var sumY: CGFloat = 0
            var points = 0
        }

        var context = Context()

        apply(info: &context) { (context, element) in
            guard let context = context?.assumingMemoryBound(to: Context.self).pointee else { return }

            switch element.pointee.type {
            case .moveToPoint, .addLineToPoint:
                let point = element.pointee.points[0]
                context.sumX += point.x
                context.sumY += point.y
                context.points += 1
            case .addQuadCurveToPoint:
                let controlPoint = element.pointee.points[0]
                let point = element.pointee.points[1]
                context.sumX += point.x + controlPoint.x
                context.sumY += point.y + controlPoint.y
                context.points += 2
            case .addCurveToPoint:
                let controlPoint1 = element.pointee.points[0]
                let controlPoint2 = element.pointee.points[1]
                let point = element.pointee.points[2]
                context.sumX += point.x + controlPoint1.x + controlPoint2.x
                context.sumY += point.y + controlPoint1.y + controlPoint2.y
                context.points += 3
            case .closeSubpath:
                break
            @unknown default:
                break
            }
        }

        return CGPoint(x: context.sumX / CGFloat(context.points),
                       y: context.sumY / CGFloat(context.points))
    }
}
