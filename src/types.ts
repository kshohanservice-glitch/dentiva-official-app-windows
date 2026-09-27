export interface BootstrapStatus {
  activated: boolean;
  setupComplete: boolean;
  databaseHealthy: boolean;
  version: string;
}

export interface AppError { code: string; message: string }
