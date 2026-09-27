use serde::Serialize;
use thiserror::Error;

#[derive(Debug, Error)]
pub enum AppError {
    #[error("The request is invalid: {0}")]
    Validation(String),
    #[error("Authentication is required")]
    Unauthenticated,
    #[error("You do not have permission to perform this action")]
    Forbidden,
    #[error("The application data could not be accessed")]
    Database(#[from] rusqlite::Error),
    #[error("A local file operation failed")]
    Io(#[from] std::io::Error),
    #[error("The requested record was not found")]
    NotFound,
    #[error("This operation conflicts with an existing record")]
    Conflict,
    #[error("An internal operation failed")]
    Internal,
}

#[derive(Debug, Serialize)]
pub struct ErrorPayload {
    pub code: &'static str,
    pub message: String,
}

impl Serialize for AppError {
    fn serialize<S>(&self, serializer: S) -> Result<S::Ok, S::Error>
    where
        S: serde::Serializer,
    {
        let code = match self {
            Self::Validation(_) => "VALIDATION",
            Self::Unauthenticated => "UNAUTHENTICATED",
            Self::Forbidden => "FORBIDDEN",
            Self::NotFound => "NOT_FOUND",
            Self::Conflict => "CONFLICT",
            Self::Database(_) | Self::Io(_) | Self::Internal => "INTERNAL",
        };
        ErrorPayload {
            code,
            message: self.to_string(),
        }
        .serialize(serializer)
    }
}

pub type AppResult<T> = Result<T, AppError>;
