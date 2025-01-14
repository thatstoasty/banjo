import banjo
from banjo.program import TUI, BaseModel


fn main() raises:
    var program = banjo.TUI(BaseModel())
    program.run()
