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


def get_config_path():
    return os.getenv('HPOS_CONFIG_PATH')


def get_config_data():
    with open(get_config_path(), 'r') as f:
        return json.loads(f.read())


def stringify(data, pretty=None):
    if pretty:
        return json.dumps(data, sort_keys=True, indent=2)
    return json.dumps(data, sort_keys=True, separators=(',', ':'))


def body_hash(data):
    """Return base-64 encoded SHA-512 Digest of any bytes, str or object supplied (default to JSON
    serialization compatible with `stringify`, and Javascript `@fast-json-stable-stringify`) .
    We'll always return both the serialized data we produced the hash from, and the hash.
    """
    if not isinstance(data, (bytes, str)):
        data = stringify(data)
    if not isinstance(data, bytes):
        data = data.encode()
    return data.decode(), b64encode(sha512(data).digest()).decode()


@app.route('/api/v1/config', methods=['GET'])
def get_config():
    """Returns the current config.v1.settings data, and its X-Hpos-Auth-CAS, which can (if the client
    desires) be used as a header in future PUT /api/v1/config calls to ensure that multiple calls do
    not overwrite an already-updated version of the hpos-config.json.  Alternatively, the client can
    compute the hash of the returned payload body themselves, or can use Javascript
    `@fast-json-stable-stringify` to produce a compatible serialization to hash.

    """
    data, data_hash = body_hash(get_config_data()['v1']['settings'])
    return data, 200, { 'X-Hpos-Admin-CAS': data_hash }


def replace_file_contents(path, body):
    """Replace the current hpos-config.json body (assumed to be a UTF-8 encoded string) atomically.
    This will seek out the underlying file by following any symlinks, create a temp file in the same
    directory to write `body` to (with correct permissions), and atomically swap the file into
    place.  We are required to clean up after mkstemp in all cases.

    """
    tmp_path = None, None
    try:
        if os.path.islink(path):
            path = os.readlink(path)
        # The returned fd has been opened w/ an encoding="UTF-8", and we'll close it here; it must
        # be readable to all, but since it's already open, do so manually.
        fd, tmp_path = mkstemp(dir=os.path.dirname(path))
        with open(fd, 'w') as f:
            f.write(body)
        os.chmod(tmp_path, stat.S_IRWXU | stat.S_IRGRP | stat.S_IROTH)
        os.rename(tmp_path, path)
    except Exception as exc:
        raise Exception(f"Failed to atomically updated {path} to: {body}: {exc}")
    finally:
        if tmp_path and os.path.exists(tmp_path):
            os.remove(tmp_path)

def check_config_update(cas, config, settings):
    """Validates a proposed update to the supplied config.v1.settings.  Note that the X-Hpos-Auth-CAS
    covers only the config.v1.settings subset of the config file.  However, we validate the entire
    config's schema.

    """
    # Ensure that the current config's CAS matches the one supplied
    _, current_cas = body_hash(config['v1']['settings'])
    assert current_cas == cas, \
        "X-Hpos-Admin-CAS: {cas} header did not match current config CAS {current_cas}"

    # Replace *only* the supplied config.v1.settings (taking care not to mutate original config).
    # We do *not* have knowledge of what else may be in the config; only that .v1.settings exists!
    update = config.copy()
    update['v1'] = config['v1'].copy()
    update['v1']['settings'] = settings

    # Ensure JSON schema of config + updated settings is provisionally valid; may raise Exception
    check_config(update)
    return update


@app.route('/api/v1/config', methods=['PUT'])
def put_settings():
    """Update current config.v1.settings if x-body-hash auth validated, and then return current settings and CAS"""
    try:
        # Ensure the supplied X-Body-Hash auth'ed (signed by the Admin) actually matches the supplied body.
        data, data_hash = body_hash(request.get_data())
        x_body_hash = request.headers.get('x-body-hash')
        assert data_hash == x_body_hash, \
            f"X-Body-Hash {x_body_hash} header used for authorization didn't match hash {data_hash} of body: {data}"

        # Ensure that the current config's CAS matches the one supplied, within the lock to
        # serialize; we must get current, check CAS and update atomically.
        with state_lock:
            admin_cas = request.headers.get('x-hpos-admin-cas')
            update = check_config_update(cas=admin_cas, config=get_config_data(), settings=json.loads(data))
            replace_file_contents(get_config_path(), stringify(update, pretty=True))
    except Exception as exc:
        msg = f"Failed to update HPOS config: {exc}"
        log.warning(msg)
        return msg, 409

    rebuild(priority=5)
    return get_config() # Admin UI may opt to use current state returned by PUT


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
