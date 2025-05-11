from utils.variant import Variant
from banjo.key_msg import KeyMsg


@fieldwise_init
@register_passable("trivial")
struct FocusMsg(Copyable, Movable, Writable):
    """Represents a terminal focus message. This occurs when the terminal gains focus."""

    fn write_to[W: Writer, //](self, mut writer: W) -> None:
        """Writes the focus message to the writer.

        Parameters:
            W: The writer to write the message to.

        Args:
            writer: The writer to write the message to.
        """
        writer.write("FocusMsg")


@fieldwise_init
@register_passable("trivial")
struct BlurMsg(Copyable, Movable, Writable):
    """Represents a terminal blur message. This occurs when the terminal loses focus."""

    fn write_to[W: Writer, //](self, mut writer: W) -> None:
        """Writes the blur message to the writer.

        Parameters:
            W: The writer to write the message to.

        Args:
            writer: The writer to write the message to.
        """
        writer.write("BlurMsg")


@fieldwise_init
@register_passable("trivial")
struct ExitMsg(Copyable, Movable, Writable):
    """Represents a terminal exit message. This occurs when the terminal is about to exit."""

    fn write_to[W: Writer, //](self, mut writer: W) -> None:
        """Writes the exit message to the writer.

        Parameters:
            W: The writer to write the message to.

        Args:
            writer: The writer to write the message to.
        """
        writer.write("ExitMsg")


fn exit_msg() -> Msg:
    """Creates an exit message.

    Returns:
        An instance of `ExitMsg`.
    """
    return ExitMsg()


@fieldwise_init
@register_passable("trivial")
struct UnknownInputByteMsg(Copyable, Movable, Writable):
    """Represents an unknown input byte message. This occurs when an unrecognized byte is received."""

    var value: Byte
    """Internal value representing the unknown input byte."""

    fn write_to[W: Writer, //](self, mut writer: W) -> None:
        """Writes the unknown input byte message to the writer.

        Parameters:
            W: The writer to write the message to.

        Args:
            writer: The writer to write the message to.
        """
        writer.write("UnknownInputByteMsg")


@fieldwise_init
@register_passable("trivial")
struct NoMsg(Copyable, Movable, Writable):
    """Represents a message that indicates no input was received. This is used when no relevant message is available."""

    fn write_to[W: Writer, //](self, mut writer: W) -> None:
        """Writes no message to the writer.

        Parameters:
            W: The writer to write the message to.

        Args:
            writer: The writer to write the message to.
        """
        writer.write("NoMsg")


@fieldwise_init
struct GeneralMsg(Copyable, Movable, Writable):
    """Represents a general message that contains a string value. This is used for messages that do not fit into other categories.
    """

    var value: String
    """Internal value representing the general message."""

    fn write_to[W: Writer, //](self, mut writer: W) -> None:
        """Writes the general message to the writer.

        Parameters:
            W: The writer to write the message to.

        Args:
            writer: The writer to write the message to.
        """
        writer.write("GeneralMsg(value=", self.value, ")")


@fieldwise_init
struct Msg(Copyable, Movable, Writable):
    """A message that can be sent to the terminal. It can represent various types of messages such as exit, key, focus, blur, unknown input byte, general messages, or no message.
    """

    alias _type = Variant[ExitMsg, KeyMsg, FocusMsg, BlurMsg, UnknownInputByteMsg, GeneralMsg, NoMsg]
    var value: Self._type
    """Internal value representing the message. It can be one of the following types: ExitMsg, KeyMsg, FocusMsg, BlurMsg, UnknownInputByteMsg, GeneralMsg, or NoMsg."""

    @implicit
    fn __init__(out self, value: ExitMsg):
        """Initializes the message with an ExitMsg.

        Args:
            value: The `ExitMsg` to initialize the message with.
        """
        self.value = value

    @implicit
    fn __init__(out self, value: KeyMsg):
        """Initializes the message with a KeyMsg.

        Args:
            value: The `KeyMsg` to initialize the message with.
        """
        self.value = value

    @implicit
    fn __init__(out self, value: FocusMsg):
        """Initializes the message with a FocusMsg.

        Args:
            value: The `FocusMsg` to initialize the message with.
        """
        self.value = value

    @implicit
    fn __init__(out self, value: BlurMsg):
        """Initializes the message with a BlurMsg.

        Args:
            value: The `BlurMsg` to initialize the message with.
        """
        self.value = value

    @implicit
    fn __init__(out self, value: UnknownInputByteMsg):
        """Initializes the message with an UnknownInputByteMsg.

        Args:
            value: The `UnknownInputByteMsg` to initialize the message with.
        """
        self.value = value

    @implicit
    fn __init__(out self, value: NoneType):
        """Initializes the message with a NoneType, indicating no message.

        Args:
            value: The `NoneType` to initialize the message with.
        """
        self.value = value

    fn write_to[W: Writer, //](self, mut writer: W) -> None:
        """Writes the message to the writer.

        Parameters:
            W: The writer to write the message to.

        Args:
            writer: The writer to write the message to.
        """
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

    fn isa[T: Movable & Copyable](self) -> Bool:
        """Checks if the message is of type T.

        Parameters:
            T: The type to check against. It must be a Movable and Copyable type.

        Returns:
            True if the message is of type T, False otherwise.
        """
        return self.value.isa[T]()

    fn __getitem__[T: Movable & Copyable](ref self) -> ref [__origin_of(self.value)] T:
        """Gets the value of the message as type T.

        Parameters:
            T: The type to get the value as. It must be a Movable and Copyable type.

        Returns:
            The value of the message as type T.
        """
        return self.value[T]
