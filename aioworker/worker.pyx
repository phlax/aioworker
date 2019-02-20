# distutils: define_macros=CYTHON_TRACE_NOGIL=1
# cython: linetrace=True
# cython: binding=True

import asyncio
from typing import Union

from .shared import tasks, workers

from .app cimport App
from .backends.redis.backend cimport RedisBackend
from .model cimport Config
from .tasks cimport task
from .utils cimport pack_task, resolve, unpack


subscribers = {}

cdef str prefix = "aioworker"


cdef class Worker(object):

    def __cinit__(self, Config config, **kwargs):
        self.config = config
        self.loop = kwargs.get("loop") or asyncio.get_event_loop()
        self.prefix = kwargs.get("prefix", prefix)
        self.configure()

    cpdef configure(self):
        self._set_globals()

    cpdef load(self, App app):
        self.backend = self.get_backend(app)

    cpdef start(self):
        return self.backend.start()

    cpdef stop(self):
        return self.backend.stop()

    cpdef _set_globals(self):
        global subscribers, tasks, workers
        self.subscribers = subscribers
        self.tasks = tasks
        if workers:
            workers[0] = self
        else:
            workers.append(self)

    cpdef get_backend(self, App app):
        Backend = (
            RedisBackend
            if self.config.backend == "aioworker.backends.RedisBackend"
            else resolve(self.config.backend))
        return Backend(self, app)

    async def call(self, task: task, *args, **kwargs) -> Union[str, None]:
        return await self.backend.push_task(task, args, kwargs)


class Py__Worker(Worker):
    pass


cpdef get_worker():
    return (
        workers[0]
        if workers
        else None)
