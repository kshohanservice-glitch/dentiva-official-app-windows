import { invoke } from '@tauri-apps/api/core';
import type { BootstrapStatus } from '../types';

export const native = {
  bootstrapStatus: () => invoke<BootstrapStatus>('bootstrap_status'),
  activate: (code: string) => invoke<void>('submit_activation', { request: { code } }),
  completeSetup: (request: { clinicName: string; address: string; phone: string; dentistName: string; username: string; password: string; autoLockMinutes: number }) => invoke<void>('complete_setup', { request }),
};
