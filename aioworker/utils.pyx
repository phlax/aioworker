# distutils: define_macros=CYTHON_TRACE_NOGIL=1
# cython: linetrace=True
# cython: binding=True

import importlib
import logging
from typing import Union
from urllib.parse import urlparse

import umsgpack as msgpack

from .exceptions import AioworkerTypeError
from .model import GlobalConfig


log = logging.getLogger("aioworker")
BANNER = """"""


cpdef resolve(str path):
    cdef list parts = path.split(".")
    return getattr(
        importlib.import_module(".".join(parts[:-1])),
        parts[-1])


cpdef bytes pack(dict msg):
    return msgpack.packb(msg, use_bin_type=True)


cpdef dict unpack(bytes incoming):
    return msgpack.unpackb(incoming, raw=False)


cpdef bytes pack_task(str task_id, str function, tuple args, dict kwargs):
    return pack(
        dict(task_id=task_id,
             function=function,
             args=args,
             kwargs=kwargs))


cpdef tuple unpack_task(bytes incoming):
    cdef dict msg = unpack(incoming)
    return (
        msg.get("task_id"),
        msg.get("function"),
        msg.get("args"),
        msg.get("kwargs"))


cpdef tuple parse_dsn(
        str dsn,
        default_port=None,
        default_db=None):
    _, host, db, _, _, _ = urlparse(dsn)

    if "@" in host:
        credentials, host = host.split("@", maxsplit=1)
    else:
        credentials = None

    user, password = None, None
    if credentials:
        _splitted_cred = credentials.split(":", maxsplit=1)

        if len(_splitted_cred) == 1:
            user = _splitted_cred[0]
            password = ""
        else:
            user, password = _splitted_cred

    if ":" in host:
        host, port = host.split(":")
        port = int(port)
    else:
        port = None

    if db.startswith("/"):
        db = db[1:]
    if not db:
        db = ""

    if default_port is not None and not port:
        port = default_port

    if default_db is not None and not db:
        db = default_db

    return user, password, host, port, db


def get_log_level(verbosity: int) -> int:
    verbosity *= 10

    if verbosity > logging.CRITICAL:
        verbosity = logging.CRITICAL

    if verbosity < logging.DEBUG:
        verbosity = logging.DEBUG

    return (logging.CRITICAL - verbosity) + 10


__all__ = (
    "parse_dsn", "BANNER", "get_log_level")
