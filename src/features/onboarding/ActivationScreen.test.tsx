import { fireEvent, render, screen } from '@testing-library/react';
import { beforeEach, describe, expect, it, vi } from 'vitest';
import { ActivationScreen } from './ActivationScreen';
import { native } from '../../services/native';

vi.mock('../../services/native', () => ({ native: { activate: vi.fn() } }));

describe('ActivationScreen', () => {
  beforeEach(() => vi.clearAllMocks());
  it('validates malformed codes without invoking the native verifier', () => {
    render(<ActivationScreen version="1.0.0" onActivated={vi.fn()} />);
    fireEvent.change(screen.getByLabelText(/activation code/i), { target: { value: '123' } });
    fireEvent.click(screen.getByRole('button', { name: /continue/i }));
    expect(screen.getByRole('alert')).toHaveTextContent('complete 16-digit');
    expect(native.activate).not.toHaveBeenCalled();
  });

  it('sends complete numeric input only to native verification', async () => {
    vi.mocked(native.activate).mockResolvedValue(undefined);
    const onActivated = vi.fn().mockResolvedValue(undefined);
    render(<ActivationScreen version="1.0.0" onActivated={onActivated} />);
    fireEvent.change(screen.getByLabelText(/activation code/i), { target: { value: '1234567890123456' } });
    fireEvent.click(screen.getByRole('button', { name: /continue/i }));
    expect(native.activate).toHaveBeenCalledWith('1234567890123456');
  });
});
