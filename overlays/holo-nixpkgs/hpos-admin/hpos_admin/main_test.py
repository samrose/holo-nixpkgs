import pytest
import json

from hpos_admin.main import cas_hash, update_settings
from hpos_config.schema_test import config_json

config = json.loads(config_json)
config_cas = cas_hash(config['v1']['settings'])

def test_cas():
    assert config_cas == "KkrCSBphJighnRPEnJE9FmM8DiGKW4Jc5L9DjJ1KNroZ8ySt/Aw+BptpGimd78navA+7NUhoA9U/Z4Tsh/m4Lw=="

def test_schema():
    settings = { 'admin': { 'email': "a@b.ca", 'public_key': 'xyz==' }}
    with pytest.raises(AssertionError, match='.*x-hpos-admin-cas header did not match.*') as exc_info:
        update_settings(cas="abc==", config=config, settings=settings)
    config_updated = update_settings(cas=config_cas, config=config, settings=settings)
    assert config_updated['v1']['settings'] == settings
