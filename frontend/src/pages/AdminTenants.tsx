import { useState, useEffect } from 'react';
import Layout from '../components/Layout';
import api from '../services/api';
import { Tenant } from '../types';
import { Building2, CheckCircle, XCircle, Clock, DollarSign, Calendar, Edit, RotateCw, Power, PowerOff } from 'lucide-react';
import { format } from 'date-fns';

export default function AdminTenants() {
  const [tenants, setTenants] = useState<Tenant[]>([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState<'all' | 'active' | 'trial' | 'suspended'>('all');
  const [showEditModal, setShowEditModal] = useState(false);
  const [showRenewModal, setShowRenewModal] = useState(false);
  const [selectedTenant, setSelectedTenant] = useState<Tenant | null>(null);
  const [editForm, setEditForm] = useState({ business_name: '', segment: '', plan: '' });
  const [renewMonths, setRenewMonths] = useState(1);

  useEffect(() => {
    loadTenants();
  }, []);

  const loadTenants = async () => {
    try {
      const response = await api.get('/admin/tenants');
      setTenants(response.data);
    } catch (error) {
      console.error('Erro ao carregar tenants:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleStatusChange = async (tenant: Tenant, newStatus: string) => {
    setSelectedTenant(tenant);
    const action = newStatus === 'active' ? 'ativar' : 'suspender';
    
    if (!confirm(`Tem certeza que deseja ${action} ${tenant.business_name}?`)) {
      return;
    }

    try {
      await api.put(`/admin/tenants/${tenant.id}/status`, { status: newStatus });
      alert(`Tenant ${action === 'ativar' ? 'ativado' : 'suspenso'} com sucesso!`);
      loadTenants();
    } catch (error: any) {
      alert(error.response?.data?.error || 'Erro ao atualizar status');
    }
  };

  const handleRenewPlan = async () => {
    if (!selectedTenant) return;

    try {
      await api.post(`/admin/tenants/${selectedTenant.id}/renew`, { months: renewMonths });
      alert('Plano renovado com sucesso!');
      setShowRenewModal(false);
      setRenewMonths(1);
      loadTenants();
    } catch (error: any) {
      alert(error.response?.data?.error || 'Erro ao renovar plano');
    }
  };

  const handleEdit = (tenant: Tenant) => {
    setSelectedTenant(tenant);
    setEditForm({
      business_name: tenant.business_name,
      segment: tenant.business_type,
      plan: tenant.plan
    });
    setShowEditModal(true);
  };

  const handleSaveEdit = async () => {
    if (!selectedTenant) return;

    try {
      await api.put(`/admin/tenants/${selectedTenant.id}`, {
        business_name: editForm.business_name,
        business_type: editForm.segment,
        plan: editForm.plan
      });
      alert('Tenant atualizado com sucesso!');
      setShowEditModal(false);
      loadTenants();
    } catch (error: any) {
      alert(error.response?.data?.error || 'Erro ao atualizar tenant');
    }
  };

  const formatDate = (dateString?: string) => {
    if (!dateString) return '-';
    try {
      return format(new Date(dateString), 'dd/MM/yyyy');
    } catch {
      return dateString;
    }
  };

  const getPlanBadge = (plan: string) => {
    const colors: any = {
      trial: 'bg-gray-100 text-gray-800',
      basic: 'bg-blue-100 text-blue-800',
      pro: 'bg-purple-100 text-purple-800',
      premium: 'bg-pink-100 text-pink-800'
    };
    return colors[plan] || 'bg-gray-100 text-gray-800';
  };

  const getStatusIcon = (status: string) => {
    if (status === 'active') return <CheckCircle className="w-5 h-5 text-green-600" />;
    if (status === 'suspended') return <XCircle className="w-5 h-5 text-red-600" />;
    return <Clock className="w-5 h-5 text-yellow-600" />;
  };

  const filteredTenants = tenants.filter(t => {
    if (filter === 'all') return true;
    if (filter === 'active') return t.status === 'active' && t.plan !== 'trial';
    if (filter === 'trial') return t.plan === 'trial';
    if (filter === 'suspended') return t.status === 'suspended';
    return true;
  });

  const stats = {
    total: tenants.length,
    active: tenants.filter(t => t.status === 'active').length,
    trial: tenants.filter(t => t.plan === 'trial').length,
    suspended: tenants.filter(t => t.status === 'suspended').length,
    revenue: tenants.reduce((sum, t) => {
      const prices: any = { basic: 49, pro: 99, premium: 199 };
      return sum + (t.status === 'active' ? (prices[t.plan] || 0) : 0);
    }, 0)
  };

  if (loading) {
    return (
      <Layout>
        <div className="text-center py-12">
          <div className="text-xl text-gray-600">Carregando...</div>
        </div>
      </Layout>
    );
  }

  return (
    <Layout>
      <div className="max-w-7xl mx-auto">
        <h1 className="text-3xl font-bold text-gray-900 mb-8">🏢 Gerenciar Tenants</h1>

        {/* Stats */}
        <div className="grid grid-cols-1 md:grid-cols-5 gap-4 mb-8">
          <div className="bg-white rounded-xl shadow-sm p-6 border-l-4 border-indigo-500">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-gray-600">Total</p>
                <p className="text-2xl font-bold text-gray-900">{stats.total}</p>
              </div>
              <Building2 className="w-8 h-8 text-indigo-500" />
            </div>
          </div>

          <div className="bg-white rounded-xl shadow-sm p-6 border-l-4 border-green-500">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-gray-600">Ativos</p>
                <p className="text-2xl font-bold text-gray-900">{stats.active}</p>
              </div>
              <CheckCircle className="w-8 h-8 text-green-500" />
            </div>
          </div>

          <div className="bg-white rounded-xl shadow-sm p-6 border-l-4 border-yellow-500">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-gray-600">Trial</p>
                <p className="text-2xl font-bold text-gray-900">{stats.trial}</p>
              </div>
              <Clock className="w-8 h-8 text-yellow-500" />
            </div>
          </div>

          <div className="bg-white rounded-xl shadow-sm p-6 border-l-4 border-red-500">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-gray-600">Suspensos</p>
                <p className="text-2xl font-bold text-gray-900">{stats.suspended}</p>
              </div>
              <XCircle className="w-8 h-8 text-red-500" />
            </div>
          </div>

          <div className="bg-gradient-to-br from-indigo-600 via-purple-600 to-pink-600 rounded-xl shadow-sm p-6 text-white">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-indigo-100">Receita/mês</p>
                <p className="text-2xl font-bold">R$ {stats.revenue}</p>
              </div>
              <DollarSign className="w-8 h-8" />
            </div>
          </div>
        </div>

        {/* Filtros */}
        <div className="bg-white rounded-xl shadow-sm p-4 mb-6 flex items-center space-x-4">
          <span className="text-sm font-medium text-gray-700">Filtrar:</span>
          <button
            onClick={() => setFilter('all')}
            className={`px-4 py-2 rounded-lg text-sm font-medium transition ${
              filter === 'all' ? 'bg-indigo-600 text-white' : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
            }`}
          >
            Todos
          </button>
          <button
            onClick={() => setFilter('active')}
            className={`px-4 py-2 rounded-lg text-sm font-medium transition ${
              filter === 'active' ? 'bg-green-600 text-white' : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
            }`}
          >
            Ativos
          </button>
          <button
            onClick={() => setFilter('trial')}
            className={`px-4 py-2 rounded-lg text-sm font-medium transition ${
              filter === 'trial' ? 'bg-yellow-600 text-white' : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
            }`}
          >
            Trial
          </button>
          <button
            onClick={() => setFilter('suspended')}
            className={`px-4 py-2 rounded-lg text-sm font-medium transition ${
              filter === 'suspended' ? 'bg-red-600 text-white' : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
            }`}
          >
            Suspensos
          </button>
        </div>

        {/* Tabela */}
        <div className="bg-white rounded-xl shadow-sm overflow-hidden">
          <table className="w-full">
            <thead className="bg-gray-50 border-b">
              <tr>
                <th className="px-6 py-4 text-left text-sm font-semibold text-gray-900">Empresa</th>
                <th className="px-6 py-4 text-left text-sm font-semibold text-gray-900">Plano</th>
                <th className="px-6 py-4 text-left text-sm font-semibold text-gray-900">Status</th>
                <th className="px-6 py-4 text-left text-sm font-semibold text-gray-900">Expira em</th>
                <th className="px-6 py-4 text-left text-sm font-semibold text-gray-900">Criado em</th>
                <th className="px-6 py-4 text-left text-sm font-semibold text-gray-900">Ações</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-200">
              {filteredTenants.map((tenant) => (
                <tr key={tenant.id} className="hover:bg-gray-50">
                  <td className="px-6 py-4">
                    <div className="flex items-center space-x-3">
                      <div className="w-10 h-10 bg-indigo-100 rounded-full flex items-center justify-center">
                        <Building2 className="w-5 h-5 text-indigo-600" />
                      </div>
                      <div>
                        <div className="font-medium text-gray-900">{tenant.business_name}</div>
                        <div className="text-sm text-gray-500">{tenant.subdomain}.vallefy.com</div>
                      </div>
                    </div>
                  </td>
                  <td className="px-6 py-4">
                    <span className={`inline-block px-3 py-1 rounded-full text-xs font-semibold ${getPlanBadge(tenant.plan)}`}>
                      {tenant.plan.toUpperCase()}
                    </span>
                  </td>
                  <td className="px-6 py-4">
                    <div className="flex items-center space-x-2">
                      {getStatusIcon(tenant.status)}
                      <span className="text-sm text-gray-700 capitalize">{tenant.status}</span>
                    </div>
                  </td>
                  <td className="px-6 py-4">
                    <div className="flex items-center space-x-2 text-gray-600">
                      <Calendar className="w-4 h-4" />
                      <span className="text-sm">{formatDate(tenant.trial_ends_at)}</span>
                    </div>
                  </td>
                  <td className="px-6 py-4 text-sm text-gray-600">
                    {formatDate(tenant.created_at)}
                  </td>
                  <td className="px-6 py-4">
                    <div className="flex items-center space-x-2">
                      <button
                        onClick={() => handleEdit(tenant)}
                        className="p-2 text-indigo-600 hover:bg-indigo-50 rounded-lg transition"
                        title="Editar"
                      >
                        <Edit className="w-4 h-4" />
                      </button>
                      <button
                        onClick={() => { setSelectedTenant(tenant); setShowRenewModal(true); }}
                        className="p-2 text-purple-600 hover:bg-purple-50 rounded-lg transition"
                        title="Renovar Plano"
                      >
                        <RotateCw className="w-4 h-4" />
                      </button>
                      {tenant.status === 'active' ? (
                        <button
                          onClick={() => handleStatusChange(tenant, 'suspended')}
                          className="p-2 text-red-600 hover:bg-red-50 rounded-lg transition"
                          title="Suspender"
                        >
                          <PowerOff className="w-4 h-4" />
                        </button>
                      ) : (
                        <button
                          onClick={() => handleStatusChange(tenant, 'active')}
                          className="p-2 text-green-600 hover:bg-green-50 rounded-lg transition"
                          title="Ativar"
                        >
                          <Power className="w-4 h-4" />
                        </button>
                      )}
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

        {/* Modal de Renovação */}
        {showRenewModal && selectedTenant && (
          <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
            <div className="bg-white rounded-xl shadow-2xl p-8 max-w-md w-full">
              <h2 className="text-2xl font-bold text-gray-900 mb-4">Renovar Plano</h2>
              <p className="text-gray-600 mb-6">{selectedTenant.business_name}</p>
              
              <div className="space-y-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">Quantos meses?</label>
                  <input
                    type="number"
                    min="1"
                    max="12"
                    value={renewMonths}
                    onChange={(e) => setRenewMonths(parseInt(e.target.value))}
                    className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-purple-500"
                  />
                </div>
              </div>

              <div className="flex space-x-3 mt-6">
                <button
                  onClick={() => { setShowRenewModal(false); setRenewMonths(1); }}
                  className="flex-1 px-4 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 transition"
                >
                  Cancelar
                </button>
                <button
                  onClick={handleRenewPlan}
                  className="flex-1 px-4 py-2 bg-gradient-to-r from-purple-600 to-pink-600 text-white rounded-lg hover:from-purple-700 hover:to-pink-700 transition"
                >
                  Renovar
                </button>
              </div>
            </div>
          </div>
        )}

        {/* Modal de Edição */}
        {showEditModal && selectedTenant && (
          <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
            <div className="bg-white rounded-xl shadow-2xl p-8 max-w-md w-full">
              <h2 className="text-2xl font-bold text-gray-900 mb-6">Editar Tenant</h2>
              
              <div className="space-y-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">Nome da Empresa</label>
                  <input
                    type="text"
                    value={editForm.business_name}
                    onChange={(e) => setEditForm({ ...editForm, business_name: e.target.value })}
                    className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500"
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">Tipo de Negócio</label>
                  <select
                    value={editForm.segment}
                    onChange={(e) => setEditForm({ ...editForm, segment: e.target.value })}
                    className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500"
                  >
                    <option value="academia">Academia</option>
                    <option value="time">Time Esportivo</option>
                    <option value="escola">Escola</option>
                    <option value="estudio">Estúdio</option>
                    <option value="corrida">Assessoria de Corrida</option>
                    <option value="outro">Outro</option>
                  </select>
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">Plano</label>
                  <select
                    value={editForm.plan}
                    onChange={(e) => setEditForm({ ...editForm, plan: e.target.value })}
                    className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500"
                  >
                    <option value="trial">Trial</option>
                    <option value="basic">Básico</option>
                    <option value="pro">Pro</option>
                    <option value="premium">Premium</option>
                  </select>
                </div>
              </div>

              <div className="flex space-x-3 mt-6">
                <button
                  onClick={() => setShowEditModal(false)}
                  className="flex-1 px-4 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 transition"
                >
                  Cancelar
                </button>
                <button
                  onClick={handleSaveEdit}
                  className="flex-1 px-4 py-2 bg-gradient-to-r from-indigo-600 via-purple-600 to-pink-600 text-white rounded-lg hover:from-indigo-700 hover:via-purple-700 hover:to-pink-700 transition"
                >
                  Salvar
                </button>
              </div>
            </div>
          </div>
        )}
      </div>
    </Layout>
  );
}
