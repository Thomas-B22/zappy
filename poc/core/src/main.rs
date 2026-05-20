mod manager;
mod plugin;
mod watcher;

use colored::*;
use macroquad::prelude::{Color as MQColor, *};
use manager::PluginManager;
use plugin::{CubeState, KeyEvent};
use wasmtime::{Config, Engine};

#[macroquad::main("Zappy PoC")]
async fn main() -> Result<(), anyhow::Error> {
    println!(
        "{} {}",
        "[SYSTEM]".bright_blue().bold(),
        "Starting Core...".bright_black()
    );

    let mut config = Config::new();
    config.wasm_component_model(true);
    let engine = Engine::new(&config)?;

    let mut manager = PluginManager::new(engine);

    let (reload_rx, _watcher) = watcher::setup()?;

    println!(
        "{} {}",
        "[READY]".bright_green().bold(),
        "Core. Waiting for events...".bright_black()
    );

    loop {
        clear_background(MQColor::new(0.1, 0.1, 0.12, 1.0));

        if let Ok(changed_plugin_name) = reload_rx.try_recv() {
            std::thread::sleep(std::time::Duration::from_millis(50));
            manager.reload_plugin(&changed_plugin_name);
        }

        if let Some(key) = get_last_key_pressed() {
            let event = KeyEvent::Pressed(format!("{key:?}"));
            manager.handle_inputs(event);
        }

        let state = CubeState {
            time: get_time() as f32,
        };
        manager.update_and_render(state);

        next_frame().await;
    }
}
