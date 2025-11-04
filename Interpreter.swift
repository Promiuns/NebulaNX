import SwiftUI
import Expression

enum NXError: Error {
    case template(String)
}

enum GraphicsCommands {
    case circle(x: Double, y: Double, radius: Double, color: Color, hollowOrFilled: Bool, rotation: Double)
    case rect(x: Double, y: Double, width: Double, height: Double, color: Color, hollowOrFilled: Bool, rotation: Double)
    case line(x1: Double, y1: Double, x2: Double, y2: Double, color: Color)
    case text(x: Double, y: Double, text: String, color: Color, rotation: Double)
}

struct Interpreter {
    func f(_ input: String, v: Variable) {
        // func stuff
        let t = t(input)
        guard t.count == 2 else { return }
        
        let start = v.index + 1
        let end = (v.code.firstIndex(of: "END<F>") ?? 0) - 1
        guard end != -1 else { return }
        
        let array = v.code[start...end]
        v.defined_functions[t[1]] = Array(array)
        v.index = end + 1
        print(v.defined_functions)
    }
    
    func w(_ input: String, v: Variable) throws {
        // sleep double
        let t = t(input)
        guard t.count == 2 else { throw NXError.template("Unknown parameters in PD function 'sleep'") }
        guard t[1].sEval(v: v) != nil else { throw NXError.template("Non-numerical value in a numerical parameter") }
        
        v.paused = true
        v.pauselength = t[1].sEval(v: v)!
    }
    
    func inp(_ input: String, v: Variable) {
        // input("stff") -> a
        let t = t(input)
        guard t.count == 4 else { return }
        guard t[1].sEval(v: v) != nil else { return }
        
        v.blocked = true
        v.title = t[1]
        v.variableName = t[3]
    }
    
    func c(_ input: String, v: Variable) {
        // cast var1 as type -> b
        let t = t(input)
        guard t.count == 4 || t.count == 6 else { return }
        
        let type = t[3]
        let varN1 = t[1]
        let varN2 = t[5]
        let varS: Any = (v.strings[varN1] != nil ? v.strings[varN1] ?? "" : v.numbers[varN1] ?? 0.0)
        
        v.numbers.removeValue(forKey: varN1)
        v.strings.removeValue(forKey: varN1)
        
        if type == "string" {
            v.strings[varN2] = (String(describing: varS).contains("\"")) ? String(describing: varS) : "\"" + String(describing: varS) + "\""
        } else if type == "number" {
            let s = String(describing: varS)
            guard Double(s.filter {$0 != "\""}) != nil else { return }
            v.numbers[varN2] = Double(s.filter {$0 != "\""})
        }
        
        
    }
    
    func p(_ input: String, v: Variable) throws -> String {
        let array = t(input)
        guard array.count >= 2 else { throw NXError.template("PD function 'print(any)' is missing a value.") }
        if array[1] == "join" {
            var joined = ""
            guard array.count > 2 else { throw NXError.template("PD method of 'print(any)' i.e. 'join(any)' is missing neccesary arguments") }
            
            for i in 2 ..< array.count {
                
                switch array[i] {
                case let x where x.first == "\"" && x.last == "\"":
                    var a = array[i]
                    a = a.filter { $0 != "\"" }
                    
                    joined += a
                case let x where v.numbers[x] != nil:
                    joined += String(describing: ciW(v.numbers[array[i]]!))
                case let x where v.strings[x] != nil:
                    var a = v.strings[array[i]]
                    a = a?.filter { $0 != "\"" }
                    joined += a ?? ""
                default:
                    throw NXError.template("Unknown argument \(array[i])")
                }
            }
            
            joined = "\"" + joined + "\""
            return joined.filter { $0 != "\"" }
        } else if v.numbers[array[1]] != nil {
            return String(describing: ciW(v.numbers[array[1]]!)).filter { $0 != "\"" }
        } else if v.strings[array[1]] != nil {
            return v.strings[array[1]]?.filter { $0 != "\"" } ?? ""
        } else if array[1].sEval(v: v) != nil {
            return String(array[1].sEval(v: v)!)
        } else {
            return array[1].filter { $0 != "\"" }
        }
    }
    
