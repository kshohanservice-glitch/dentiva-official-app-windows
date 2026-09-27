import { fireEvent, render, screen } from '@testing-library/react';
import { describe, expect, it, vi } from 'vitest';
import { SetupWizard } from './SetupWizard';

vi.mock('../../services/native', () => ({ native: { completeSetup: vi.fn() } }));

describe('SetupWizard', () => {
  it('prevents advancing without the required clinic identity', () => {
    render(<SetupWizard onComplete={vi.fn()} />);
    fireEvent.click(screen.getByRole('button', { name: /continue/i }));
    expect(screen.getByRole('alert')).toHaveTextContent('Clinic name is required');
    expect(screen.getByText('Step 1 of 3')).toBeInTheDocument();
  });
});
