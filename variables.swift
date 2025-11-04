import SwiftUI
import Combine

class Variable: ObservableObject {
    @Published var numbers: [String: Double] = [:]
    @Published var strings: [String: String] = [:]
    @Published var arrays_strings: [String: [String]] = [:]
    @Published var arrays_numbers: [String: [Double]] = [:]
    @Published var tOut: [String] = []
    @Published var text = ""
    @Published var code = [""]
    @Published var index = 1
    @Published var loopInfo: [LoopInfo] = []
    @Published var blocked = false
    @Published var response = ""
    @Published var title = ""
    @Published var variableName = ""
    @Published var paused = false
    @Published var pauselength = 0.0
    @Published var defined_functions: [String: [String]] = [:]
    @Published var commands: [GraphicsCommands] = []
    @Published var renderCommands: [GraphicsCommands] = []
    @Published var graphicsInfo: [String: GraphicsCommands] = [:]
    @Published var objects: [String: GraphicsCommands] = [:]
    @Published var graphicsClicked: [String: Bool] = [:]
    typealias LoopInfo = (cIndex: Int, sIndex: Int, eIndex: Int, index: String, lbl: String)
}
