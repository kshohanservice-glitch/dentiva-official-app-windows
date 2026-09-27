import { FormEvent, useRef, useState } from 'react';
import { Activity, ArrowRight, KeyRound, LockKeyhole, ShieldCheck, WifiOff } from 'lucide-react';
import { native } from '../../services/native';

export function ActivationScreen({ version, onActivated }: { version: string; onActivated: () => Promise<void> }) {
  const [code, setCode] = useState(''); const [error, setError] = useState(''); const [busy, setBusy] = useState(false); const input = useRef<HTMLInputElement>(null);
  const submit = async (event: FormEvent) => {
    event.preventDefault(); setError('');
    if (!/^\d{16}$/.test(code)) { setError('Enter the complete 16-digit activation code.'); input.current?.focus(); return; }
    setBusy(true);
    try { await native.activate(code); setCode(''); await onActivated(); }
    catch { setError('That activation code is not valid. Check the code and try again.'); input.current?.focus(); }
    finally { setBusy(false); }
  };
  return <main className="onboarding-shell"><section className="onboarding-card split-card">
    <aside className="welcome-panel"><div className="brand inverse"><span className="brand-mark"><Activity/></span><span><strong>Dentiva Pro</strong><small>Clinical practice management</small></span></div><div><p className="eyebrow pale">Welcome to a calmer clinic</p><h1>Thoughtful tools for exceptional dental care.</h1><p>Private, dependable practice management created for clinics in Bangladesh.</p></div><ul className="benefit-list"><li><WifiOff/>Works completely offline</li><li><ShieldCheck/>Local-first patient privacy</li><li><LockKeyhole/>Secure clinical records</li></ul><small>Version {version} · Windows desktop</small></aside>
    <div className="form-panel"><div className="status-icon"><KeyRound/></div><p className="eyebrow">One-time activation</p><h2>Activate Dentiva Pro</h2><p className="lead">Enter the activation code provided with your licensed copy. Activation is verified privately on this computer.</p>
      <form onSubmit={submit} noValidate><label htmlFor="activation">Activation code <span aria-hidden="true">*</span></label><input ref={input} id="activation" value={code} onChange={e=>setCode(e.target.value.replace(/\D/g,'').slice(0,16))} inputMode="numeric" autoComplete="off" placeholder="•••• •••• •••• ••••" aria-invalid={!!error} aria-describedby={error?'activation-error':'activation-help'} disabled={busy}/><small id="activation-help">16 digits · Internet connection is not required</small>{error&&<p id="activation-error" className="field-error" role="alert">{error}</p>}<button className="button primary full" disabled={busy}>{busy?<><span className="spinner small"/>Verifying securely…</>:<>Continue <ArrowRight/></>}</button></form>
      <div className="privacy-note"><ShieldCheck/><span><strong>Your data stays here.</strong><br/>Dentiva Pro does not contact an activation server.</span></div>
    </div>
  </section></main>;
}
