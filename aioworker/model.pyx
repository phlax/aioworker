# -*- coding: utf-8 -*-

from marshmallow import Schema, fields, post_load
import rapidjson as json


class GlobalConfig(Schema):
    verbosity = fields.Integer(default=0)
    timeout = fields.Integer(default=10)
    debug = fields.Boolean(default=False)


cdef class Config(object):

    def __init__(self, **kwargs):
        self.kwargs = kwargs
        print(self.kwargs)

    def __getattribute__(self, k):
        try:
            return object.__getattribute__(self, "kwargs")[k]
        except KeyError:
            return object.__getattribute__(self, k)

    @property
    def app_config(self):
        with open(self.config_file, 'r') as f:
            app_config = json.load(f)
        app_config["app_type"] = self.console_type
        return app_config

    @property
    def application_import(self):
        return str(self.worker or self.agent)

    @property
    def console_type(self):
        return (
            "worker"
            if self.worker
            else "agent")

    @property
    def is_worker(self):
        return self.console_type == "worker"


class ConfigSchema(Schema):
    verbosity = fields.Boolean(default=False, allow_none=True)
    log_level = fields.Integer(default=0, allow_none=True)
    timeout = fields.Integer(default=10)
    debug = fields.Boolean(default=False)
    worker = fields.Str(required=False, allow_none=True, default=None)
    concurrency = fields.Integer(default=4, allow_none=True)
    agent = fields.Str(default="", allow_none=True)
    broker = fields.Str(required=True)
    config_file = fields.Str(allow_none=True)
    prefix = fields.Str(default="aioworker")
    backend = fields.Str(
        allow_none=True,
        default="aioworker.backends.RedisBackend")

    @post_load
    def make_config(self, data):
        return Config(**self.dump(data))


__all__ = ("Config", "ConfigSchema")
