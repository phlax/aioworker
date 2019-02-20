# distutils: define_macros=CYTHON_TRACE_NOGIL=1
# cython: linetrace=True
# cython: binding=True

import concurrent.futures


class AioworkerError(Exception):
    pass


class AioworkerValueError(ValueError):
    pass


class AioworkerTypeError(TypeError):
    pass


class AioworkerTimeout(concurrent.futures.TimeoutError):
    pass


__all__ = ("AioworkerError", "AioworkerValueError", "AioworkerTypeError",
           "AioworkerTimeout")
