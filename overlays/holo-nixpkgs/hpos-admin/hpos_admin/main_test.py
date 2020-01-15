import pytest
import json

from hpos_admin.main import body_hash, check_config_update
from hpos_config.schema_test import config_json

_, config_cas = body_hash(json.loads(config_json)['v1']['settings'])

def test_cas():
    assert config_cas == "KkrCSBphJighnRPEnJE9FmM8DiGKW4Jc5L9DjJ1KNroZ8ySt/Aw+BptpGimd78navA+7NUhoA9U/Z4Tsh/m4Lw=="

def test_schema():
    settings = {
        'admin': {
            'email': "a@b.ca",
            'public_key': 'xyz=='
        }
    }
    settings_bad = {
        'admin': {
            'email': "a<at>b.ca",
            'public_key': 'xyz=='
        }
    }
    with pytest.raises(AssertionError, match='.*X-Hpos-Admin-CAS:.* header did not match.*') as exc_info:
        check_config_update(cas="abc==", config=json.loads(config_json), settings=settings)
    config_updated = check_config_update(cas=config_cas, config=json.loads(config_json), settings=settings)
    assert config_updated['v1']['settings'] == settings
    with pytest.raises(AssertionError, match='.*Expected.*email to satisfy predicate is_email.*') as exc_info:
        check_config_update(cas=config_cas, config=json.loads(config_json), settings=settings_bad)
