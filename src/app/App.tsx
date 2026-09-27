import { useCallback, useEffect, useState } from 'react';
import { Activity, CheckCircle2, Database, LockKeyhole, ShieldCheck, WifiOff } from 'lucide-react';
import { native } from '../services/native';
import type { AppError, BootstrapStatus } from '../types';
import { ActivationScreen } from '../features/onboarding/ActivationScreen';
import { SetupWizard } from '../features/onboarding/SetupWizard';

const asMessage = (error: unknown) => {
  const candidate = error as Partial<AppError>;
  return candidate?.message ?? 'Dentiva Pro could not complete the request. Please try again.';
};

export function App() {
  const [status, setStatus] = useState<BootstrapStatus | null>(null);
  const [error, setError] = useState('');

  const load = useCallback(async () => {
    setError('');
    try { setStatus(await native.bootstrapStatus()); }
    catch (reason) { setError(asMessage(reason)); }
  }, []);

  useEffect(() => {
    native.bootstrapStatus().then(setStatus).catch((reason: unknown) => setError(asMessage(reason)));
  }, []);

  if (error) return <Recovery message={error} retry={load} />;
  if (!status) return <Loading />;
  if (!status.databaseHealthy) return <Recovery message="The local database did not pass its integrity check. Your data has not been changed." retry={load} />;
  if (!status.activated) return <ActivationScreen version={status.version} onActivated={load} />;
  if (!status.setupComplete) return <SetupWizard onComplete={load} />;

  return <FoundationReady version={status.version} />;
}

function Brand() {
  return <div className="brand"><span className="brand-mark" aria-hidden="true"><Activity /></span><span><strong>Dentiva Pro</strong><small>Clinical practice management</small></span></div>;
}

function Loading() {
  return <main className="onboarding-shell"><section className="onboarding-card" aria-live="polite"><Brand/><div className="loading-block"><span className="spinner"/><h1>Preparing your workspace</h1><p>Opening the protected local database…</p></div></section></main>;
}

function Recovery({ message, retry }: { message: string; retry: () => void }) {
  return <main className="onboarding-shell"><section className="onboarding-card"><Brand/><div className="status-icon danger"><Database /></div><p className="eyebrow">Startup recovery</p><h1>We couldn’t open the workspace</h1><p className="lead">{message}</p><div className="notice">No repair or reset was attempted, so your existing data remains untouched.</div><button className="button primary" onClick={retry}>Try again</button></section></main>;
}

function FoundationReady({ version }: { version: string }) {
  return <main className="onboarding-shell"><section className="onboarding-card"><Brand/><div className="status-icon success"><CheckCircle2 /></div><p className="eyebrow">Foundation initialized</p><h1>Your clinic workspace is secure</h1><p className="lead">Dentiva Pro has completed activation and clinic setup. The operational workspace is being delivered module by module behind native authorization.</p><div className="assurance-grid"><span><WifiOff/>Fully offline</span><span><ShieldCheck/>Native access control</span><span><LockKeyhole/>Protected credentials</span></div><p className="version">Version {version}</p></section></main>;
}
