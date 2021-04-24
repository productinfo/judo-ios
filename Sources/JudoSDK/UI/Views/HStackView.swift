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
struct HStackView: View {
    var stack: JudoModel.HStack
    var useLazy: Bool = false
    
    var body: some View {
        if useLazy  {
            if #available(iOS 14.0, *) {
                SwiftUI.LazyHStack(alignment: stack.alignment, spacing: stack.spacing) {
                    ForEach(orderedLayers) {
                        LayerView(layer: $0)
                    }
                }
            } else {
                SwiftUI.HStack(alignment: stack.alignment, spacing: stack.spacing) {
                    ForEach(orderedLayers) {
                        LayerView(layer: $0)
                    }
                }.frame(maxHeight: .infinity, alignment: .center)
            }
        } else {
            SwiftUI.HStack(alignment: stack.alignment, spacing: stack.spacing) {
                ForEach(orderedLayers) {
                    LayerView(layer: $0)
                }
            }
        }
    }
    
    private var orderedLayers: [Layer] {
        stack.children.compactMap { $0 as? Layer }
    }
}