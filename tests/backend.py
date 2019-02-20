
import asyncio

from unittest.mock import (
    patch, MagicMock, PropertyMock)

import pytest

from aioworker import (
    App, Backend, Config, Job,
    Runner, Subscriber, Worker, task)
from aioworker.backend import Py__Backend as Backend

from .base import AsyncMock


def test_backend_signature():

    with pytest.raises(TypeError):
        Backend()


class _MockSubscriber(Subscriber):

    def __init__(self, backend, **kwargs):
        self.publish = MagicMock()
        self.push_task = MagicMock()
        self.start = MagicMock()


def MockSubscriber(backend, **kwargs):
    return _MockSubscriber(backend, **kwargs)


class _MockRunner(Runner):

    def __init__(self, backend, **kwargs):
        self.start = MagicMock()


def MockRunner(backend, **kwargs):
    return _MockRunner(backend, **kwargs)


class _MockWorker(Worker):
    pass


def MockWorker(broker="BROKER", **kwargs):
    return _MockWorker(
        Config(
            worker=True,
            concurrency=23,
            broker=broker,
            prefix="PREFIX",
            **kwargs))


class _MockApp(App):

    def __init__(self, **kwargs):
        self.start = MagicMock()
        self.on_start = AsyncMock()


def MockApp(**kwargs):
    return _MockApp(**kwargs)



@patch('aioworker.backend.Py__Backend.connect')
def test_backend(connect_m):
    worker = MockWorker()
    worker.loop = 23
    app = App()
    backend = Backend(worker, app)
    assert backend.worker is worker
    assert backend.app is app
    assert backend.config is worker.config
    assert backend.loop is worker.loop
    assert (
        [c[0] for c in connect_m.call_args_list]
        == [()])


@patch('aioworker.backend.Py__Backend.connect')
def test_backend_get_task_event(connect_m):
    worker = MockWorker()
    app = App()
    backend = Backend(worker, app)
    event = backend.get_task_event()
    assert event == "PREFIX:tasks"


@patch('aioworker.backend.Py__Backend.connect')
def test_backend_publish(connect_m):
    worker = MockWorker()
    app = App()
    backend = Backend(worker, app)
    backend.subscriber = MockSubscriber(backend)
    response = backend.publish("CHANNEL", dict(foo=23))
    assert (
        [c[0] for c in backend.subscriber.publish.call_args_list]
        == [('CHANNEL', {'foo': 23})])
    assert response == backend.subscriber.publish.return_value


@patch('aioworker.backend.uuid')
@patch('aioworker.backend.Py__Backend.connect')
def test_backend_push_task(connect_m, uuid_m):
    worker = MockWorker()
    app = App()
    backend = Backend(worker, app)
    backend.subscriber = MockSubscriber(backend)
    _task = task(lambda: "done")
    response = backend.push_task(_task, ("foo", "bar"), dict(baz=23))
    assert (
        [c[0] for c in backend.subscriber.push_task.call_args_list]
        == [(uuid_m.uuid4.return_value.hex,
             _task,
             'foo', 'bar')])
    assert (
        [c[1] for c in backend.subscriber.push_task.call_args_list]
        == [{'baz': 23}])
    assert response == backend.subscriber.push_task.return_value
    assert [c[0] for c in uuid_m.uuid4.call_args_list] == [()]


@pytest.mark.asyncio
async def test_backend_start():
    worker = MockWorker()
    app = MockApp()

    with patch('aioworker.backend.Py__Backend.connect'):
        backend = Backend(worker, app)
    backend.loop = MagicMock()
    backend.subscriber = MockSubscriber(backend)
    backend.runner = MockRunner(backend)

    await backend.start()
    assert [c[0] for c in app.on_start.call_args_list] == [()]
    assert [c[0] for c in backend.runner.start.call_args_list] == [()]
    assert [c[0] for c in backend.subscriber.start.call_args_list] == [()]
    assert (
        [c[0] for c in backend.loop.create_task.call_args_list]
        == [(backend.runner.start.return_value, ),
            (backend.subscriber.start.return_value, )])

    app.on_start.reset_mock()
    backend.runner.start.reset_mock()
    backend.subscriber.start.reset_mock()
    backend.loop.create_task.reset_mock()
    backend.config.kwargs["worker"] = False

    await backend.start()
    assert [c[0] for c in app.on_start.call_args_list] == [()]
    assert [c[0] for c in backend.runner.start.call_args_list] == []
    assert [c[0] for c in backend.subscriber.start.call_args_list] == [()]
    assert (
        [c[0] for c in backend.loop.create_task.call_args_list]
        == [(backend.subscriber.start.return_value, )])


def test_backend_connect():
    worker = MockWorker()
    app = MockApp()

    with patch('aioworker.backend.Py__Backend.connect'):
        backend = Backend(worker, app)

    with patch('aioworker.backend.Py__Backend.get_task_event') as task_m:
        with patch('aioworker.backend.Py__Backend.get_subscriber') as subscriber_m:
            with patch('aioworker.backend.Py__Backend.get_runner') as runner_m:
                task_m.return_value = "TASK"
                subscriber_m.return_value = MockSubscriber(backend)
                runner_m.return_value = MockRunner(backend)
                backend.connect()
                assert [c[0] for c in task_m.call_args_list] == [()]
                assert [c[0] for c in subscriber_m.call_args_list] == [()]
                assert [c[0] for c in runner_m.call_args_list] == [()]

    backend.config.kwargs["worker"] = False
    with patch('aioworker.backend.Py__Backend.get_task_event') as task_m:
        with patch('aioworker.backend.Py__Backend.get_subscriber') as subscriber_m:
            with patch('aioworker.backend.Py__Backend.get_runner') as runner_m:
                task_m.return_value = "TASK"
                subscriber_m.return_value = MockSubscriber(backend)
                runner_m.return_value = MockRunner(backend)
                backend.connect()
                assert [c[0] for c in task_m.call_args_list] == [()]
                assert [c[0] for c in subscriber_m.call_args_list] == [()]
                assert [c[0] for c in runner_m.call_args_list] == []
