// Copyright (c) 2020-present, Rover Labs, Inc. All rights reserved.
// You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
// copy, modify, and distribute this software in source code or binary form for use
// in connection with the web services and APIs provided by Rover.
//
// This copyright notice shall be included in all copies or substantial portions of 
// the software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

import SwiftUI
import JudoModel

@available(iOS 13.0, *)
struct CarouselView: View {
    @Environment(\.collectionIndex) private var collectionIndex
    @Environment(\.data) private var data
    @Environment(\.urlParameters) private var urlParameters
    @Environment(\.userInfo) private var userInfo
    
    let carousel: Carousel

    @EnvironmentObject private var carouselState: CarouselState

    var body: some View {
        PageViewController(
            pages: pages,
            loop: carousel.isLoopEnabled,
            currentPage: currentPage
        )
    }
    
    private var currentPage: Binding<Int> {
        let viewID = ViewID(nodeID: carousel.id, collectionIndex: collectionIndex)
        return Binding {
            carouselState.currentPageForCarousel[viewID] ?? 0
        } set: { newValue in
            carouselState.currentPageForCarousel[viewID] = newValue
        }
    }
    
    private var pages: [Page] {
        let result = carousel.children.flatMap { node -> [Page] in
            switch node {
            case let collection as Collection:
                let items = collection.items(
                    data: data,
                    urlParameters: urlParameters,
                    userInfo: userInfo
                )
                
                return items.flatMap { item in
                    collection.children.compactMap { child in
                        guard let layer = child as? Layer else {
                            return nil
                        }
                        
                        return Page(layer: layer, item: item)
                    }
                }
            case let layer as Layer:
                return [Page(layer: layer)]
            default:
                return []
            }
        }
        
        return result
    }
}

@available(iOS 13.0, *)
private struct Page: View {
    var layer: Layer
    var item: Any?
    
    var body: some View {
        if let item = item {
            LayerView(layer: layer).environment(\.data, item)
        } else {
            LayerView(layer: layer)
        }
    }
}

@available(iOS 13.0, *)
private struct PageViewController: UIViewControllerRepresentable {
    private let pages: [Page]
    private let loop: Bool
    @Binding private var currentPage: Int

    init(pages: [Page], loop: Bool, currentPage: Binding<Int>) {
        self.pages = pages
        self.loop = loop
        self._currentPage = currentPage
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self, loop: loop)
    }

    func makeUIViewController(context: Context) -> UIPageViewController {
        let pageViewController = UIPageViewController(
            transitionStyle: .scroll,
            navigationOrientation: .horizontal)
        pageViewController.dataSource = context.coordinator
        pageViewController.delegate = context.coordinator

        return pageViewController
    }

    func updateUIViewController(_ pageViewController: UIPageViewController, context: Context) {
        context.coordinator.parent = self
        context.coordinator.loop = self.loop
        
        if !context.coordinator.controllers.isEmpty {
            guard context.coordinator.controllers.indices.contains(currentPage) else {
                assertionFailure("Invalid carousel state")
                return
            }

            pageViewController.setViewControllers(
                [context.coordinator.controllers[currentPage]],
                direction: .forward,
                animated: true
            )
        }
    }

    class Coordinator: NSObject, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
        var parent: PageViewController
        var controllers: [UIViewController]
        var loop: Bool

        init(_ pageViewController: PageViewController, loop: Bool) {
            parent = pageViewController
            self.loop = loop
            controllers = parent.pages.map {
                let controller = UIHostingController(rootView: $0)
                controller.view.backgroundColor = .clear
                return controller
            }
        }

        func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
            guard let index = controllers.firstIndex(of: viewController) else {
                return nil
            }

            if index > 0 {
                return controllers[index - 1]
            } else if loop {
                return controllers.last
            } else {
                return nil
            }
        }

        func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
            guard let index = controllers.firstIndex(of: viewController) else {
                return nil
            }

            if index + 1 < controllers.count {
                return controllers[index + 1]
            } else if loop {
                return controllers.first
            } else {
                return nil
            }
        }

        func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
            if completed,
               let visibleViewController = pageViewController.viewControllers?.first,
               let index = controllers.firstIndex(of: visibleViewController)
            {
                parent.currentPage = index
            }
        }
    }
}
