from functools import lru_cache
import json
import logging
import os
import requests
import subprocess
import time


HOLO_AUTH_URL = "https://holoport-authorizer.holo.host/v1/auth"


@lru_cache()
def config_path():
    return os.getenv('HPOS_CONFIG_PATH')


@lru_cache()
def config():
    with open(config_path()) as f:
        return json.load(f)


def admin_email():
    return config()['v1']['settings']['admin']['email']


def agent_id():
    with open(config_path()) as f:
        proc = subprocess.run(['hpos-config-into-base36-id'],
                              capture_output=True, stdin=f)
        return proc.stdout.decode('utf-8').rstrip()


def confirm_email(email, zerotier_address):
    return requests.post(HOLO_AUTH_URL, json={
        'addr': zerotier_address,
        'email': email,
        'pubkey': agent_id()
    })


def zerotier_address():
    proc = subprocess.run(["zerotier-cli", "-j", "info"], capture_output=True)
    return json.loads(proc.stdout)['address']


def zerotier_status():
    proc = subprocess.run(["zerotier-cli", "-j", "listnetworks"], capture_output=True)
    return json.loads(proc.stdout)[0]['status']


def main():
    while zerotier_status() == 'REQUESTING_CONFIGURATION':
        time.sleep(1)
    if zerotier_status() == 'ACCESS_DENIED':
        logging.debug(confirm_email(admin_email(), zerotier_address()))


if __name__ == "__main__":
    main()
