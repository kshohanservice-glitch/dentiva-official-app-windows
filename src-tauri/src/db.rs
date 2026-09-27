use crate::error::{AppError, AppResult};
use rusqlite::{Connection, OpenFlags};
use sha2::{Digest, Sha256};
use std::{fs, path::{Path, PathBuf}};

const INITIAL_MIGRATION: &str = include_str!("../migrations/0001_initial.sql");

#[derive(Clone)]
pub struct Database { path: PathBuf }

impl Database {
    pub fn initialize(path: PathBuf) -> AppResult<Self> {
        if let Some(parent) = path.parent() { fs::create_dir_all(parent)?; }
        let database = Self { path };
        let mut connection = database.connect()?;
        let has_migrations: bool = connection.query_row(
            "SELECT EXISTS(SELECT 1 FROM sqlite_master WHERE type='table' AND name='schema_migrations')",
            [], |row| row.get(0),
        )?;
        if !has_migrations {
            let transaction = connection.transaction()?;
            transaction.execute_batch(INITIAL_MIGRATION)?;
            let checksum = hex::encode(Sha256::digest(INITIAL_MIGRATION.as_bytes()));
            transaction.execute(
                "INSERT INTO schema_migrations(version,name,checksum,applied_at) VALUES(1,'initial',?1,?2)",
                (&checksum, chrono::Utc::now().to_rfc3339()),
            )?;
            transaction.commit()?;
        }
        Ok(database)
    }

    pub fn connect(&self) -> AppResult<Connection> {
        let connection = Connection::open_with_flags(&self.path, OpenFlags::SQLITE_OPEN_READ_WRITE | OpenFlags::SQLITE_OPEN_CREATE | OpenFlags::SQLITE_OPEN_FULL_MUTEX)?;
        connection.execute_batch("PRAGMA foreign_keys=ON; PRAGMA journal_mode=WAL; PRAGMA synchronous=FULL; PRAGMA busy_timeout=5000; PRAGMA secure_delete=ON;")?;
        Ok(connection)
    }

    pub fn path(&self) -> &Path { &self.path }

    pub fn quick_check(&self) -> AppResult<()> {
        let result: String = self.connect()?.query_row("PRAGMA quick_check", [], |row| row.get(0))?;
        if result == "ok" { Ok(()) } else { Err(AppError::Internal) }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn migration_creates_constrained_schema() {
        let dir = tempfile::tempdir().unwrap();
        let db = Database::initialize(dir.path().join("test.sqlite3")).unwrap();
        db.quick_check().unwrap();
        let conn = db.connect().unwrap();
        let count: i64 = conn.query_row("SELECT count(*) FROM sqlite_master WHERE type='table'", [], |r| r.get(0)).unwrap();
        assert!(count >= 35);
        let foreign_keys: i64 = conn.query_row("PRAGMA foreign_keys", [], |r| r.get(0)).unwrap();
        assert_eq!(foreign_keys, 1);
    }
}
