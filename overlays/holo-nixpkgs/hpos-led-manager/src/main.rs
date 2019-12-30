use aorura::*;
use docopt::Docopt;
use failure::*;
use serde::*;

use std::env;
use std::fs;
use std::path::PathBuf;
use std::thread::sleep;
use std::time::Duration;

const POLLING_INTERVAL: u64 = 1;

const USAGE: &'static str = "
Usage: hpos-led-manager --device <path> --state <path>
       hpos-led-manager --help

Manages AORURA LED.

Options:
  --device <path>  Path to AORURA device
  --state <path>   Path to state JSON file
";

#[derive(Debug, Deserialize)]
struct Args {
    flag_device: PathBuf,
    flag_state: PathBuf,
}

fn main() -> Fallible<()> {
    let args: Args = Docopt::new(USAGE)?
        .argv(env::args())
        .deserialize()
        .unwrap_or_else(|e| e.exit());

    let mut led = Led::open(&args.flag_device)?;

    let state_path = args.flag_state;
    let state_temp_path = state_path.with_extension("tmp");

    loop {
        let state = State::Aurora;
        led.set(state)?;

        fs::write(&state_temp_path, serde_json::to_vec(&state)?)?;
        fs::rename(&state_temp_path, &state_path)?;

        sleep(Duration::new(POLLING_INTERVAL, 0));
    }
}
