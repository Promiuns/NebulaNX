# NebulaNX
A lightweight interpreted programming language made in Swift by **Ryan**.  
NebulaNX is designed to make **code feel human** — clean, visual, and readable.
Also I'm 12.

---

##  Features
- Variables (`var a = 10`)
- Loops (including nested loops)
- If statements
- Math evaluator
- String concatenation
- Functions
- Clickable graphics
- Rendering commands
- Debug console
- Input + user prompts

---

## Example Program
Here’s a clickable red circle, written in just **7 lines**:

```nebulanx
for forever times as _ lbl("clicking")
draw circle x: 150 y: 100 r: 25 rotation: 0 hollow?: true color: red, id: "circle"
render
if clicked(id: "circle") lbl("circle clicked")
print("you clicked me!")
END<"circle clicked">
END<"clicking">
```

Here's a simple calculator made in NebulaNX in **6 lines**:

```nebulanx
input("what is your first number?") -> num1
input("what is your second number") -> num2
cast num1 as number -> num1
cast num2 as number -> num2
var result = num1+num2
print(result)
