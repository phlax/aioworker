# distutils: define_macros=CYTHON_TRACE_NOGIL=1
# cython: linetrace=True
# cython: binding=True

import os
import atexit
import asyncio
import functools
import logging
import time

from aioworker.backend cimport Backend
from .runner cimport RedisRunner
from .subscriber cimport RedisSubscriber

log = logging.getLogger("aioworker")


cdef class RedisBackend(Backend):

    def get_subscriber(self):
        return RedisSubscriber(self)

    def get_runner(self):
        return RedisRunner(self)
