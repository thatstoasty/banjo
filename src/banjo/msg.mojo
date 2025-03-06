from utils.variant import Variant
from banjo.key import KeyMsg


@value
@register_passable("trivial")
struct FocusMsg:
    """Represents a terminal focus message. This occurs when the terminal gains focus."""

    fn write_to[W: Writer, //](self, mut writer: W) -> None:
        writer.write("FocusMsg")


@value
@register_passable("trivial")
struct BlurMsg:
    """Represents a terminal blur message. This occurs when the terminal loses focus."""

    fn write_to[W: Writer, //](self, mut writer: W) -> None:
        writer.write("BlurMsg")


@value
@register_passable("trivial")
struct ExitMsg:
    fn write_to[W: Writer, //](self, mut writer: W) -> None:
        writer.write("ExitMsg")


fn exit_msg() -> Msg:
    return ExitMsg()


@value
@register_passable("trivial")
struct UnknownInputByteMsg:
    var value: Byte

    fn write_to[W: Writer, //](self, mut writer: W) -> None:
        writer.write("UnknownInputByteMsg")


@value
@register_passable("trivial")
struct NoMsg:
    fn write_to[W: Writer, //](self, mut writer: W) -> None:
        writer.write("NoMsg")


@value
struct Msg:
    alias _type = Variant[ExitMsg, KeyMsg, FocusMsg, BlurMsg, UnknownInputByteMsg, NoMsg]
    var value: Self._type

    @implicit
    fn __init__(out self, value: ExitMsg):
        self.value = value

    @implicit
    fn __init__(out self, value: KeyMsg):
        self.value = value

    @implicit
    fn __init__(out self, value: FocusMsg):
        self.value = value

    @implicit
    fn __init__(out self, value: BlurMsg):
        self.value = value

    @implicit
    fn __init__(out self, value: UnknownInputByteMsg):
        self.value = value

    @implicit
    fn __init__(out self, value: NoneType):
        self.value = value

    fn write_to[W: Writer, //](self, mut writer: W) -> None:
        if self.value.isa[ExitMsg]():
            writer.write(self.value[ExitMsg])
        elif self.value.isa[KeyMsg]():
            writer.write(self.value[KeyMsg])
        elif self.value.isa[FocusMsg]():
            writer.write(self.value[FocusMsg])
        elif self.value.isa[BlurMsg]():
            writer.write(self.value[BlurMsg])
        elif self.value.isa[UnknownInputByteMsg]():
            writer.write(self.value[UnknownInputByteMsg])
        elif self.value.isa[NoneType]():
            writer.write(self.value[NoneType])

    fn isa[T: CollectionElement](self) -> Bool:
        return self.value.isa[T]()

    fn __getitem__[T: CollectionElement](ref self) -> ref [__origin_of(self.value)] T:
        return self.value[T]
