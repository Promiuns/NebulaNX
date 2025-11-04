import SwiftUI
import Combine

class runReference: ObservableObject {
    @Published var runner = Run_Code()
}

import SwiftUI
import Combine

@MainActor
class Run_Code {
    var int = Interpreter()       // your interpreter instance
    var timer: Timer?             // timer for frame loop
    var delete = false            // deletion flag
    var key = ""                  // variable key to delete
    
    func run(v: Variable) {
        v.index = 0
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 120.0, repeats: true) { [weak self] timer in
            DispatchQueue.main.async {
                guard let self = self else { v.tOut = ["Unknown error at index \(v.index)"]; timer.invalidate(); return }
                
                // Handle deletion toggle
                if v.pauselength == 0 {
                    if self.delete {
                        v.numbers.removeValue(forKey: String(self.key))
                        self.delete.toggle()
                    }
                    
                    // Loop info updating
                    // --- Update all loop end indices ---
                    for (index, _) in v.loopInfo.enumerated() {
                        v.loopInfo[index].2 = v.code.firstIndex(of: "END<" + v.loopInfo[index].4 + ">") ?? -1
                        if v.loopInfo[index].2 == -1 {
                            v.tOut = ["Runtime Error: Missing END<\(v.loopInfo[index].4)>"]
                            self.timer?.invalidate()
                            return
                        }
                    }

                    // --- Handle active loop (only the last one) ---
                    if !v.loopInfo.isEmpty {
                        let lastIndex = v.loopInfo.count - 1

                        // Check if reached the END tag for this loop
                        if v.index == v.loopInfo[lastIndex].2 {
                            // Decrement iteration count
                            v.loopInfo[lastIndex].0 -= 1

                            // Increment loop variable if it's numeric
                            if let varName = v.loopInfo[lastIndex].3 as String?,
                               v.numbers[varName] != nil {
                                v.numbers[varName]! += 1.0
                            }

                            // If still looping, go back to start
                            if v.loopInfo[lastIndex].0 > 0 || v.loopInfo[lastIndex].0 < 0 {
                                v.index = v.loopInfo[lastIndex].1
                                return
                            }

                            // Otherwise, this loop is done → remove it
                            self.key = v.loopInfo[lastIndex].3
                            v.loopInfo.removeLast()
                            self.delete.toggle()
                        }
                    }
                    
                    // End of code reached
                    if v.index >= v.code.count {
                        timer.invalidate()
                        return
                    }
                    
                    // Execute instruction
                    do {
                        try self.int.instr(v.code[v.index], s: v)
                    } catch NXError.template(let msg) {
                        v.tOut = [msg]
                        timer.invalidate()
                        return
                    } catch {
                        v.tOut = ["Runtime Error: \(error)"]
                        timer.invalidate()
                        return
                    }
                    
                    // Move forward in interpreter
                    if !v.blocked && !v.paused {
                        v.index += 1
                    }
                } else {
                    v.pauselength -= 1.0/120.0
                }
            }
        }
    }
}
