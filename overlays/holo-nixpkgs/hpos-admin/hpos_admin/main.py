from base64 import b64encode
from flask import Flask, jsonify, request
from gevent import subprocess, pywsgi, queue, socket, spawn, lock
from hashlib import sha512
from tempfile import mkstemp
import json
import logging
import os

from hpos_config.schema import check_config

app = Flask(__name__)
log = logging.getLogger(__name__)
rebuild_queue = queue.PriorityQueue()
state_lock = lock.Semaphore()


def rebuild_worker():
    while True:
        (_, cmd) = rebuild_queue.get()
        rebuild_queue.queue.clear()
        subprocess.run(cmd)


def rebuild(priority, args):
    rebuild_queue.put((priority, ['sudo', 'nixos-rebuild', 'switch'] + args))


def get_state_path():
    return os.getenv('HPOS_CONFIG_PATH')


def get_state_data():
    with open(get_state_path(), 'r') as f:
        return json.loads(f.read())


def cas_hash(data):
    dump = json.dumps(data, separators=(',', ':'), sort_keys=True)
    return b64encode(sha512(dump.encode()).digest()).decode()


@app.route('/v1/config', methods=['GET'])
def get_settings():
    return jsonify(get_state_data()['v1']['settings'])


def replace_file_contents(path, data):
    fd, tmp_path = mkstemp(dir=os.path.dirname(path))
    with open(fd, 'w') as f:
        f.write(data)
    os.rename(tmp_path, path)


def update_settings(cas, config, settings):
    assert cas == cas_hash(config['v1']['settings']), \
        "x-hpos-admin-cas header did not match current config settings hash"
    config['v1']['settings'] = settings
    check_config(config)
    return config

    
@app.route('/v1/config', methods=['PUT'])
def put_settings():
    try:
        with state_lock:
            cas = request.headers.get('x-hpos-admin-cas')
            settings = request.get_json(force=True)
            state = update_settings(cas, get_state_data(), settings)
            replace_file_contents(get_state_path(), json.dumps(state, indent=2))
    except Exception as exc:
        log.warning(f"Failed to update HPOS config settings: {exc}")
        return '', 409

    rebuild(priority=5, args=[])
    return '', 200


def zerotier_info():
    proc = subprocess.run(['sudo', 'zerotier-cli', '-j', 'info'],
                          capture_output=True, check=True)
    return json.loads(proc.stdout)


@app.route('/v1/status', methods=['GET'])
def status():
    return jsonify({
        'zerotier': zerotier_info()
    })


@app.route('/v1/upgrade', methods=['POST'])
def upgrade():
    rebuild(priority=1, args=['--upgrade'])
    return '', 200


def unix_socket(path):
    sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    if os.path.exists(path):
        os.remove(path)
    sock.bind(path)
    sock.listen()
    return sock


def main():
    spawn(rebuild_worker)
    pywsgi.WSGIServer(unix_socket('/run/hpos-admin.sock'), app).serve_forever()


if __name__ == '__main__':
    main()
