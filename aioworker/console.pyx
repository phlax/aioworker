# distutils: define_macros=CYTHON_TRACE_NOGIL=1
# cython: linetrace=True
# cython: binding=True

import asyncio
import datetime
import logging
import os
import platform
import socket
import signal
from threading import current_thread

import uvloop

from .model import ConfigSchema
from .utils import get_log_level

from cpython cimport bool

from .app cimport App
from .model cimport Config
from .prompt cimport console_templates
from .utils cimport resolve
from .worker cimport Worker


log = logging.getLogger('aioworker')


cdef class Console(object):

    def __cinit__(self, dict config, **kwargs):
        self.shared_config = config or {}
        self.kwargs = kwargs

    def __init__(self, dict config, **kwargs):
        self.configure()

    @property
    def imported_app(self) -> type(App):
        return resolve(".".join((
            self.config.application_import,
            "app")))

    @property
    def loop_policy(self) -> asyncio.AbstractEventLoopPolicy:
        return uvloop.EventLoopPolicy()

    cpdef configure(self):
        self.loop = self.setup_loop()
        self.schema = self.get_schema()
        self.config = self.make_config()
        self.set_logging()
        self.worker = self.get_worker()
        self.application = self.get_application()

    cpdef App get_application(self):
        return self.imported_app(
            self.worker, self.config.app_config)

    cpdef get_schema(self):
        return ConfigSchema()

    cpdef Worker get_worker(self):
        return Worker(self.config)

    cpdef Config make_config(self):
        cdef dict config = self.shared_config
        config.update(self.kwargs)
        return self.schema.load(config)

    cpdef str make_summary(self):
        cdef now = datetime.datetime.now()
        cdef list display_subscriptions = []
        for topic, clients in self.worker.subscribers.items():
            display_subscriptions.append("'{}'".format(topic))
            for client in clients:
                display_subscriptions.append("   > {}".format(client.__name__))
        return console_templates[self.config.console_type].format(
            hostname=socket.gethostname(),
            version="1.0.0-a1",
            os=platform.system(),
            arch=platform.release(),
            date=now.strftime("%Y-%m-%d"),
            time=now.strftime("%H:%M:%S"),
            app_id=hex(current_thread().ident),
            concurrency=self.config.concurrency,
            tasks="-  \n".join(self.worker.tasks.keys()),
            subscriptions="\n".join(display_subscriptions))

    cpdef run(self):
        self.add_signal_handlers()
        self.worker.load(self.application)
        self.loop.run_until_complete(self.worker.start())
        self._on_start()
        self.loop.run_forever()

    cpdef set_logging(self):
        log.setLevel(get_log_level(self.config.verbosity))

    cpdef setup_loop(self):
        if self.should_set_loop_policy():
            asyncio.set_event_loop_policy(self.loop_policy)
        loop = asyncio.get_event_loop()
        loop.set_debug(True)
        # logging.basicConfig(level=logging.DEBUG)
        return loop

    cpdef bool should_set_loop_policy(self):
        # return False
        return not (
            os.getenv("AIOWORKER_DEBUG", False)
            or isinstance(
                asyncio.get_event_loop_policy(),
                type(self.loop_policy)))

    cpdef _on_start(self):
        print(self.make_summary())

    def add_signal_handlers(self) -> None:
        cdef tuple signals = (signal.SIGHUP, signal.SIGTERM, signal.SIGINT)
        for s in signals:
            self.loop.add_signal_handler(
                s, lambda s=s: self.loop.create_task(self.worker.stop()))


class Py__Console(Console):
    pass


__all__ = ("Console", "Py__Console")