    func v(_ input: String, v: Variable) throws {
        let t = t(input)
        guard t.count >= 3 else { throw NXError.template("PD method 'var' expected name and value") }
        
        let p = switch t[1] {
        case let x where x == "=":
            0
        case let x where x != "=":
            1
        default:
            2
        }
        
        guard p != 2 else { throw NXError.template("Unknown usage of value definition") }
        
        let v_name = t[p]
        
        let v_val = t[p+2]
        
        if v_val == "join" {
            let start = p+2
            let array = Array(t[start...])
            var joined = ""
            for i in 1 ..< array.count {
                print(array[i])
                
                switch array[i] {
                case let x where x.first == "\"" && x.last == "\"":
                    var a = array[i]
                    a = a.filter { $0 != "\"" }
                    
                    joined += a
                case let x where v.numbers[x] != nil:
                    joined += String(describing: ciW(v.numbers[array[i]]!))
                case let x where v.strings[x] != nil:
                    var a = v.strings[array[i]]
                    a = a?.filter { $0 != "\"" }
                    joined += a ?? ""
                default:
                    throw NXError.template("Unknown argument \(array[i])")
                }
            }
            
            if v.numbers[v_name] != nil {
                v.numbers.removeValue(forKey: v_name)
            }
            
            v.strings[v_name] = "\"" + joined + "\""
        } else {
            if v_val.sEval(v: v) == nil {
                v.strings[v_name] = "\"" + v_val + "\""
            } else if v_val.sEval(v: v) != nil {
                v.numbers[v_name] = v_val.sEval(v: v) ?? 0.0
            }
        }
    }
    
    func ciW(_ number: Double) -> Any {
        if number == Double(Int(number)) {
            return Int(number)
        } else {
            return number
        }
    }
    
    func instr(_ code: String, s: Variable) throws {
        let t = t(code)
        
        switch t[0] {
        case "print":
            do {
                try s.tOut.append(p(code, v: s))
            } catch NXError.template(let msg) {
                throw NXError.template("\(msg)")
            }
        case let x where x == "var" || (s.numbers[x] != nil || s.strings[x] != nil):
            do {
                try v(code, v: s)
            } catch NXError.template(let msg) {
                throw NXError.template("\(msg)")
            }
        case "if":
            do { try i(code, v: s) } catch NXError.template(let msg) { throw NXError.template(msg) }
        case "for":
            do {
                try l(code, v: s)
            } catch NXError.template(let msg) {
                throw NXError.template("\(msg)")
            }
        case let x where x.contains("END<"):
            print()
        case "cast":
            c(code, v: s)
        case "input":
            inp(code, v: s)
        case "sleep":
            do {
                try w(code, v: s)
            } catch NXError.template(let msg) {
                throw NXError.template("\(msg)")
            }
        case "func":
            f(code, v: s)
        case let name where s.defined_functions[name] != nil:
            s.code.remove(at: s.index)
            s.code.insert(contentsOf: s.defined_functions[name]!, at: s.index)
            s.index -= 1
        case "draw":
            do {
                try pa(code, v: s)
            } catch NXError.template(let msg) {
                throw NXError.template("\(msg)")
            }
        case "render":
            s.renderCommands = s.commands
            s.commands = []
        default:
            throw NXError.template("invalid")
        }
    }
    
    func t(_ input: String) -> [String] {
        var result = [""]
        var token = ""
        var inQuote = false
        
        for char in input {
            if char == "\"" || char == "[" || char == "]" { inQuote.toggle() }
            if char == " " || char == "(" || char == ")" || char == "," {
                if inQuote {
                    token += String(char)
                    if token == "//" {
                        token = ""
                        continue
                    }
                } else {
                    result.append(token)
                    token = ""
                }
            } else {
                token += String(char)
            }
        }
        
        if !token.isEmpty { result.append(token) }
        let removed = result.filter { $0 != "" }
        return removed
    }
    
    func l(_ input: String, v: Variable) throws {
        // for num times as var lbl "tag"
        let t = t(input)
        guard t.count == 7 else { throw NXError.template("PD method 'for' uses unknown arguments") }
        let indV = t[4]
        let end = (t[1] == "forever" ? -1 : Int(t[1].sEval(v: v) ?? -2.0))
        guard end != -2 else { throw NXError.template("Unknown usage of \(t[1])") }
        guard v.code.firstIndex(of: "END<" + t[6] + ">") != nil else { throw NXError.template("temp") }
        let endInd = v.code.firstIndex(of: "END<" + t[6] + ">")!
        
        v.loopInfo.append((end, v.index+1, endInd, t[4].filter { $0 != "\"" }, t[6]))
        v.numbers[indV] = indV == "_" ? -1.0 : 1.0
        print(v.loopInfo)
    }
    
