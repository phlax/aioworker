
import asyncio
from unittest.mock import patch, MagicMock

import pytest

from aioworker import App, Config, task
from aioworker.worker import Py__Worker as Worker

from .base import AsyncMock


class _MockWorker(Worker):
    pass


def MockWorker(broker="BROKER", **kwargs):
    return _MockWorker(Config(broker=broker, **kwargs))


def test_worker_signature():

    with pytest.raises(TypeError):
        Worker()


@patch('aioworker.worker.Py__Worker.configure')
def test_worker(configure_m):
    worker = MockWorker()

    assert (
        [c[0] for c in configure_m.call_args_list]
        == [()])

    assert worker.loop is asyncio.get_event_loop()
    assert worker.prefix == "aioworker"


@patch('aioworker.worker.Py__Worker.configure')
def test_worker_kwargs(configure_m):
    worker = Worker(Config(broker="BROKER"), loop="LOOP", prefix="PREFIX")

    assert (
        [c[0] for c in configure_m.call_args_list]
        == [()])

    assert worker.loop == "LOOP"
    assert worker.prefix == "PREFIX"


@patch('aioworker.worker.Py__Worker.configure')
def test_worker_start(configure_m, mocker):
    worker = MockWorker()
    worker.backend = mocker.MagicMock()
    response = worker.start()
    assert (
        response
        == worker.backend.start.return_value)
    assert (
        [c[0] for c in worker.backend.start.call_args_list]
        == [()])


@patch('aioworker.worker.Py__Worker.configure')
def test_worker_stop(configure_m, mocker):
    worker = MockWorker()
    worker.backend = mocker.MagicMock()
    response = worker.stop()
    assert (
        response
        == worker.backend.stop.return_value)
    assert (
        [c[0] for c in worker.backend.stop.call_args_list]
        == [()])


@patch('aioworker.worker.Py__Worker.configure')
def test_worker_load(configure_m, mocker):
    worker = MockWorker()
    worker.get_backend = mocker.MagicMock()
    app = App({})
    worker.load(app)
    assert worker.backend == worker.get_backend.return_value
    assert (
        [c[0] for c in worker.get_backend.call_args_list]
        == [(app, )])


@pytest.mark.asyncio
async def test_worker_call():
    with patch('aioworker.worker.Py__Worker.configure'):
        worker = MockWorker()
        worker.backend = MagicMock()
        worker.backend.push_task = AsyncMock()
        _task = task(lambda: "done")
        await worker.call(_task, "arg1", "arg2", dict(arg3="foo"))
        assert (
            [c[0] for c in worker.backend.push_task.call_args_list]
            == [(_task, ('arg1', 'arg2', {'arg3': 'foo'}), {})])
