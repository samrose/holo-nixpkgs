from base64 import b64encode
from flask import Flask, jsonify, request
from gevent import subprocess, pywsgi, queue, socket, spawn, lock
from hashlib import sha512
from tempfile import mkstemp
import json
import logging
import os
import stat

from hpos_config.schema import check_config

app = Flask(__name__)
log = logging.getLogger(__name__)
rebuild_queue = queue.PriorityQueue()
state_lock = lock.Semaphore()


def rebuild_worker():
    while True:
        (_, cmd) = rebuild_queue.get()
        rebuild_queue.queue.clear()
        log.info(f"Rebuilding w/ command: {cmd}")
        subprocess.run(cmd)


def rebuild(priority, args=None):
    rebuild_queue.put((priority, ['sudo', 'nixos-rebuild', 'switch'] + (args or [])))


def get_state_path():
    return os.getenv('HPOS_CONFIG_PATH')


def get_state_data():
    with open(get_state_path(), 'r') as f:
        return json.loads(f.read())


def cas_hash(data):
    """Return base-64 encoded SHA-512 Digest of any bytes, str or object supplied"""
    if type(data) not in (bytes, str):
        data = json.dumps(data, separators=(',', ':'), sort_keys=True)
    if type(data) != bytes:
        data = data.encode()
    return b64encode(sha512(data).digest()).decode()


@app.route('/api/v1/config', methods=['GET'])
def get_settings():
    settings = get_state_data()['v1']['settings']
    return jsonify(settings), 200, { 'X-Hpos-Admin-CAS': cas_hash(settings) }


def replace_file_contents(path, data):
    """Replace the current hpos-config.json atomically.  This will seek out the underlying file by
    following any symlinks, create a temp file in the same directory to write `data` to, and
    atomically swap the file into place.
    """
    if os.path.islink(path):
        linkpath = os.readlink(path)
        log.info(f"Resolved symbolic link at {path} to underlying file at {linkpath}")
        path = linkpath
    fd, tmp_path = mkstemp(dir=os.path.dirname(path))
    with open(fd, 'w', 0o755) as f:
        f.write(data)
    os.rename(tmp_path, path)
    log.info(f"Atomically updated {path} to: {data}")


def verify_body_hash(request):
    """Header x-body-hash contains the base-64 SHA-512 hash of the body payload that was signed."""
    x_body_hash = request.headers.get('x-body-hash')
    if x_body_hash:
        body = request.get_data()
        body_hash = cas_hash(body)
        assert body_hash == x_body_hash, \
            f"x-body-hash {x_body_hash} used for authorization didn't match hash {body_hash} of body: {body}"


def update_settings(cas, config, settings):
    assert cas == cas_hash(config['v1']['settings']), \
        "X-Hpos-Admin-CAS header did not match current config settings hash"
    config['v1']['settings'] = settings
    check_config(config)
    return config


@app.route('/api/v1/config', methods=['PUT'])
def put_settings():
    """Update settings if x-body-hash auth validated, and then return current settings and CAS"""
    try:
        verify_body_hash(request)
        with state_lock:
            cas = request.headers.get('X-Hpos-Admin-CAS')
            settings = request.get_json(force=True)
            state = update_settings(cas, get_state_data(), settings)
            replace_file_contents(get_state_path(), json.dumps(state, indent=2))
    except Exception as exc:
        msg = f"Failed to update HPOS config settings: {exc}"
        log.warning(msg)
        return msg, 409

    rebuild(priority=5)
    return get_settings()


def zerotier_info():
    proc = subprocess.run(['/run/current-system/sw/bin/zerotier-cli -j info'],
                          capture_output=True, check=True, shell=True)
    return json.loads(proc.stdout)


@app.route('/api/v1/status', methods=['GET'])
def status():
    return jsonify({
        'zerotier': zerotier_info()
    })


@app.route('/api/v1/upgrade', methods=['POST'])
def upgrade():
    rebuild(priority=1, args=['--upgrade'])
    return '', 200


def unix_socket(path):
    sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    if os.path.exists(path):
        os.remove(path)
    sock.bind(path)
    sock.listen()
    os.chmod(path, stat.S_IRWXU|stat.S_IRWXG|stat.S_IRWXO) # support various services' users connecting
    return sock


def main():
    logging.basicConfig(level=logging.INFO)
    spawn(rebuild_worker)
    pywsgi.WSGIServer(unix_socket('/run/hpos-admin.sock'), app).serve_forever()


if __name__ == '__main__':
    main()
