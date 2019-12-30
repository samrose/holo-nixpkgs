from functools import lru_cache
from glob import glob
from twisted.internet import reactor
from twisted.internet.defer import inlineCallbacks
import hpos_seed
import os


@lru_cache()
def runtime_dir():
    return os.getenv('RUNTIME_DIRECTORY', '.')


@lru_cache()
def state_dir():
    return os.getenv('STATE_DIRECTORY', '.')


@lru_cache()
def runtime_config_path():
    return runtime_dir() + '/hpos-config.json'


@lru_cache()
def state_config_path():
    return state_dir() + '/hpos-config.json'


@lru_cache()
def wormhole_code_path():
    return runtime_dir() + '/wormhole-code.txt'


def on_wormhole_code(wormhole_code):
    with open(wormhole_code_path(), 'w') as f:
        f.write(wormhole_code)


@inlineCallbacks
def resolve_config_path():
    paths = glob(state_config_path()) + glob('/media/*/hpos-config.json')
    if paths == []:
        config = yield hpos_seed.receive(on_wormhole_code, reactor)
        os.remove(wormhole_code_path())
        with open(state_config_path(), 'wb') as f:
            f.write(config)
        return state_config_path()
    else:
        return paths[0]


@inlineCallbacks
def hpos_init():
    try:
        if glob(runtime_config_path()) == []:
            config_path = yield resolve_config_path()
            os.symlink(config_path, runtime_config_path())
    finally:
        reactor.callLater(0, reactor.stop)


def main():
    reactor.callLater(0, hpos_init)
    reactor.run()


if __name__ == '__main__':
    main()
