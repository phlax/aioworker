
import asyncio
from unittest.mock import patch, MagicMock

import uvloop

import pytest

from aioworker.app import App
from aioworker.console import Py__Console as Console
from aioworker.model import Config, ConfigSchema
from aioworker.worker import Py__Worker as Worker


class _MockWorker(Worker):
    pass


def MockWorker(broker="BROKER", **kwargs):
    return _MockWorker(Config(broker=broker, **kwargs))


def test_console_signature():

    with pytest.raises(TypeError):
        Console()


@patch('aioworker.console.Py__Console.configure')
def test_console(configure_m):
    console = Console({"config": "CONFIG"}, foo=7, bar=23)
    assert configure_m.call_args_list == [()]
    assert console.kwargs == {'bar': 23, 'foo': 7}
    assert console.shared_config == {"config": "CONFIG"}


def test_console_configure():
    with patch('aioworker.console.Py__Console.configure'):
        console = Console({})
    worker = MockWorker()
    app = App(worker, {})
    config = Config()
    schema = ConfigSchema()
    order = []

    def _setup_loop():
        order.append("loop")
        return asyncio.get_event_loop()

    def _get_worker():
        order.append("worker")
        return worker

    def _make_config():
        order.append("config")
        return config

    def _get_app():
        order.append("application")
        return app

    def _get_schema():
        order.append("schema")
        return schema

    console.setup_loop = MagicMock(side_effect=_setup_loop)
    console.make_config = MagicMock(side_effect=_make_config)
    console.set_logging = MagicMock(
        side_effect=lambda: order.append("logging"))
    console.get_worker = MagicMock(side_effect=_get_worker)
    console.get_application = MagicMock(side_effect=_get_app)
    console.get_schema = MagicMock(side_effect=_get_schema)
    console.configure()
    assert (
        order
        == ['loop', 'schema', 'config', 'logging',
            'worker', 'application'])
    mocks = dict(
        loop=console.setup_loop,
        config=console.make_config,
        worker=console.get_worker,
        application=console.get_application,
        schema=console.get_schema)
    for target, mock in mocks.items():
        assert (
            [c[0] for c in mock.call_args_list]
            == [()])
        print(target)
        assert getattr(console, target) == mock.side_effect()
    assert (
        [c[0] for c in console.set_logging.call_args_list]
        == [()])


@patch('aioworker.console.Py__Console.configure')
def test_console_loop_policy(configure_m):
    assert isinstance(Console({}).loop_policy, uvloop.EventLoopPolicy)


@patch('aioworker.console.Py__Console.configure')
def test_console_make_config(configure_m):
    console = Console({})
    console.kwargs = dict(baz=117)
    console.shared_config = dict(foo=7, bar=23)
    console.schema = MagicMock()
    console.schema.load.return_value = Config()
    result = console.make_config()
    assert result == console.schema.load.return_value
    assert (
        [c[0] for c in console.schema.load.call_args_list]
        == [({'foo': 7, 'bar': 23, 'baz': 117},)])


@patch('aioworker.console.Py__Console.configure')
def test_console_run(configure_m):
    console = Console({})
    console.add_signal_handlers = MagicMock()
    config = Config(
        broker="CONFIGURED_BROKER",
        worker=None,
        concurrency=None)
    worker = MockWorker()
    app = App(worker, {})
    worker.load = MagicMock()
    worker.start = MagicMock()
    console.application = app
    console.config = config
    console.worker = worker
    console.loop = MagicMock()

    console.run()
    assert (
        [c[0] for c
         in console.add_signal_handlers.call_args_list]
        == [()])
    assert (
        [c[0] for c in worker.load.call_args_list]
        == [(app, )])
    assert (
        [c[0] for c in worker.start.call_args_list]
        == [()])
    assert (
        [c[0] for c
         in console.loop.run_until_complete.call_args_list]
        == [(worker.start.return_value, )])
    assert (
        [c[0] for c
         in console.loop.run_forever.call_args_list]
        == [()])


@patch('aioworker.console.Py__Console.configure')
@patch('aioworker.console.asyncio')
@patch('aioworker.console.uvloop')
def test_console_should_setup_loop(uv_m, asyncio_m, configure_m):
    console = Console({})
    console.should_set_loop_policy = MagicMock(return_value=True)
    loop = console.setup_loop()
    assert loop is asyncio_m.get_event_loop.return_value
    assert (
        [c[0] for c
         in console.should_set_loop_policy.call_args_list]
        == [()])
    assert (
        [c[0] for c
         in asyncio_m.set_event_loop_policy.call_args_list]
        == [(console.loop_policy, )])

    console.should_set_loop_policy.reset_mock()
    console.should_set_loop_policy.return_value = False
    uv_m.reset_mock()
    loop = console.setup_loop()
    assert loop is asyncio_m.get_event_loop.return_value
    assert not uv_m.set_event_loop_policy.called


@patch('aioworker.console.Py__Console.configure')
@patch('aioworker.console.Py__Console.make_summary')
def test_console_on_start(summary_m, configure_m, capsys):
    console = Console({})
    summary_m.return_value = "STARTED"
    console._on_start()
    assert (
        [c[0] for c in summary_m.call_args_list]
        == [()])
    assert capsys.readouterr().out.strip() == "STARTED"


@patch('aioworker.console.Py__Console.configure')
def test_console_get_schema(configure_m):
    console = Console({})
    assert isinstance(
        console.get_schema(), ConfigSchema)


@patch('aioworker.console.Py__Console.configure')
def test_console_get_application(configure_m):
    worker = MockWorker()
    imported_app = MagicMock(return_value=App({}))

    class MockConsole(Console):

        @property
        def imported_app(self):
            return imported_app

    console = MockConsole({})
    console.worker = worker
    console.config = Config(app_config="APP_CONFIG")
    console.get_application()
    assert (
        [c[0] for c in console.imported_app.call_args_list]
        == [(worker, 'APP_CONFIG')])
