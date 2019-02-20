
from aioworker.subscriber cimport Subscriber


cdef class RedisSubscriber(Subscriber):
    cdef public loop
    cdef public _redis_pub
    cdef public _redis_sub
    cdef public backend
