import { useState, useEffect } from 'react';
import Layout from '../components/Layout';
import api from '../services/api';
import { Member } from '../types';
import { DollarSign, Calendar, Users, CheckSquare, Square, AlertCircle, CheckCircle } from 'lucide-react';

export default function GenerateFees() {
  const [members, setMembers] = useState<Member[]>([]);
  const [selectedMembers, setSelectedMembers] = useState<number[]>([]);
  const [allMembers, setAllMembers] = useState(false);
  const [amount, setAmount] = useState('99.00');
  const [dueDate, setDueDate] = useState('');
  const [reference, setReference] = useState('');
  const [monthsCount, setMonthsCount] = useState(1);
  const [multipleMonths, setMultipleMonths] = useState(false);
  const [loading, setLoading] = useState(true);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState<any>(null);

  useEffect(() => {
    loadMembers();
    // Define data padrão como dia 10 do mês atual
    const today = new Date();
    const defaultDate = new Date(today.getFullYear(), today.getMonth(), 10);
    setDueDate(defaultDate.toISOString().split('T')[0]);
  }, []);

  const loadMembers = async () => {
    try {
      const response = await api.get('/members');
      const activeMembers = response.data.filter((m: Member) => m.is_active);
      setMembers(activeMembers);
    } catch (error) {
      console.error('Erro ao carregar membros:', error);
      setError('Erro ao carregar membros');
    } finally {
      setLoading(false);
    }
  };

  const toggleMember = (id: number) => {
    setSelectedMembers(prev =>
      prev.includes(id) ? prev.filter(m => m !== id) : [...prev, id]
    );
  };

  const selectAll = () => {
    setSelectedMembers(members.map(m => m.id));
  };

  const clearSelection = () => {
    setSelectedMembers([]);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setSuccess(null);

    if (!allMembers && selectedMembers.length === 0) {
      setError('Selecione ao menos um membro ou marque "Todos os membros ativos"');
      return;
    }

    if (!amount || parseFloat(amount) <= 0) {
      setError('Informe um valor válido');
      return;
    }

    if (!dueDate) {
      setError('Informe a data de vencimento');
      return;
    }

    setSubmitting(true);

    try {
      const amountCents = Math.round(parseFloat(amount) * 100);
      const payload = {
        member_ids: allMembers ? [] : selectedMembers,
        amount_cents: amountCents,
        due_date: dueDate,
        reference: reference || `Mensalidade ${new Date(dueDate).toLocaleDateString('pt-BR', { month: 'short', year: 'numeric' })}`,
        months_count: multipleMonths ? monthsCount : 1,
      };

      const response = await api.post('/fees/generate', payload);
      setSuccess(response.data);
      
      // Limpar formulário
      setSelectedMembers([]);
      setAllMembers(false);
      setReference('');
      setMultipleMonths(false);
      setMonthsCount(1);
    } catch (err: any) {
      setError(err.response?.data?.error || 'Erro ao gerar mensalidades');
    } finally {
      setSubmitting(false);
    }
  };

  const getMonthsPreview = () => {
    if (!dueDate || !multipleMonths) return [];
    const months = [];
    const baseDate = new Date(dueDate);
    for (let i = 0; i < monthsCount; i++) {
      const date = new Date(baseDate);
      date.setMonth(date.getMonth() + i);
      months.push(date.toLocaleDateString('pt-BR', { month: 'short', year: 'numeric' }));
    }
    return months;
  };

  return (
    <Layout>
      <div className="max-w-4xl mx-auto">
        <h1 className="text-3xl font-bold text-gray-900 mb-8">📋 Gerar Mensalidades</h1>

        {loading ? (
          <div className="text-center py-12">
            <div className="text-xl text-gray-600">Carregando...</div>
          </div>
        ) : (
          <form onSubmit={handleSubmit} className="bg-white rounded-xl shadow-sm p-8 space-y-6">
            {/* Tipo de Geração */}
            <div>
              <label className="block text-sm font-semibold text-gray-900 mb-3">
                Tipo de Geração:
              </label>
              <div className="space-y-2">
                <label className="flex items-center space-x-3 cursor-pointer">
                  <input
                    type="radio"
                    checked={!allMembers}
                    onChange={() => setAllMembers(false)}
                    className="w-4 h-4 text-blue-600"
                  />
                  <span className="text-gray-700">Membros específicos</span>
                </label>
                <label className="flex items-center space-x-3 cursor-pointer">
                  <input
                    type="radio"
                    checked={allMembers}
                    onChange={() => setAllMembers(true)}
                    className="w-4 h-4 text-blue-600"
                  />
                  <span className="text-gray-700">Todos os membros ativos ({members.length})</span>
                </label>
              </div>
            </div>

            {/* Seleção de Membros */}
            {!allMembers && (
              <div>
                <label className="block text-sm font-semibold text-gray-900 mb-3">
                  Selecionar Membros:
                </label>
                <div className="border border-gray-300 rounded-lg p-4 max-h-64 overflow-y-auto space-y-2">
                  {members.map(member => (
                    <label
                      key={member.id}
                      className="flex items-center space-x-3 p-2 hover:bg-gray-50 rounded cursor-pointer"
                    >
                      <div onClick={() => toggleMember(member.id)}>
                        {selectedMembers.includes(member.id) ? (
                          <CheckSquare className="w-5 h-5 text-blue-600" />
                        ) : (
                          <Square className="w-5 h-5 text-gray-400" />
                        )}
                      </div>
                      <span className="text-gray-900">{member.full_name}</span>
                    </label>
                  ))}
                </div>
                <div className="flex space-x-2 mt-3">
                  <button
                    type="button"
                    onClick={selectAll}
                    className="px-4 py-2 text-sm bg-gradient-to-r from-indigo-50 to-purple-50 text-indigo-600 rounded-lg hover:from-indigo-100 hover:to-purple-100 transition"
                  >
                    Selecionar Todos
                  </button>
                  <button
                    type="button"
                    onClick={clearSelection}
                    className="px-4 py-2 text-sm bg-gray-50 text-gray-600 rounded-lg hover:bg-gray-100 transition"
                  >
                    Limpar
                  </button>
                </div>
                {selectedMembers.length > 0 && (
                  <p className="text-sm text-gray-600 mt-2">
                    {selectedMembers.length} membro(s) selecionado(s)
                  </p>
                )}
              </div>
            )}

            {/* Valor */}
            <div>
              <label className="block text-sm font-semibold text-gray-900 mb-2">
                Valor: *
              </label>
              <div className="relative">
                <DollarSign className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
                <input
                  type="number"
                  step="0.01"
                  value={amount}
                  onChange={(e) => setAmount(e.target.value)}
                  className="w-full pl-10 pr-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  placeholder="99.00"
                  required
                />
              </div>
            </div>

            {/* Vencimento */}
            <div>
              <label className="block text-sm font-semibold text-gray-900 mb-2">
                Vencimento: *
              </label>
              <div className="relative">
                <Calendar className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
                <input
                  type="date"
                  value={dueDate}
                  onChange={(e) => setDueDate(e.target.value)}
                  className="w-full pl-10 pr-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  required
                />
              </div>
            </div>

            {/* Referência */}
            <div>
              <label className="block text-sm font-semibold text-gray-900 mb-2">
                Referência:
              </label>
              <input
                type="text"
                value={reference}
                onChange={(e) => setReference(e.target.value)}
                className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                placeholder="Ex: Mensalidade Dez/2024"
              />
              <p className="text-xs text-gray-500 mt-1">
                Deixe em branco para gerar automaticamente
              </p>
            </div>

            {/* Múltiplos Meses */}
            <div>
              <label className="flex items-center space-x-3 cursor-pointer">
                <input
                  type="checkbox"
                  checked={multipleMonths}
                  onChange={(e) => setMultipleMonths(e.target.checked)}
                  className="w-4 h-4 text-blue-600 rounded"
                />
                <span className="text-sm font-semibold text-gray-900">
                  Gerar para múltiplos meses?
                </span>
              </label>

              {multipleMonths && (
                <div className="mt-3 space-y-3">
                  <div className="flex items-center space-x-3">
                    <label className="text-sm text-gray-700">Quantos meses:</label>
                    <input
                      type="number"
                      min="1"
                      max="12"
                      value={monthsCount}
                      onChange={(e) => setMonthsCount(parseInt(e.target.value) || 1)}
                      className="w-20 px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                    />
                  </div>
                  {getMonthsPreview().length > 0 && (
                    <div className="bg-gradient-to-r from-indigo-50 to-purple-50 border border-purple-200 rounded-lg p-3">
                      <p className="text-sm text-indigo-900">
                        <strong>Criará mensalidades para:</strong> {getMonthsPreview().join(', ')}
                      </p>
                    </div>
                  )}
                </div>
              )}
            </div>

            {/* Mensagens */}
            {error && (
              <div className="flex items-start space-x-2 bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-lg">
                <AlertCircle className="w-5 h-5 flex-shrink-0 mt-0.5" />
                <span className="text-sm">{error}</span>
              </div>
            )}

            {success && (
              <div className="bg-green-50 border border-green-200 rounded-lg p-4 space-y-2">
                <div className="flex items-center space-x-2 text-green-800">
                  <CheckCircle className="w-5 h-5" />
                  <span className="font-semibold">{success.message}</span>
                </div>
                <div className="text-sm text-green-700 space-y-1">
                  <p>✅ {success.total_created} mensalidades criadas</p>
                  {success.total_skipped > 0 && (
                    <>
                      <p>⚠️ {success.total_skipped} mensalidades já existiam</p>
                      {success.skipped_members?.length > 0 && (
                        <p className="text-xs">
                          Membros pulados: {success.skipped_members.join(', ')}
                        </p>
                      )}
                    </>
                  )}
                </div>
              </div>
            )}

            {/* Botões */}
            <div className="flex space-x-3 pt-4">
              <button
                type="button"
                onClick={() => window.history.back()}
                className="flex-1 px-6 py-3 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 transition font-semibold"
              >
                Cancelar
              </button>
              <button
                type="submit"
                disabled={submitting}
                className="flex-1 px-6 py-3 bg-gradient-to-r from-indigo-600 via-purple-600 to-pink-600 hover:from-indigo-700 hover:via-purple-700 hover:to-pink-700 text-white rounded-lg transition font-semibold disabled:opacity-50 disabled:cursor-not-allowed shadow-lg hover:shadow-xl"
              >
                {submitting ? 'Gerando...' : 'Gerar Mensalidades'}
              </button>
            </div>
          </form>
        )}
      </div>
    </Layout>
  );
}
