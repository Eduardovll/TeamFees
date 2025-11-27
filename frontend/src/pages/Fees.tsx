import { useState, useEffect } from 'react';
import Layout from '../components/Layout';
import api from '../services/api';
import { Fee, Member } from '../types';
import { DollarSign, Filter, Calendar, CheckCircle, Clock, PlusCircle, ShieldOff, X, Edit, Trash2 } from 'lucide-react';
import { format } from 'date-fns';
import { useNavigate } from 'react-router-dom';

export default function Fees() {
  const navigate = useNavigate();
  const [fees, setFees] = useState<Fee[]>([]);
  const [members, setMembers] = useState<Member[]>([]);
  const [loading, setLoading] = useState(true);
  const [statusFilter, setStatusFilter] = useState<'ALL' | 'OPEN' | 'PAID' | 'EXEMPT'>('ALL');
  const [memberFilter, setMemberFilter] = useState<number>(0);
  const [page, setPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [showExemptModal, setShowExemptModal] = useState(false);
  const [showEditModal, setShowEditModal] = useState(false);
  const [selectedFee, setSelectedFee] = useState<Fee | null>(null);
  const [exemptReason, setExemptReason] = useState('');
  const [editForm, setEditForm] = useState({ valor: 0, vencimento: '' });
  const [submitting, setSubmitting] = useState(false);

  useEffect(() => {
    loadMembers();
  }, []);

  useEffect(() => {
    loadFees();
  }, [page, statusFilter, memberFilter]);

  const loadMembers = async () => {
    try {
      const response = await api.get('/members');
      setMembers(response.data.filter((m: Member) => m.is_active));
    } catch (error) {
      console.error('Erro ao carregar membros:', error);
    }
  };

  const loadFees = async () => {
    try {
      setLoading(true);
      const params: any = { page, limit: 20 };
      if (statusFilter !== 'ALL') params.status = statusFilter;
      if (memberFilter > 0) params.member_id = memberFilter;

      const response = await api.get('/fees', { params });
      const data = response.data.data || [];
      
      const sorted = data.sort((a: Fee, b: Fee) => {
        if (a.status !== b.status) {
          return a.status === 'OPEN' ? -1 : 1;
        }
        const dateA = new Date(a.vencimento).getTime();
        const dateB = new Date(b.vencimento).getTime();
        return a.status === 'OPEN' ? dateB - dateA : dateA - dateB;
      });
      
      setFees(sorted);
      setTotalPages(response.data.total_pages || 1);
    } catch (error) {
      console.error('Erro ao carregar mensalidades:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleExempt = async () => {
    if (!selectedFee || !exemptReason.trim()) return;

    setSubmitting(true);
    try {
      await api.post(`/fees/${selectedFee.id}/exempt`, { reason: exemptReason });
      setShowExemptModal(false);
      setExemptReason('');
      setSelectedFee(null);
      loadFees();
    } catch (error: any) {
      alert(error.response?.data?.error || 'Erro ao isentar mensalidade');
    } finally {
      setSubmitting(false);
    }
  };

  const handleEdit = (fee: Fee) => {
    setSelectedFee(fee);
    setEditForm({
      valor: fee.valor,
      vencimento: fee.vencimento.split('T')[0]
    });
    setShowEditModal(true);
  };

  const handleSaveEdit = async () => {
    if (!selectedFee) return;

    setSubmitting(true);
    try {
      await api.put(`/fees/${selectedFee.id}`, editForm);
      alert('Mensalidade atualizada com sucesso!');
      setShowEditModal(false);
      loadFees();
    } catch (error: any) {
      alert(error.response?.data?.error || 'Erro ao atualizar mensalidade');
    } finally {
      setSubmitting(false);
    }
  };

  const handleDelete = async (fee: Fee) => {
    if (fee.status === 'PAID') {
      alert('Não é possível excluir mensalidade paga!');
      return;
    }

    if (!confirm(`Tem certeza que deseja excluir a mensalidade de ${fee.nome}?`)) {
      return;
    }

    try {
      await api.delete(`/fees/${fee.id}`);
      alert('Mensalidade excluída com sucesso!');
      loadFees();
    } catch (error: any) {
      alert(error.response?.data?.error || 'Erro ao excluir mensalidade');
    }
  };

  const formatCurrency = (cents: number) => {
    return new Intl.NumberFormat('pt-BR', {
      style: 'currency',
      currency: 'BRL',
    }).format(cents / 100);
  };

  const formatDate = (dateString: string) => {
    try {
      return format(new Date(dateString), 'dd/MM/yyyy');
    } catch {
      return dateString;
    }
  };

  const getStatusBadge = (fee: Fee) => {
    if (fee.status === 'PAID') {
      return (
        <span className="inline-flex items-center space-x-1 px-3 py-1 bg-green-100 text-green-800 rounded-full text-sm font-medium">
          <CheckCircle className="w-4 h-4" />
          <span>Paga</span>
        </span>
      );
    }
    if (fee.status === 'EXEMPT') {
      return (
        <span className="inline-flex items-center space-x-1 px-3 py-1 bg-purple-100 text-purple-800 rounded-full text-sm font-medium" title={fee.exempt_reason}>
          <ShieldOff className="w-4 h-4" />
          <span>Isenta</span>
        </span>
      );
    }
    return (
      <span className="inline-flex items-center space-x-1 px-3 py-1 bg-yellow-100 text-yellow-800 rounded-full text-sm font-medium">
        <Clock className="w-4 h-4" />
        <span>Em Aberto</span>
      </span>
    );
  };

  return (
    <Layout>
      <div className="max-w-7xl">
        <div className="flex justify-between items-center mb-8">
          <h1 className="text-3xl font-bold text-gray-900">Mensalidades</h1>
          
          <button
            onClick={() => navigate('/generate-fees')}
            className="flex items-center space-x-2 bg-gradient-to-r from-indigo-600 via-purple-600 to-pink-600 hover:from-indigo-700 hover:via-purple-700 hover:to-pink-700 text-white font-semibold px-6 py-3 rounded-lg transition shadow-lg hover:shadow-xl"
          >
            <PlusCircle className="w-5 h-5" />
            <span>Gerar Mensalidades</span>
          </button>
        </div>

        {/* Filtros */}
        <div className="bg-white rounded-xl shadow-sm p-4 mb-6 flex items-center space-x-4">
          <Filter className="w-5 h-5 text-gray-600" />
          
          <div className="flex-1">
            <label className="block text-xs font-medium text-gray-600 mb-1">Status</label>
            <select
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value as any)}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500"
            >
              <option value="ALL">Todas</option>
              <option value="OPEN">Em Aberto</option>
              <option value="PAID">Pagas</option>
              <option value="EXEMPT">Isentas</option>
            </select>
          </div>

          <div className="flex-1">
            <label className="block text-xs font-medium text-gray-600 mb-1">Membro</label>
            <select
              value={memberFilter}
              onChange={(e) => setMemberFilter(Number(e.target.value))}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500"
            >
              <option value={0}>Todos os membros</option>
              {members.map(member => (
                <option key={member.id} value={member.id}>{member.full_name}</option>
              ))}
            </select>
          </div>
        </div>

        {loading ? (
          <div className="text-center py-12">
            <div className="text-xl text-gray-600">Carregando...</div>
          </div>
        ) : (
          <>
            <div className="bg-white rounded-xl shadow-sm overflow-hidden">
              <table className="w-full">
                <thead className="bg-gray-50 border-b">
                  <tr>
                    <th className="px-6 py-4 text-left text-sm font-semibold text-gray-900">Membro</th>
                    <th className="px-6 py-4 text-left text-sm font-semibold text-gray-900">Valor</th>
                    <th className="px-6 py-4 text-left text-sm font-semibold text-gray-900">Vencimento</th>
                    <th className="px-6 py-4 text-left text-sm font-semibold text-gray-900">Pago em</th>
                    <th className="px-6 py-4 text-left text-sm font-semibold text-gray-900">Status</th>
                    <th className="px-6 py-4 text-left text-sm font-semibold text-gray-900">Ações</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-200">
                  {fees.map((fee) => (
                    <tr key={fee.id} className="hover:bg-gray-50">
                      <td className="px-6 py-4">
                        <div className="flex items-center space-x-3">
                          <div className="w-10 h-10 bg-blue-100 rounded-full flex items-center justify-center">
                            <DollarSign className="w-5 h-5 text-blue-600" />
                          </div>
                          <span className="font-medium text-gray-900">{fee.nome}</span>
                        </div>
                      </td>
                      <td className="px-6 py-4 text-gray-900 font-semibold">
                        {formatCurrency(fee.valor)}
                      </td>
                      <td className="px-6 py-4">
                        <div className="flex items-center space-x-2 text-gray-600">
                          <Calendar className="w-4 h-4" />
                          <span>{formatDate(fee.vencimento)}</span>
                        </div>
                      </td>
                      <td className="px-6 py-4">
                        {fee.pago_em ? (
                          <div className="flex items-center space-x-2 text-green-600">
                            <CheckCircle className="w-4 h-4" />
                            <span>{formatDate(fee.pago_em)}</span>
                          </div>
                        ) : fee.status === 'EXEMPT' && fee.exempt_reason ? (
                          <span className="text-xs text-purple-600" title={fee.exempt_reason}>
                            {fee.exempt_reason.substring(0, 30)}...
                          </span>
                        ) : (
                          <span className="text-gray-400">-</span>
                        )}
                      </td>
                      <td className="px-6 py-4">
                        {getStatusBadge(fee)}
                      </td>
                      <td className="px-6 py-4">
                        <div className="flex items-center space-x-2">
                          {fee.status !== 'PAID' && (
                            <>
                              <button
                                onClick={() => handleEdit(fee)}
                                className="p-2 text-indigo-600 hover:bg-indigo-50 rounded-lg transition"
                                title="Editar"
                              >
                                <Edit className="w-4 h-4" />
                              </button>
                              <button
                                onClick={() => handleDelete(fee)}
                                className="p-2 text-red-600 hover:bg-red-50 rounded-lg transition"
                                title="Excluir"
                              >
                                <Trash2 className="w-4 h-4" />
                              </button>
                            </>
                          )}
                          {fee.status === 'OPEN' && (
                            <button
                              onClick={() => {
                                setSelectedFee(fee);
                                setShowExemptModal(true);
                              }}
                              className="p-2 text-purple-600 hover:bg-purple-50 rounded-lg transition"
                              title="Isentar"
                            >
                              <ShieldOff className="w-4 h-4" />
                            </button>
                          )}
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>

            {totalPages > 1 && (
              <div className="flex justify-center items-center space-x-2 mt-6">
                <button
                  onClick={() => setPage(p => Math.max(1, p - 1))}
                  disabled={page === 1}
                  className="px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  Anterior
                </button>
                <span className="text-gray-600">
                  Página {page} de {totalPages}
                </span>
                <button
                  onClick={() => setPage(p => Math.min(totalPages, p + 1))}
                  disabled={page === totalPages}
                  className="px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  Próxima
                </button>
              </div>
            )}
          </>
        )}
      </div>

      {/* Modal de Edição */}
      {showEditModal && selectedFee && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-xl shadow-2xl w-full max-w-md p-6">
            <div className="flex justify-between items-start mb-4">
              <h2 className="text-2xl font-bold text-gray-900">Editar Mensalidade</h2>
              <button onClick={() => setShowEditModal(false)} className="text-gray-400 hover:text-gray-600">
                <X className="w-6 h-6" />
              </button>
            </div>

            <div className="mb-4">
              <p className="text-sm text-gray-600 mb-4">
                <strong>Membro:</strong> {selectedFee.nome}
              </p>

              <div className="space-y-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">Valor (em centavos)</label>
                  <input
                    type="number"
                    value={editForm.valor}
                    onChange={(e) => setEditForm({ ...editForm, valor: parseInt(e.target.value) })}
                    className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500"
                  />
                  <p className="text-xs text-gray-500 mt-1">{formatCurrency(editForm.valor)}</p>
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">Vencimento</label>
                  <input
                    type="date"
                    value={editForm.vencimento}
                    onChange={(e) => setEditForm({ ...editForm, vencimento: e.target.value })}
                    className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500"
                  />
                </div>
              </div>
            </div>

            <div className="flex space-x-3">
              <button
                onClick={() => setShowEditModal(false)}
                className="flex-1 px-4 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 transition"
              >
                Cancelar
              </button>
              <button
                onClick={handleSaveEdit}
                disabled={submitting}
                className="flex-1 px-4 py-2 bg-gradient-to-r from-indigo-600 to-purple-600 text-white rounded-lg hover:from-indigo-700 hover:to-purple-700 transition disabled:opacity-50"
              >
                {submitting ? 'Salvando...' : 'Salvar'}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Modal de Isenção */}
      {showExemptModal && selectedFee && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-xl shadow-2xl w-full max-w-md p-6">
            <div className="flex justify-between items-start mb-4">
              <h2 className="text-2xl font-bold text-gray-900">Isentar Mensalidade</h2>
              <button onClick={() => setShowExemptModal(false)} className="text-gray-400 hover:text-gray-600">
                <X className="w-6 h-6" />
              </button>
            </div>

            <div className="mb-4">
              <p className="text-sm text-gray-600">
                <strong>Membro:</strong> {selectedFee.nome}
              </p>
              <p className="text-sm text-gray-600">
                <strong>Valor:</strong> {formatCurrency(selectedFee.valor)}
              </p>
              <p className="text-sm text-gray-600">
                <strong>Vencimento:</strong> {formatDate(selectedFee.vencimento)}
              </p>
            </div>

            <div className="mb-4">
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Motivo da Isenção *
              </label>
              <textarea
                value={exemptReason}
                onChange={(e) => setExemptReason(e.target.value)}
                className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-purple-500 focus:border-transparent"
                rows={4}
                placeholder="Ex: Acordo com diretoria, situação financeira, etc."
                required
              />
            </div>

            <div className="flex space-x-3">
              <button
                type="button"
                onClick={() => setShowExemptModal(false)}
                className="flex-1 px-4 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 transition"
              >
                Cancelar
              </button>
              <button
                onClick={handleExempt}
                disabled={submitting || !exemptReason.trim()}
                className="flex-1 px-4 py-2 bg-gradient-to-r from-purple-600 to-pink-600 hover:from-purple-700 hover:to-pink-700 text-white rounded-lg transition disabled:opacity-50 shadow-lg hover:shadow-xl"
              >
                {submitting ? 'Isentando...' : 'Isentar'}
              </button>
            </div>
          </div>
        </div>
      )}
    </Layout>
  );
}
