

from .app cimport App
from .request cimport JobRequest
from .tasks cimport task


cdef class Job:
    cdef public request
    cdef public _start
    cdef public result

    cpdef JobRequest create_request(self, App app, task task, tuple args, dict kwargs)
