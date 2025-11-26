import api from './api';
import { SignupRequest, SignupResponse } from '../types';

export const tenantService = {
  // Criar novo tenant (signup)
  async signup(data: SignupRequest): Promise<SignupResponse> {
    const response = await api.post('/tenants/signup', data);
    return response.data;
  },

  // Verificar disponibilidade de subdomínio
  async checkSubdomain(subdomain: string): Promise<{ available: boolean }> {
    const response = await api.get(`/tenants/check-subdomain/${subdomain}`);
    return response.data;
  },

  // Obter informações do tenant atual
  async getCurrentTenant() {
    const response = await api.get('/tenants/current');
    return response.data;
  },

  // Atualizar plano do tenant
  async updatePlan(plan: string) {
    const response = await api.put('/tenants/plan', { plan });
    return response.data;
  }
};
