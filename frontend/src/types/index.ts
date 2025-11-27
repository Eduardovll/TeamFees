export type UserRole = 'PLAYER' | 'TREASURER' | 'ADMIN';
export type TenantPlan = 'trial' | 'basic' | 'pro' | 'premium';
export type TenantStatus = 'active' | 'suspended' | 'cancelled';
export type BusinessType = 'academia' | 'time' | 'escola' | 'estudio' | 'corrida' | 'outro';

export interface User {
  id: string;
  full_name: string;
  email: string;
  phone?: string;
  role: UserRole;
  tenant_id?: string;
}

export interface Tenant {
  id: string;
  business_name: string;
  business_type: BusinessType;
  cnpj?: string;
  subdomain: string;
  plan: TenantPlan;
  status: TenantStatus;
  trial_ends_at?: string;
  created_at: string;
  settings?: TenantSettings;
}

export interface TenantSettings {
  max_members: number;
  features: string[];
  branding?: {
    logo_url?: string;
    primary_color?: string;
  };
}

export interface SignupRequest {
  business_name: string;
  business_type: BusinessType;
  cnpj?: string;
  admin_name: string;
  admin_email: string;
  admin_phone: string;
  admin_cpf: string;
}

export interface SignupResponse {
  tenant_id: string;
  admin_user_id: string;
  trial_ends_at: string;
  message: string;
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
  tenant_id?: string;
  tenant?: Tenant;
}

export interface Fee {
  id: number;
  nome: string;
  valor: number;
  status: 'OPEN' | 'PAID' | 'EXEMPT';
  vencimento: string;
  pago_em?: string;
  exempt_reason?: string;
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
