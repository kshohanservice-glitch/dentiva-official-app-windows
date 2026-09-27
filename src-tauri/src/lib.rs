mod commands;
mod db;
mod error;
mod security;

use db::Database;
use security::SessionStore;

pub struct AppState { db: Database, sessions: SessionStore }

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .plugin(tauri_plugin_dialog::init())
        .plugin(tauri_plugin_fs::init())
        .plugin(tauri_plugin_shell::init())
        .setup(|app| {
            let data_dir = app.path().app_local_data_dir().map_err(|error| error.to_string())?;
            let database = Database::initialize(data_dir.join("data").join("dentiva.sqlite3")).map_err(|error| error.to_string())?;
            app.manage(AppState { db: database, sessions: SessionStore::default() });
            Ok(())
        })
        .invoke_handler(tauri::generate_handler![commands::bootstrap_status, commands::submit_activation, commands::complete_setup])
        .run(tauri::generate_context!())
        .expect("Dentiva Pro failed to start");
}
