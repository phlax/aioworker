# distutils: define_macros=CYTHON_TRACE_NOGIL=1
# cython: linetrace=True
# cython: binding=True

import logging
import aioredis

from aioworker.subscriber cimport Subscriber
from aioworker.utils cimport pack, parse_dsn

log = logging.getLogger("aioworker")


cdef class RedisSubscriber(Subscriber):

    def __init__(self, backend):
        super().__init__(backend)
        _, password, host, port, db = parse_dsn(
            backend.config.broker,
            default_port=6379,
            default_db=0)
        db = int(db)
        self._redis_pub = self.backend.loop.run_until_complete(
            aioredis.create_redis(
                address=(host, port),
                db=db,
                password=password,
                loop=self.backend.loop))
        self._redis_sub = self.backend.loop.run_until_complete(
            aioredis.create_redis(
                address=(host, port),
                db=db,
                password=password,
                loop=self.backend.loop))

    async def publish(self, str topic, dict data):
        await self._redis_pub.publish(
            "{}:{}".format(self.backend.config.prefix, topic),
            pack(data))

    async def has_pending_topics(self) -> bool:
        return bool(self.running_tasks)

    async def register_topics(self):
        channels = await self._redis_sub.psubscribe(
            "{}:*".format(self.backend.config.prefix))
        return channels[0]

    async def wait_for_message(self, channel):
        return await channel.wait_message()

    async def get_next_message(self, channel):
        return await channel.get()

    def stop_subscriptions(self):
        self._redis_sub.close()
        self._redis_pub.close()

        if not self.backend.loop.is_closed():
            self.backend.loop.run_until_complete(
                self._redis_sub.wait_closed())
            self.backend.loop.run_until_complete(
                self._redis_pub.wait_closed())


__all__ = ("RedisSubscriber", )
