from banjo.app import Runtime
from termctl.multiplex.kqueue import KQueueSelector
from sample.app import Model


comptime RENDER_HZ = 60.0
"""The ceiling on repaints. Nothing here animates on its own, so this caps how
often the view is rebuilt after input rather than driving frames."""


def main() raises:
    var model = Model()
    var rt = Runtime[Model](KQueueSelector(), RENDER_HZ)
    rt.run(model)
