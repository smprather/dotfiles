"""
Minimal typing_extensions stub for Python < 3.8.
Provides Literal, Final, Protocol, runtime_checkable used by rich 12.x.
On Python >= 3.8 these are imported from typing directly; this file is
only reached on Python 3.6/3.7 via the sys.path insertion in install.
"""


class _SubscriptMeta(type):
    """Metaclass that makes a class subscriptable (Literal[...], Final[...])."""
    def __getitem__(cls, item):
        return cls


class Literal(metaclass=_SubscriptMeta):
    """No-op Literal for type annotations only."""


class Final(metaclass=_SubscriptMeta):
    """No-op Final for type annotations only."""


class _ProtocolMeta(_SubscriptMeta):
    """
    Metaclass for Protocol that provides structural isinstance() checking.
    Collects callable members defined in each Protocol subclass and checks
    for their presence on the tested instance.
    """
    def __instancecheck__(cls, instance):
        proto_methods = cls.__dict__.get("_protocol_methods")
        if proto_methods is None:
            return type.__instancecheck__(cls, instance)
        for attr in proto_methods:
            if not hasattr(instance, attr):
                return False
        return True


class Protocol(metaclass=_ProtocolMeta):
    """Minimal Protocol base class with structural isinstance() support."""
    _protocol_methods = ()

    def __init_subclass__(cls, **kwargs):
        super(Protocol, cls).__init_subclass__(**kwargs)
        cls._protocol_methods = tuple(
            name for name, val in cls.__dict__.items()
            if callable(val) and name not in (
                "__init_subclass__", "__subclasshook__",
                "__class_getitem__", "__getitem__",
                "__init__", "__new__",
            )
        )


def runtime_checkable(cls):
    """Identity decorator — Protocol metaclass handles isinstance() already."""
    return cls
