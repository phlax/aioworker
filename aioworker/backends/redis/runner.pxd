
from aioworker.runner cimport Runner


cdef class RedisRunner(Runner):
    cdef _redis_consumer
    cdef _redis_poller    
