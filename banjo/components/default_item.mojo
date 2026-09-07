"""The title-and-description row from `bubbles`, as a mapping rather than a delegate.

`bubbles` renders this through an `ItemDelegate` interface that receives the
list model back. That shape does not port -- Mojo has no boxed existentials,
and the circular reference is unpleasant besides. Here it is a plain function
from your data to a `ListItem`, which is what ratatui expects of an
application anyway.

```mojo
var styles = DefaultItemStyles(Profile.ANSI)
items.append(default_item("Raspberry", "A red berry", styles))
```

Both appearances are built up front, because mog renders to a string and a
selected row's title and description are styled differently. See
`ListItem.selected_content`.
"""

import mog
from mog import Profile

from banjo.components.list import ListItem


@fieldwise_init
struct DefaultItemStyles(Copyable):
    """Styles for a title-and-description row, selected and not."""

    var normal_title: mog.Style
    """The title of an unselected row."""
    var normal_desc: mog.Style
    """The description of an unselected row."""
    var selected_title: mog.Style
    """The title of the selected row."""
    var selected_desc: mog.Style
    """The description of the selected row."""

    def __init__(out self, profile: Profile):
        """Creates the default styles, which follow the `bubbles` dark theme.

        The selected row is marked with a left border bar, as in `bubbles`,
        which is also what keeps its indentation matching the unselected rows.

        Args:
            profile: The colour profile to render in.
        """
        self.normal_title = mog.Style(profile, padding=mog.Padding(left=2)).foreground(mog.Color(0xDDDDDD))
        self.normal_desc = mog.Style(profile, padding=mog.Padding(left=2)).foreground(mog.Color(0x777777))
        self.selected_title = (
            mog.Style(profile, padding=mog.Padding(left=1))
            .border(mog.NORMAL_BORDER)
            .border_side_rendering(top=False, right=False, bottom=False, left=True)
            .border_foreground(mog.Color(0xAD58B4))
            .foreground(mog.Color(0xEE6FF8))
        )
        self.selected_desc = (
            mog.Style(profile, padding=mog.Padding(left=1))
            .border(mog.NORMAL_BORDER)
            .border_side_rendering(top=False, right=False, bottom=False, left=True)
            .border_foreground(mog.Color(0xAD58B4))
            .foreground(mog.Color(0xAD58B4))
        )


def default_item(
    var title: String,
    var description: String,
    styles: DefaultItemStyles,
    *,
    show_description: Bool = True,
) raises -> ListItem:
    """Builds a row showing a title and, optionally, a description beneath it.

    Args:
        title: The row's title.
        description: The row's description.
        styles: How to draw it, selected and not.
        show_description: Whether to draw the description at all. With it off
            the row is a single line, as in `bubbles`.

    Returns:
        A list item carrying both appearances.

    Raises:
        Error: If styling fails.
    """
    if not show_description:
        return ListItem(
            styles.normal_title.render(title),
            selected_content=styles.selected_title.render(title),
        )

    var normal = String(styles.normal_title.render(title), "\n", styles.normal_desc.render(description))
    var selected = String(styles.selected_title.render(title), "\n", styles.selected_desc.render(description))
    return ListItem(normal^, selected_content=selected^)
