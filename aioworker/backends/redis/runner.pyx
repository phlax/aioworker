# distutils: define_macros=CYTHON_TRACE_NOGIL=1
# cython: linetrace=True
# cython: binding=True

import logging
import aioredis

from aioworker.runner cimport Runner
from aioworker.utils cimport parse_dsn

log = logging.getLogger("aioworker")


cdef class RedisRunner(Runner):

    def __init__(self, backend):
        super().__init__(backend)
        _, password, host, port, db = parse_dsn(
            backend.config.broker,
            default_port=6379,
            default_db=0)
        db = int(db)
        self._redis_consumer = (
            backend.loop.run_until_complete(
                aioredis.create_redis(
                    address=(host, port),
                    db=db,
                    password=password,
                    loop=self.backend.loop)))
        self._redis_poller = (
            backend.loop.run_until_complete(
                aioredis.create_redis(
                    address=(host, port),
                    db=db,
                    password=password,
                    loop=self.backend.loop)))

    async def has_pending_tasks(self):
        return bool(self.jobs)

    def stop_delayers(self):
        self._redis_consumer.close()
        self._redis_poller.close()
        for t in self.jobs.values():
            t.cancel()
        if not self.backend.loop.is_closed():
            self.backend.loop.run_until_complete(
                self._redis_consumer.wait_closed())
            self.backend.loop.run_until_complete(
                self._redis_poller.wait_closed())

    @property
    def poller(self):
        return self._redis_poller

    @property
    def pending_tasks(self):
        return self._redis_consumer.brpop(self.backend.task_event, timeout=0)


__all__ = ("RedisRunner", )
