//
//  Copyright 2024 Readium Foundation. All rights reserved.
//  Use of this source code is governed by the BSD-style license
//  available in the top-level LICENSE file of the project.
//

import Foundation
import WebKit
import UIKit

/// A custom web view which:
///  - Forwards copy: menu action to an EditingActionsController.
final class WebView: WKWebView {
    private let editingActions: EditingActionsController

    init() {
        let config = WKWebViewConfiguration()
        super.init(frame: .zero, configuration: config)
    }


    override func buildMenu(with builder: any UIMenuBuilder) {
        // No super call to prevent default menu items
    }

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return false // Disable all actions
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func clearSelection() {
        evaluateJavaScript("window.getSelection().removeAllRanges()")
        // Toggle user interaction to remove selection overlays (for iOS < 12)
        isUserInteractionEnabled = false
        isUserInteractionEnabled = true
    }

    override func buildMenu(with builder: any UIMenuBuilder) {
        if #available(iOS 13.0, *) {
            editingActions.buildMenu(with: builder)
            // Do not call super to exclude default menu items like “Copy Link with Highlight”
        }
    }

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return super.canPerformAction(action, withSender: sender) && editingActions.canPerformAction(action)
    }

    override func copy(_ sender: Any?) {
        editingActions.copy()
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        setupDragAndDrop()
    }

    private func setupDragAndDrop() {
        guard !editingActions.canCopy else { return }

        // Locate the content view containing drag interactions
        if let webScrollView = subviews.first(where: { $0 is UIScrollView }),
           let contentView = webScrollView.subviews.first(where: { $0.interactions.count > 1 }),
           let dragInteraction = contentView.interactions.first(where: { $0 is UIDragInteraction }) {
            contentView.removeInteraction(dragInteraction)
        }
    }
}
