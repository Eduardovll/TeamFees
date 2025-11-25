export type UserRole = 'PLAYER' | 'TREASURER' | 'ADMIN';

export interface User {
  id: string;
  full_name: string;
  email: string;
  phone?: string;
  role: UserRole;
}

export interface AuthResponse {
  access_token: string;
  token_type: string;
  role: UserRole;
  member_id: string;
  full_name: string;
  email: string;
  phone: string;
  expires_in: number;
}

export interface Fee {
  id: number;
  nome: string;
  valor: number;
  status: 'OPEN' | 'PAID';
  vencimento: string;
  pago_em?: string;
}

export interface Payment {
  id: number;
  member_fee_id: number;
  amount_cents: number;
  method: string;
  transaction_id: string;
  paid_at: string;
  created_at: string;
  cycle_id?: number;
  member_name?: string;
}

export interface Member {
  id: number;
  full_name: string;
  email: string;
  phone: string;
  cpf: string;
  is_active: boolean;
}

export interface Summary {
  total_open: number;
  total_paid: number;
  total_amount_open: number;
  total_amount_paid: number;
}
