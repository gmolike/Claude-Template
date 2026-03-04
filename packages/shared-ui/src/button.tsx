import type { ButtonHTMLAttributes } from 'react';

interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'primary' | 'secondary' | 'danger';
}

/** Gemeinsamer Button — wird von Web und Mobile genutzt. */
export const Button = ({ variant = 'primary', children, ...props }: ButtonProps) => (
  <button data-variant={variant} {...props}>
    {children}
  </button>
);
