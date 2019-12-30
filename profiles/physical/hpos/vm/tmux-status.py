from pathlib import Path
import json
import sys

def aorura_tmux_color(color):
    return {'orange': 'colour166',
            'purple': 'colour63'}.get(color, color)


def aorura_color_indicator(color):
    return '#[fg={}]███#[default]'.format(aorura_tmux_color(color))


def aorura_state_indicator(state):
    if state == 'aurora':
        return aorura_color_indicator('cyan')
    elif state.get('flash', None):
        return '#[blink]' + aorura_color_indicator(state['flash'])
    elif state == 'off':
        return aorura_color_indicator('white')
    elif state.get('static', None):
        return aorura_color_indicator(state['static'])


WORMHOLE_CODE_PATH = Path('/run/hpos-init/wormhole-code.txt')


def tmux_status(aorura_state):
    status = [aorura_state_indicator(aorura_state)]
    if WORMHOLE_CODE_PATH.is_file():
        status.insert(0, 'Wormhole code: ' + WORMHOLE_CODE_PATH.read_text())
    return ' '.join(status)


def main():
    sys.stdout.write(tmux_status(json.load(sys.stdin)))


if __name__ == '__main__':
    main()
