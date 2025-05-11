from sys import stdin
import banjo.termios
from banjo.termios import WhenOption, tcsetattr, tcgetattr, set_raw


fn get_key_unix() raises -> String:
    var key: String = ""
    with open("/dev/tty", "r") as stdin:
        var bytes = stdin.read_bytes(1)
        key = chr(Int(bytes[0]))

    return key


fn get_key() raises -> String:
    print("Press c to exit.")
    var k: String = ""
    var old_settings = set_raw(stdin)

    while True:
        k = get_key_unix()
        if k == "c":
            break

    # restore terminal settings
    tcsetattr(stdin, WhenOption.TCSADRAIN, old_settings)
    print(k)

    return k


fn main() raises:
    print(get_key())