    func i(_ input: String, v: Variable) throws {
        let t = t(input)
        guard t.checkSequence(1...3) else { throw NXError.template("Invalid condition in if statement") }
        guard t.count == 6 else { throw NXError.template("PD method 'if' has invalid parameters") }
        // if clicked(id: "id") lbl "lbl"
        let cond = Array(t[1...3])
        
        var firstArgument: String = ""
        var secondArgument: String = ""
        var binaryOperator: String = ""
        var id = ""
        
        if cond[0] != "clicked" {
            firstArgument = switch cond[0] {
            case let x where v.numbers[x] != nil:
                String(v.numbers[x]!)
            case let x where v.strings[x] != nil:
                v.strings[x]!
            default:
                if cond[0].sEval(v: v) != nil {
                    String(cond[0].sEval(v: v)!)
                } else {
                    "\"" + String(cond[0]) + "\""
                }
            }
            
            secondArgument = switch cond[2] {
            case let x where v.numbers[x] != nil:
                String(v.numbers[x]!)
            case let x where v.strings[x] != nil:
                v.strings[x]!
            default:
                if Double(cond[2]) != nil {
                    String(Double(cond[2])!)
                } else {
                    "\"" + String(cond[2]) + "\""
                }
            }
            
            print(firstArgument)
            print(secondArgument)
            
            binaryOperator = cond[1]
        } else if cond[0] == "clicked" {
            id = cond[2]
        } else if cond[0] == "pressed" {
            id = cond[2]
        }
        
        func unwrapQuotes(_ text: String) -> String {
            if text.first == "\"" && text.last == "\"" {
                return String(text.dropFirst().dropLast())
            }
            return text
        }

        let left = unwrapQuotes(firstArgument)
        let right = unwrapQuotes(secondArgument)

        let leftNum = Double(left)
        let rightNum = Double(right)

        var bool: Bool = false
        
        if cond[0] != "clicked" {
            switch binaryOperator {
            case "==":
                if let l = leftNum, let r = rightNum {
                    bool = l == r
                } else {
                    bool = left == right
                }

            case "!=":
                if let l = leftNum, let r = rightNum {
                    bool = l != r
                } else {
                    bool = left != right
                }

            case ">":
                if let l = leftNum, let r = rightNum {
                    bool = l > r
                } else {
                    bool = left > right
                }

            case "<":
                if let l = leftNum, let r = rightNum {
                    bool = l < r
                } else {
                    bool = left < right
                }

            case ">=":
                if let l = leftNum, let r = rightNum {
                    bool = l >= r
                } else {
                    bool = left >= right
                }

            case "<=":
                if let l = leftNum, let r = rightNum {
                    bool = l <= r
                } else {
                    bool = left <= right
                }

            default:
                bool = false
            }
        } else if cond[0] == "clicked" {
            if v.graphicsClicked[id] == true {
                bool = true
                v.graphicsClicked[id] = false
            }
        }
        
        let end = t[5]
        
        if !bool {
            v.index = v.code.firstIndex(of: "END<" + end + ">") ?? 0
        }
    }
    
