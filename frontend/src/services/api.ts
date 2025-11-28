import axios from 'axios';
import { toast } from '../utils/toast';

// Usa variável de ambiente ou fallback para desenvolvimento local
const API_URL = (import.meta as any).env.VITE_API_URL || 'http://localhost:9000';

const api = axios.create({
  baseURL: API_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

api.interceptors.request.use((config) => {
  const token = localStorage.getItem('token');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      // Não redireciona se for erro na rota de login
      if (!error.config?.url?.includes('/auth/login')) {
        localStorage.removeItem('token');
        localStorage.removeItem('user');
        
        toast('<strong>Sessão expirada.</strong> Faça login novamente.', 'error', 2000);
        
        // Redirecionar após 2 segundos
        setTimeout(() => {
          window.location.href = '/login';
        }, 2000);
      }
    }
    return Promise.reject(error);
  }
);

export default api;
