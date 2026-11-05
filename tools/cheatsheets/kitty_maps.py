# Dump kitty's keyboard shortcuts: built-in defaults vs a given kitty.conf.
# Runs inside kitty's own Python (kitty +launch), so it sees exactly what kitty
# would load — includes, kitty_mod, and `map` lines resolved by kitty itself.
#
# Usage: kitty +launch kitty_maps.py <kitty.conf> <out.json>
import json
import sys

from kitty.config import load_config
from kitty.types import human_repr_of_single_key, mod_to_names


def dump(paths):
    opts = load_config(*paths)
    maps = {}
    for defs in opts.keyboard_modes[""].keymap.values():
        for d in defs:
            keys = (d.trigger,) + tuple(d.rest or ())
            maps[" > ".join(human_repr_of_single_key(k, opts.kitty_mod) for k in keys)] = d.definition
    return maps, "+".join(mod_to_names(opts.kitty_mod, False, 0))


conf, out = sys.argv[1], sys.argv[2]
defaults, _ = dump([])
active, kitty_mod = dump([conf])
with open(out, "w") as f:
    json.dump({"defaults": defaults, "active": active, "kitty_mod": kitty_mod}, f, indent=1)
