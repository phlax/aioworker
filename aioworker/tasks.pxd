
from cpython cimport bool


cdef class task:
    cdef public f
    cdef public str name
    cdef public tuple fun_args
    cdef public dict fun_kwargs

    cdef bool _is_func(self, tuple args)
