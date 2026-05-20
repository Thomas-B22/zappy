use colored::*;
use wasmtime::component::*;
use wasmtime::{Engine, Store};

wasmtime::component::bindgen!({
    path: "../wit/zappy.wit",
    world: "plugin-world",
});

pub struct PluginInstance {
    pub name: String,
    pub store: Store<()>,
    pub bindings: PluginWorld,
}

impl PluginInstance {
    pub fn load(engine: &Engine, path: &std::path::Path) -> Result<Self, anyhow::Error> {
        let name = path
            .file_stem()
            .unwrap_or_default()
            .to_string_lossy()
            .to_string();
        let component_bytes = std::fs::read(path)?;

        let component = Component::new(engine, &component_bytes)?;
        let mut store = Store::new(engine, ());
        let mut linker = Linker::new(engine);

        linker.define_unknown_imports_as_traps(&component)?;

        let bindings = PluginWorld::instantiate(&mut store, &component, &linker)?;

        println!(
            "{} {} {} {}",
            "[SYSTEM]".bright_blue().bold(),
            "Plugin".bright_black(),
            name.bright_green().italic(),
            "loaded.".bright_black()
        );
        Ok(PluginInstance {
            name,
            store,
            bindings,
        })
    }
}