    func pa(_ code: String, v: Variable) throws {
        func parseColor(_ name: String) -> Color {
            switch name.lowercased() {
            case "red": return .red
            case "blue": return .blue
            case "green": return .green
            case "yellow": return .yellow
            case "purple": return .purple
            case "orange": return .orange
            case "pink": return .pink
            case "black": return .black
            case "white": return .white
            case "gray": return .gray
            case "teal": return .teal
            case "cyan": return .cyan
            case "clear": return .clear
            default:
                print("⚠️ Unknown color: \(name). Defaulting to gray.")
                return .gray
            }
        }
        
        let tokens = t(code)
            guard tokens.count >= 6 else { throw NXError.template("Invalid draw syntax") }

            let shape = tokens[1]

            switch shape {
            case "circle":
                // [draw circle x: 150 y: 100 r: 500 rotation: 90 hollow?: true color: red id: somethign]
                let bool = tokens[11] == "true" ? true : false
                var color: Color = .gray
                var x: Double = 0.0
                var y: Double = 0.0
                var r: Double = 0.0
                var rot: Double = 0.0
                do {
                    color = parseColor(try tokens.get(13))
                    x = try tokens.get(3).sEval(v: v) ?? 0.0
                    y = try tokens.get(5).sEval(v: v) ?? 0.0
                    r = try tokens.get(7).sEval(v: v) ?? 0.0
                    rot = try tokens.get(9).sEval(v: v) ?? 0.0
                } catch {
                    throw NXError.template("Invalid parameters in PD function 'draw circle'")
                }
                
                v.commands.append(.circle(x: x, y: y, radius: r, color: color, hollowOrFilled: bool, rotation: rot))
                
                if tokens.contains("id:") {
                    guard tokens.count == 16 else { throw NXError.template("Invalid id") }
                    v.graphicsInfo[tokens.last!] = .circle(x: x, y: y, radius: r, color: color, hollowOrFilled: bool, rotation: rot)
                    v.graphicsClicked[tokens.last!] = false
                }

            case "rect":
                // [draw rect x: 100 y: 100 w: 500 h: 400 rotation: 90 hollow?: true color: red]
                let bool = tokens[13] == "true" ? true : false
                var color: Color = .gray
                var x: Double = 0.0
                var y: Double = 0.0
                var w: Double = 0.0
                var h: Double = 0.0
                var rot: Double = 0.0
                do {
                    color = parseColor(try tokens.get(15))
                    x = try tokens.get(3).sEval(v: v) ?? 0.0
                    y = try tokens.get(5).sEval(v: v) ?? 0.0
                    w = try tokens.get(7).sEval(v: v) ?? 0.0
                    h = try tokens.get(9).sEval(v: v) ?? 0.0
                    rot = try tokens.get(11).sEval(v: v) ?? 0.0
                } catch {
                    throw NXError.template("Invalid parameters in PD function 'draw rect'")
                }
                v.commands.append(.rect(x: x, y: y, width: w, height: h, color: color, hollowOrFilled: bool, rotation: rot))
                
                if tokens.contains("id:") {
                    guard tokens.count == 16 else { throw NXError.template("Invalid id") }
                    v.graphicsInfo[tokens.last!] = .rect(x: x, y: y, width: w, height: h, color: color, hollowOrFilled: bool, rotation: rot)
                    v.graphicsClicked[tokens.last!] = false
                }
                
            case "line":
                // [draw line x1: x1 y1: y1 x2: x2 y2: y2 rotation: 90 color: red]
                var color: Color = .gray
                var x1: Double = 0.0
                var x2: Double = 0.0
                var y1: Double = 0.0
                var y2: Double = 0.0
                do {
                    color = parseColor(try tokens.get(7))
                    x1 = try tokens.get(2).sEval(v: v) ?? 0.0
                    y1 = try tokens.get(3).sEval(v: v) ?? 0.0
                    x2 = try tokens.get(4).sEval(v: v) ?? 0.0
                    y2 = try tokens.get(5).sEval(v: v) ?? 0.0
                } catch {
                    throw NXError.template("Invalid parameters in PD function 'draw line'")
                }
                v.commands.append(.line(x1: x1, y1: y1, x2: x2, y2: y2, color: color))
                
                if tokens.contains("id:") {
                    guard tokens.count == 13 else { throw NXError.template("Invalid id") }
                    v.graphicsInfo[tokens.last!] = .line(x1: x1, y1: y1, x2: x2, y2: y2, color: color)
                    v.graphicsClicked[tokens.last!] = false
                }
                
            case "text":
                // [draw text x: x y: y text: text rotation: 90 color: color]
                var color: Color = .gray
                var x: Double = 0.0
                var y: Double = 0.0
                var text: String = ""
                var rot: Double = 0.0
                do {
                    color = parseColor(try tokens.get(11))
                    x = try tokens.get(3).sEval(v: v) ?? 0.0
                    y = try tokens.get(5).sEval(v: v) ?? 0.0
                    text = try p("print(" + tokens.get(7) + ")", v: v)
                    rot = try tokens.get(9).sEval(v: v) ?? 0.0
                } catch {
                    throw NXError.template("Invalid parameters in PD function 'draw text'")
                }
                
                v.commands.append(.text(x: x, y: y, text: text, color: color, rotation: rot))
                
                if tokens.contains("id:") {
                    guard tokens.count == 12 else { throw NXError.template("Invalid id") }
                    v.graphicsInfo[tokens.last!] = .text(x: x, y: y, text: text, color: color, rotation: rot)
                    v.graphicsClicked[tokens.last!] = false
                }

            default:
                throw NXError.template("Unknown shape: \(shape)")
            }
        
        print(v.commands)
    }
}

extension Array {
    func get(_ index: Int) throws -> Element {
        guard indices.contains(index) else {
                    throw NXError.template("Not defined")
                }
                return self[index]
    }
}

extension Array {
    func checkSequence(_ range: ClosedRange<Int>) -> Bool {
        return range.lowerBound >= startIndex && range.upperBound < endIndex
    }
}

extension String {
    func sEval(v: Variable) -> Double? {
        let r = self
            .replacingOccurrences(of: "{", with: "(")
            .replacingOccurrences(of: "}", with: ")")
            .replacingOccurrences(of: ";", with: ",")
        let expr = Expression(r, constants: v.numbers)
        
        guard let result = try? expr.evaluate() else {
            return nil
        }

        return result
    }
}
