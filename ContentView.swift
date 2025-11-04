import SwiftUI
import Expression

struct ContentView: View {
    @State var int = Run_Code()
    @EnvironmentObject var V: Variable
    @FocusState private var isFocused: Bool
    @State var inter = Interpreter()
    @State var temp = false
    @Environment(\.openWindow) var openWindow
    @State private var gradientOffset: CGFloat = -1.0
    
    var body: some View {
        if V.blocked {
            TextField(V.title, text: $V.response)
                .onSubmit {
                    V.strings[V.variableName] = "\"" + V.response + "\""
                    V.blocked = false
                    V.index += 1
                    V.response = ""
                }
        }
        
        
        
        GeometryReader { geo in
            ZStack {

                VStack {
                    
                    HStack {
                        Button(action: {
                            V.numbers = [:]
                            V.strings = [:]
                            V.loopInfo = []
                            V.code = []
                        }) {
                            Label("Stop", systemImage: "stop.fill")
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color.red.opacity(0.2))
                                    .foregroundColor(.red)
                                    .cornerRadius(15)
                        }
                        .buttonStyle(.plain)
                        
                        Button(action: {
                            V.tOut = []
                            V.numbers = [:]
                            V.strings = [:]
                            V.loopInfo = []
                            V.code = V.text.split(separator: "\n").map(String.init)
                            V.commands = []
                            V.renderCommands = []
                            int.run(v: V)
                            print(V.commands)
                        }) {
                            Label("Play", systemImage: "play.fill")
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color.green.opacity(0.2))
                                    .foregroundColor(.green)
                                    .cornerRadius(15)
                        }
                        
                        Button {
                                    openWindow(id: "graphics")
                                } label: {
                                    Text("Open Graphics Window")
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(
                                            LinearGradient(
                                                colors: [.red, .orange, .yellow, .green, .blue, .purple, .red],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                            .hueRotation(.degrees(gradientOffset * 360))
                                            .animation(.linear(duration: 6).repeatForever(autoreverses: false), value: gradientOffset)
                                            
                                            .opacity(0.3)
                                        )
                                        .cornerRadius(15)
                                        .foregroundColor(.white)
                                }
                                .onAppear {
                                    gradientOffset = 1.0
                                }
                    }
                    .buttonStyle(.plain)
                    
                    HStack {
                        TextEditor(text: $V.text)
                            .focused($isFocused)
                            .monospaced()
                            .font(.system(size: 12))
                            .frame(width: geo.size.width * 0.475, height: geo.size.height * 0.675)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 2)
                                )

                        UI()
                            .frame(width: geo.size.width * 0.475, height: geo.size.height * 0.675)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 2)
                                )
                            .background(content: {
                                TextEditor(text: .constant(""))
                                    .frame(width: geo.size.width * 0.475, height: geo.size.height * 0.675)
                                    .cornerRadius(15)
                            })
                    }
                    let index = "Index: " + String(V.index+1)
                    let line = "\nLine: " + String(V.code.indices.contains(V.index) ? V.code[V.index] : "program not running")
                    let stringVariables = "\nString Variables: " + String(V.strings.prefix(5)
                        .map { "\($0.key): \"\($0.value.filter { $0 != "\"" })\"" }
                        .joined(separator: ", "))
                    let doubleVariables = "\nNumber Variables: " + String(V.numbers.prefix(5)
                        .map { "\($0.key): \(inter.ciW($0.value))" }
                        .joined(separator: ", "))

                    TextEditor(text: .constant(index + line + stringVariables + doubleVariables))
                        .monospaced()
                        .disabled(true)
                        .font(.system(size: 10))
                        .frame(width: geo.size.width * 0.965, height: geo.size.height * 0.165)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.white.opacity(0.2), lineWidth: 2)
                            )
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}

struct UI: View {
    @EnvironmentObject var v: Variable

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading) {
                ForEach(Array(v.tOut.enumerated()), id: \.offset) { _, item in
                    Text("\(item)")
                        .monospaced()
                        .font(.system(size: 12))
                }
                .padding(.horizontal, 5)
            }
        }
        .animation(nil, value: v.tOut.count)
    }
}


#Preview {
    ContentView()
        .environmentObject(Variable())
}
