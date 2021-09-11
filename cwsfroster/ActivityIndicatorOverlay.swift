//
//  ActivityIndicatorOverlay.swift
//  rollcall
//
//  Created by Bobby Ren on 9/10/21.
//  Copyright © 2021 Bobby Ren. All rights reserved.
//

internal final class ActivityIndicatorOverlay: UIView {
    var activityIndicator: UIActivityIndicatorView?

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    init(style: UIActivityIndicatorView.Style = .large, color: UIColor = .red) {
        super.init(frame: .zero)
        commonInit()
    }

    private func commonInit(style: UIActivityIndicatorView.Style = .large, color: UIColor = .red) {
        if activityIndicator == nil {
            let activityIndicator = UIActivityIndicatorView(style: style)
            activityIndicator.hidesWhenStopped = false
            activityIndicator.startAnimating()
            activityIndicator.color = color
            addSubview(activityIndicator)
            self.activityIndicator = activityIndicator

        }
        hide()
    }

    func setup(frame: CGRect) {
        self.frame = frame

        activityIndicator?.center = CGPoint(x: frame.size.width / 2, y: frame.size.height / 2)
        backgroundColor = UIColor(white: 0, alpha: 0.5)
    }

    func show() {
        isHidden = false
    }

    func hide() {
        isHidden = true
    }
}
