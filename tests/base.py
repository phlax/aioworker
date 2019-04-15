
from contextlib import ExitStack, contextmanager
from unittest.mock import MagicMock


@contextmanager
def nested(*contexts):
    """
        Reimplementation of nested in python 3.
    """
    with ExitStack() as stack:
        yield [stack.enter_context(c) for c in contexts]


class AsyncMock(MagicMock):
    async def __call__(self, *args, **kwargs):
        return super(AsyncMock, self).__call__(*args, **kwargs)
