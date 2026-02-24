Output doc/tapes/snake.gif

Set Shell "zsh"
Set FontSize 20
Set Width 1200
Set Height 800
Set WindowBar Colorful
Set Theme "Catppuccin Frappe"
Set BorderRadius 10

Type "cd examples/elm/snake" Sleep 200ms Enter
Sleep 1s
Type "pixi run app" Enter Sleep 2s Enter Sleep 50ms
Up Sleep 500ms Left Sleep 500ms Down Sleep 500ms Left Sleep 500ms Down Sleep 500ms

# Go left until collision with the wall to end the game
Left Sleep 100ms Left Sleep 100ms Left Sleep 100ms Left Sleep 100ms Left Sleep 100ms Left Sleep 100ms Left Sleep 100ms Left Sleep 100ms Left Sleep 100ms Left Sleep 100ms
Sleep 2s
