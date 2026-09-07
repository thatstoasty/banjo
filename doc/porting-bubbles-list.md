# Porting a list component to Mojo

A plan for bringing a reusable list widget into `banjo`, drawing the component
contract from Rust's [ratatui](https://github.com/ratatui/ratatui) and the
feature set from Charmbracelet's
[`bubbles/list`](https://github.com/charmbracelet/bubbles).

## Why the contract comes from ratatui rather than bubbles

The first draft of this plan ported `bubbles/list` directly. Inspecting
ratatui, and `ratatui-textarea` as a worked example of a component built on it,
changed that decision. Four things settled it.

**Ratatui does not need boxed existentials.** `Box<dyn WidgetRef>` occurs three
times in all of ratatui, and every occurrence is a doc example or a test. The
real path is monomorphised generics. Its `List` holds `Vec<ListItem>` -- a
concrete type -- and `ListItem` is styled text that the application maps its own
data into. `bubbles/list` instead requires `[]Item` and an `ItemDelegate`
interface, and Mojo cannot express either:

```
error: 'List' parameter 'T' has 'Movable' type,
       but value has type '__generator_type[T: Item] Item'
```

`Some[Trait]` is usable in argument position only; there are no boxed
existentials. Ratatui sidesteps the problem by not having it.

**State belongs to the application, not the widget.** `StatefulWidget` carries
an associated `State` type, and ratatui's `ListState` is two fields, `offset`
and `selected`. `bubbles/list.Model` owns items, delegate, paginator, spinner,
help, a filter input, a timer and a status message. Mojo already handles the
associated-type pattern -- `banjo.app.Program.Msg` uses it.

**Ownership maps directly.** `fn render(self, area, buf)` consuming the widget,
with `&mut Buffer` and `&mut Self::State`, is `deinit self` and `mut` in Mojo.
Go's pointer receivers and nil-able interface values have no clean equivalent.

**It removes the framework gaps.** `banjo` has no `Cmd`, no way for a component
to emit into an application's closed `Msg` variant, and no way for a component
to register a timer. Ratatui-shaped components need none of these: the
application owns the loop and calls methods. `TextArea::input` returns a plain
`bool` meaning "modified", which is exactly the `dirty` flag `Runtime.run`
already tracks.

## What is deliberately not taken from ratatui

**Immediate-mode rendering.** Ratatui composes cells in a two-dimensional
`Buffer` with `Rect` areas, clipping and a layout solver. `banjo` composes
styled strings through `mog`, and `Renderer` already diffs lines. Adopting
`Buffer`/`Rect` would mean reimplementing most of `ratatui-core` and discarding
what exists. Components therefore render to a `String`.

Lifetimes are also dropped: `List<'a>` borrows its content, whereas the Mojo
version owns its `String`s.

## The component contract

```mojo
trait StatefulWidget(Copyable):
    comptime State: Movable
    def render(self, mut state: Self.State) raises -> String
```

State external, plain mutating methods, "did anything change" returned as a
`Bool` rather than a command, and concrete item types rather than existentials.
Applications keep `banjo`'s Elm-shaped architecture: these two are not in
conflict, since a state-external component is perfectly drivable from inside
`Program.update`.

## Phases

- **Phase 1 -- `key`.** *Done.* `Binding`, `Help`, `matches`. Bindings match on
  `KeyEvent` values rather than strings, which is closer to ratatui's
  backend-agnostic `Input`/`Key` than to the Go original.
- **Phase 2 -- `paginator`.** *Done.* Page arithmetic and dot/arabic rendering.
- **Phase 3 -- list core.** *Done.* `ListItem`, `ListState`, `ListView`.
  Selection, scroll offset with padding, highlight symbol and styles,
  multi-line items. `render` is pure and `scroll_into_view` is separate,
  because `Program.view` takes an immutable `self` and so cannot be where
  scrolling is decided.
- **Phase 4 -- default item.** *Done.* `DefaultItemStyles` and `default_item`
  build the `bubbles` title-and-description row as an application-side mapping.
  Both appearances are built up front, since mog renders to a string and cannot
  patch a highlight over one the way ratatui patches cells.

  Block/border integration was dropped: sizing a list inside a bordered frame
  needs the frame's thickness, and mog exposes no padding or border getters, so
  any helper would have to guess. Applications pass the row count they want.
- **Phase 5 -- `help`.** *Done.* `HelpView` renders bindings short on one line
  or full in columns, skipping disabled ones and truncating with an ellipsis.
  Go's `KeyMap` interface is replaced by passing the bindings in directly.
- **Phase 6 -- filtering.** *Done.* `TextInput` is a single-line input, and
  `filter.rank` is a subsequence matcher scoring adjacency, word starts and
  early matches. Filtering stays an application concern: rank the titles, hand
  the widget a shorter list. `bubbles` instead builds filtering into the list
  model and pulls in `text_input`, `cursor` and `internal` -- about 2,000 lines
  -- for the query box alone.

  Like `ListView.render`, `TextInput.view` is pure, because `Program.view`
  takes an immutable `self`. See the note on view-time state below.

The ratatui contract deletes most of what the bubbles-shaped plan needed.
Spinners, status messages and the `Cmd` machinery leave the component entirely,
and with them the whole `text_input` dependency.

## Out of scope

- **Heterogeneous items.** Not expressible; applications map their data to
  `ListItem`, which is what ratatui does anyway.
- **`ItemDelegate`.** Replaced by that mapping.
- **Match highlighting** inside filtered items, until `mog` grows the
  equivalent of lipgloss's `StyleRunes`.

## View-time state

`Program.view` takes an immutable `self`, so **a component cannot compute
anything at render time that it needs to remember**. Both components ran into
this, and the resolution is the same in each:

1. **Store the state on the component or in the caller's state object**, not in
   a local. `ListState.offset` and `TextInput.offset` are both fields.
2. **Write it only from `update`**, which does take a mutable `self`.
   `ListView.scroll_into_view` and `TextInput._follow_cursor` are the writers.
3. **Read it defensively from `view`**, nudging a local copy so a stale value
   still renders correctly, and writing nothing back. `ListView.render` derives
   its window on a scratch `ListState`; `TextInput.view` nudges a local `start`.

Deriving the value afresh each render instead of storing it looks tempting and
is subtly wrong: a window derived from the cursor alone pins the cursor to one
edge and scrolls the content underneath it, where a remembered window holds
still and lets the cursor move inside it. Both behaviours are pinned by tests.

This is not a Mojo restriction. `bubbletea` has the same property -- `View()`
takes a value receiver -- and `bubbles/list` resolves it the same way, calling
`updatePagination()` from a dozen sites in `Update` and never from `View`.
Ratatui is the odd one out: `StatefulWidget::render` takes `&mut Self::State`
and does this bookkeeping at render time.

## Further components

Ported after the list, on the same contract.

- **`spinner`.** Frame sets and an index. Go's spinner owns a `tea.Cmd` that
  reschedules itself at its FPS; `Runtime.every` already does that, so each
  frame set just carries the rate it was designed for and the application
  registers the timer.
- **`progress`.** A pure function of a percentage, as ratatui's `Gauge` is.
  Two things are dropped: Go's spring-simulated animation, which needs
  commands and belongs in the application anyway, and its gradient fill, which
  needs `lipgloss.Blend1D` and has no `mog` equivalent.
- **`table`.** Columns, rows, a header and a scrolling selectable body.
  `TableState` is an alias of `ListState` rather than a second type -- the two
  hold the same two fields, and `bubbles` duplicates the navigation logic
  between its list and its table for no benefit.

## A note on `termctl` key equality

*Fixed.* `KeyEvent.__eq__` was declared `raises`, so it did not satisfy the
`Equatable` requirement `EventType` carries, and `==` silently resolved to
structural equality with the case normalisation unreachable -- `G`, `shift+g`
and `shift+G` all rendered as `G` yet none compared equal. It is now
non-raising, and `key.matches` compares `KeyEvent` values directly rather than
folding case itself.
