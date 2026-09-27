use crate::{error::{AppError, AppResult}, security, AppState};
use serde::{Deserialize, Serialize};
use tauri::State;

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
pub struct BootstrapStatus { pub activated: bool, pub setup_complete: bool, pub database_healthy: bool, pub version: &'static str }

#[tauri::command]
pub fn bootstrap_status(state: State<'_, AppState>) -> AppResult<BootstrapStatus> {
    let activated = security::activation_is_valid(&state.db)?;
    let conn = state.db.connect()?;
    let setup_complete: bool = conn.query_row("SELECT EXISTS(SELECT 1 FROM clinics LIMIT 1)", [], |r| r.get(0))?;
    Ok(BootstrapStatus { activated, setup_complete, database_healthy: state.db.quick_check().is_ok(), version: env!("CARGO_PKG_VERSION") })
}

#[derive(Deserialize)]
pub struct ActivationRequest { pub code: String }

#[tauri::command]
pub fn submit_activation(state: State<'_, AppState>, request: ActivationRequest) -> AppResult<()> {
    security::activate(&state.db, &request.code)
}

#[derive(Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct SetupRequest { pub clinic_name: String, pub address: String, pub phone: String, pub dentist_name: String, pub username: String, pub password: String, pub auto_lock_minutes: u32 }

#[tauri::command]
pub fn complete_setup(state: State<'_, AppState>, request: SetupRequest) -> AppResult<()> {
    if !security::activation_is_valid(&state.db)? { return Err(AppError::Forbidden); }
    if request.clinic_name.trim().is_empty() || request.dentist_name.trim().is_empty() || request.username.trim().len() < 3 { return Err(AppError::Validation("Clinic, dentist and a username of at least 3 characters are required".into())); }
    if !matches!(request.auto_lock_minutes, 0|5|10|15|30) { return Err(AppError::Validation("Invalid auto-lock duration".into())); }
    let password_hash = security::password_hash(&request.password)?;
    let now=chrono::Utc::now().to_rfc3339(); let clinic=uuid::Uuid::new_v4().to_string(); let user=uuid::Uuid::new_v4().to_string(); let role=uuid::Uuid::new_v4().to_string(); let dentist=uuid::Uuid::new_v4().to_string();
    let mut conn=state.db.connect()?; let tx=conn.transaction()?;
    let exists: bool=tx.query_row("SELECT EXISTS(SELECT 1 FROM clinics)",[],|r|r.get(0))?; if exists { return Err(AppError::Conflict); }
    tx.execute("INSERT INTO clinics(id,name,identifier,address,phone,created_at,updated_at) VALUES(?1,?2,'PRIMARY',?3,?4,?5,?5)",(&clinic,request.clinic_name.trim(),request.address.trim(),request.phone.trim(),&now))?;
    tx.execute("INSERT INTO users(id,clinic_id,username,password_hash,display_name,password_changed_at,created_at,updated_at) VALUES(?1,?2,?3,?4,?3,?5,?5,?5)",(&user,&clinic,request.username.trim(),password_hash,&now))?;
    tx.execute("INSERT INTO roles(id,clinic_id,name,description,is_system,created_at,updated_at) VALUES(?1,?2,'Owner','Full clinic access',1,?3,?3)",(&role,&clinic,&now))?;
    tx.execute("INSERT INTO user_roles(user_id,role_id) VALUES(?1,?2)",(&user,&role))?;
    tx.execute("INSERT INTO dentists(id,clinic_id,dentist_code,full_name,created_at,updated_at) VALUES(?1,?2,'DR-001',?3,?4,?4)",(&dentist,&clinic,request.dentist_name.trim(),&now))?;
    tx.execute("INSERT INTO settings(clinic_id,key,value_json,updated_by,updated_at) VALUES(?1,'security.auto_lock_minutes',?2,?3,?4)",(&clinic,request.auto_lock_minutes.to_string(),&user,&now))?;
    tx.commit()?; Ok(())
}
