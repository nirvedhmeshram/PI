import collections
from itertools import repeat
from typing import List, Dict, Any, Tuple

__all__ = ["consume_prefix_in_state_dict_if_present"]


def _ntuple(n, name="parse"):
    def parse(x):
        if isinstance(x, collections.abc.Iterable):
            return tuple(x)
        return tuple(repeat(x, n))

    parse.__name__ = name
    return parse


def _make_ntuple(x: Any, n: int) -> Tuple[Any, ...]:
    if isinstance(x, collections.abc.Iterable):
        return tuple(x)
    return tuple(repeat(x, n))


_single = _ntuple(1, "_single")
_pair = _ntuple(2, "_pair")
_triple = _ntuple(3, "_triple")
_quadruple = _ntuple(4, "_quadruple")


def _reverse_repeat_tuple(t, n):

    return tuple(x for x in reversed(t) for _ in range(n))


def _list_with_default(out_size: List[int], defaults: List[int]) -> List[int]:
    if isinstance(out_size, int):
        return out_size
    if len(defaults) <= len(out_size):
        raise ValueError(
            "Input dimension should be at least {}".format(len(out_size) + 1)
        )
    return [
        v if v is not None else d for v, d in zip(out_size, defaults[-len(out_size) :])
    ]


def consume_prefix_in_state_dict_if_present(
    state_dict: Dict[str, Any], prefix: str
) -> None:

    keys = sorted(state_dict.keys())
    for key in keys:
        if key.startswith(prefix):
            newkey = key[len(prefix) :]
            state_dict[newkey] = state_dict.pop(key)

    # also strip the prefix in metadata if any.
    if "_metadata" in state_dict:
        metadata = state_dict["_metadata"]
        for key in list(metadata.keys()):
            # for the metadata dict, the key can be:
            # '': for the DDP module, which we want to remove.
            # 'module': for the actual model.
            # 'module.xx.xx': for the rest.

            if len(key) == 0:
                continue
            newkey = key[len(prefix) :]
            metadata[newkey] = metadata.pop(key)
