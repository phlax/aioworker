# distutils: define_macros=CYTHON_TRACE_NOGIL=1
# cython: linetrace=True
# cython: binding=True

import asyncio
import functools
import logging
import uuid
from collections import defaultdict
from typing import Union

from .utils cimport pack_task, unpack
from .tasks cimport task

log = logging.getLogger("aioworker")


cdef class Subscriber(object):

    def __init__(self, backend):
        self.backend = backend
        self.running_tasks = dict()
        self.topics_subscribers = defaultdict(set)
        self.subscriber_ready = asyncio.Event(loop=self.backend.loop)

    cpdef _make_tasks_done_subscriber(self, task_id, future):
        tasks_done = self.running_tasks.pop(task_id)
        log.debug("Task '{}' done".format(tasks_done))

    async def push_task(self, str task_id, task task, *args, **kwargs) -> Union[str, None]:
        await self.backend.subscriber._redis_pub.lpush(
            self.backend.task_event,
            pack_task(
                task_id,
                task.name,
                args,
                kwargs))
        return (
            await self.listen_for_response(task_id)
            if task.returns
            else None)

    async def listen_for_response(self, task_id):
        channels = await self._redis_sub.psubscribe(
            "%s:%s" % (self.backend.config.prefix, task_id))
        channel = channels[0]
        await channel.wait_message()
        response = await channel.get()
        # this needs to handle NOT_DONE_YET, and remove the subscriber
        return unpack(response[1]).get('result')

    async def start(self):
        # Mark ready as OK
        self.subscriber_ready.set()

        channel = await self.register_topics()

        while await self.wait_for_message(channel):
            raw = await self.get_next_message(channel)
            if hasattr(raw, "__iter__") and len(raw) != 2:
                log.error("Invalid data from Redis subscriber. It must be a "
                          "tuple with len 2")

            ch, data = raw

            if hasattr(ch, 'decode'):
                ch = ch.decode()

            # Get topic
            try:
                prefix, topic = ch.split(":", maxsplit=1)
            except ValueError:
                log.error("Invalid channel name: {}".format(ch))
                continue

            # Check prefix
            if prefix != self.backend.config.prefix:
                log.error("Invalid prefix: {}".format(prefix))
                continue

            if hasattr(data, "encode"):
                data = data.encode()

            msg = unpack(data)
            data_topic = msg.get("topic", False)
            data_content = msg.get("data", False)

            if not data_topic or not data_content:
                log.error("Invalid data topic / data content - topic: {} / "
                          "data: {}".format(data_topic, data_content))
                continue

            for fn in self.topics_subscribers.get(topic, tuple()):
                # Build stop task
                task_id = uuid.uuid4().hex
                done_fn = functools.partial(
                    self._make_tasks_done_subscriber, task_id)

                task = self.backend.loop.create_task(
                    fn(data_topic,
                       data_content))

                log.debug("Launching task '{}' for topic '{}'".format(
                    fn.__name__,
                    data_topic
                ))

                task.add_done_callback(done_fn)

                self.running_tasks[task_id] = task

    def stop_subscriptions(self):  # pragma: no cover
        pass

    def subscribe(self, topics=None):

        if not topics:
            topics = set()

        if isinstance(topics, str):
            topics = {topics}

        def real_decorator(f):
            # if function is a coro, add some new functions
            if asyncio.iscoroutinefunction(f):
                if not topics:
                    log.error("Empty topic fount in function '{}'. Skipping "
                              "it.".format(f.__name__))
                for topic in topics:
                    self.topics_subscribers[topic].add(f)
            return f

        return real_decorator

    async def wait_for_message(self, channel):
        pass

    async def get_next_message(self, channel) -> object:
        pass

    async def register_topics(self):
        pass

    async def publish(self, topic, info):
        pass

    async def has_pending_topics(self):
        pass
