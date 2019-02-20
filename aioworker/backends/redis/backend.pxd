
from aioworker.backend cimport Backend


cdef class RedisBackend(Backend):
    cdef base
