//
//  VisualEffectBlur.swift
//  safar
//
//  Created by Arman Kassam on 2025-07-10.
//


import SwiftUI
import UIKit

struct VisualEffectBlur: UIViewRepresentable {
    var blurStyle: UIBlurEffect.Style
    var intensity: CGFloat

    func makeUIView(context: Context) -> UIVisualEffectView {
        let blurEffect = UIBlurEffect(style: blurStyle)
        let view = UIVisualEffectView(effect: blurEffect)
        view.alpha = intensity
        return view
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.alpha = intensity
    }
}
