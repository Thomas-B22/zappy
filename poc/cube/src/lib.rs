wit_bindgen::generate!({
    path: "../wit",
    world: "plugin-world",
});

use std::sync::Mutex;
static OFFSETS: Mutex<(f32, f32)> = Mutex::new((0.0, 0.0));

struct Plugin;

impl Guest for Plugin {
    fn handle_input(event: KeyEvent) -> bool {
        if let KeyEvent::Pressed(key) = event {
            let mut offsets = OFFSETS.lock().unwrap();
            match key.as_str() {
                "Left" => {
                    offsets.0 -= 10.0;
                    true
                }
                "Right" => {
                    offsets.0 += 10.0;
                    true
                }
                "Up" => {
                    offsets.1 -= 10.0;
                    true
                }
                "Down" => {
                    offsets.1 += 10.0;
                    true
                }
                _ => false,
            }
        } else {
            false
        }
    }

    fn update_cube(state: CubeState) -> RenderCommand {
        let offsets = OFFSETS.lock().unwrap();
        let speed = 2.0;
        let angle = state.time * speed;

        RenderCommand {
            x: angle.cos() * 100.0 + offsets.0,
            y: angle.sin() * 100.0 + offsets.1,
            rotation: angle,
        }
    }
}

export!(Plugin);
