use crate::{
    db::Database,
    error::{AppError, AppResult},
};
use argon2::{
    password_hash::{rand_core::OsRng, PasswordHash, PasswordHasher, PasswordVerifier, SaltString},
    Argon2,
};
use parking_lot::RwLock;
use pbkdf2::pbkdf2_hmac;
use sha2::{Digest, Sha256};
use std::{
    collections::{HashMap, HashSet},
    time::{Duration, Instant},
};
use subtle::ConstantTimeEq;
use uuid::Uuid;
use zeroize::Zeroizing;

const ACTIVATION_SALT: [u8; 16] = [
    0xe7, 0xb4, 0x5a, 0x2c, 0xd8, 0x70, 0x1c, 0x91, 0xd8, 0x37, 0x15, 0xcc, 0x65, 0xf4, 0x07, 0x9b,
];
const ACTIVATION_DERIVED: [u8; 32] = [
    0x45, 0x63, 0x5c, 0xc3, 0x25, 0x9b, 0xed, 0x2f, 0x37, 0x83, 0x01, 0xf0, 0xc7, 0xd4, 0x32, 0x33,
    0xdf, 0xed, 0x45, 0x26, 0xed, 0x95, 0x91, 0x75, 0x21, 0xbf, 0x05, 0x51, 0x9f, 0x64, 0xff, 0xd1,
];
const ACTIVATION_ROUNDS: u32 = 310_000;

pub fn verify_activation(input: &str) -> bool {
    let input = Zeroizing::new(input.trim().as_bytes().to_vec());
    if input.len() != 16 || !input.iter().all(u8::is_ascii_digit) {
        return false;
    }
    let mut derived = Zeroizing::new([0u8; 32]);
    pbkdf2_hmac::<Sha256>(&input, &ACTIVATION_SALT, ACTIVATION_ROUNDS, &mut *derived);
    bool::from(derived.ct_eq(&ACTIVATION_DERIVED))
}

pub fn password_hash(password: &str) -> AppResult<String> {
    if password.chars().count() < 10 || password.len() > 1024 {
        return Err(AppError::Validation(
            "Password must be between 10 and 1024 bytes".into(),
        ));
    }
    let salt = SaltString::generate(&mut OsRng);
    Argon2::default()
        .hash_password(password.as_bytes(), &salt)
        .map(|h| h.to_string())
        .map_err(|_| AppError::Internal)
}

pub fn password_verify(password: &str, encoded: &str) -> bool {
    PasswordHash::new(encoded).ok().is_some_and(|hash| {
        Argon2::default()
            .verify_password(password.as_bytes(), &hash)
            .is_ok()
    })
}

#[derive(Clone)]
pub struct Session {
    pub user_id: String,
    pub clinic_id: String,
    pub permissions: HashSet<String>,
    touched: Instant,
    timeout: Duration,
}

#[derive(Default)]
pub struct SessionStore(RwLock<HashMap<String, Session>>);

impl SessionStore {
    pub fn create(
        &self,
        user_id: String,
        clinic_id: String,
        permissions: HashSet<String>,
        timeout: Duration,
    ) -> String {
        let token = Uuid::new_v4().to_string();
        self.0.write().insert(
            token.clone(),
            Session {
                user_id,
                clinic_id,
                permissions,
                touched: Instant::now(),
                timeout,
            },
        );
        token
    }
    pub fn authorize(&self, token: &str, permission: &str) -> AppResult<Session> {
        let mut sessions = self.0.write();
        let session = sessions.get_mut(token).ok_or(AppError::Unauthenticated)?;
        if session.touched.elapsed() > session.timeout {
            sessions.remove(token);
            return Err(AppError::Unauthenticated);
        }
        if !session.permissions.contains(permission) {
            return Err(AppError::Forbidden);
        }
        session.touched = Instant::now();
        Ok(session.clone())
    }
    pub fn remove(&self, token: &str) {
        self.0.write().remove(token);
    }
}

pub fn activation_is_valid(db: &Database) -> AppResult<bool> {
    let conn = db.connect()?;
    let row = conn.query_row(
        "SELECT installation_id, proof FROM activation_state WHERE id=1",
        [],
        |r| Ok((r.get::<_, String>(0)?, r.get::<_, Vec<u8>>(1)?)),
    );
    match row {
        Ok((id, proof)) => {
            let expected = Sha256::digest([id.as_bytes(), &ACTIVATION_DERIVED].concat());
            Ok(proof.ct_eq(expected.as_slice()).into())
        }
        Err(rusqlite::Error::QueryReturnedNoRows) => Ok(false),
        Err(error) => Err(error.into()),
    }
}

pub fn activate(db: &Database, input: &str) -> AppResult<()> {
    if !verify_activation(input) {
        return Err(AppError::Validation(
            "The activation code is not valid".into(),
        ));
    }
    let installation_id = Uuid::new_v4().to_string();
    let proof = Sha256::digest([installation_id.as_bytes(), &ACTIVATION_DERIVED].concat());
    db.connect()?.execute("INSERT OR REPLACE INTO activation_state(id,installation_id,activated_at,proof,version) VALUES(1,?1,?2,?3,1)", (&installation_id, chrono::Utc::now().to_rfc3339(), proof.as_slice()))?;
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn activation_rejects_bad_inputs() {
        for value in ["", "123", "abcdefghijklmnop", "0000000000000000"] {
            assert!(!verify_activation(value));
        }
    }
    #[test]
    fn password_round_trip_and_reject() {
        let hash = password_hash("A-strong-local-password").unwrap();
        assert!(password_verify("A-strong-local-password", &hash));
        assert!(!password_verify("wrong-password", &hash));
        assert!(!hash.contains("A-strong"));
    }
    #[test]
    fn permission_is_enforced() {
        let store = SessionStore::default();
        let token = store.create(
            "u".into(),
            "c".into(),
            HashSet::from(["patient.view".into()]),
            Duration::from_secs(10),
        );
        assert!(store.authorize(&token, "patient.view").is_ok());
        assert!(matches!(
            store.authorize(&token, "financial.reports"),
            Err(AppError::Forbidden)
        ));
    }
}
