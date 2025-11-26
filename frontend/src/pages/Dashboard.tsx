import { useState, useEffect } from 'react';
import { useAuth } from '../contexts/AuthContext';
import { useNavigate } from 'react-router-dom';
import Layout from '../components/Layout';
import api from '../services/api';
import { Fee } from '../types';
import { DollarSign, Calendar, AlertCircle, CheckCircle, Clock } from 'lucide-react';
import { format } from 'date-fns';

export default function Dashboard() {
  const { user } = useAuth();
  const navigate = useNavigate();
  const [fees, setFees] = useState<Fee[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadFees();
  }, []);

  const loadFees = async () => {
    try {
      const response = await api.get('/my-fees');
      setFees(response.data.data || []);
    } catch (error) {
      console.error('Erro ao carregar mensalidades:', error);
    } finally {
      setLoading(false);
    }
  };

  const isOverdue = (dueDate: string, status: string) => {
    if (status === 'PAID') return false;
    return new Date(dueDate) < new Date();
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

  const stats = {
    total: fees.length,
    paid: fees.filter(f => f.status === 'PAID').length,
    open: fees.filter(f => f.status === 'OPEN' && !isOverdue(f.vencimento, f.status)).length,
    overdue: fees.filter(f => isOverdue(f.vencimento, f.status)).length,
    totalPaid: fees.filter(f => f.status === 'PAID').reduce((sum, f) => sum + f.valor, 0),
    totalOpen: fees.filter(f => f.status === 'OPEN').reduce((sum, f) => sum + f.valor, 0),
  };

  const nextDue = fees
    .filter(f => f.status === 'OPEN')
    .sort((a, b) => new Date(a.vencimento).getTime() - new Date(b.vencimento).getTime())[0];

  return (
    <Layout>
      <div className="max-w-7xl">
        <div className="mb-8">
          <h1 className="text-3xl font-bold text-gray-900">Olá, {user?.full_name}!</h1>
          <p className="text-gray-600 mt-2">Aqui está um resumo das suas mensalidades</p>
        </div>

        {loading ? (
          <div className="text-center py-12">
            <div className="text-xl text-gray-600">Carregando...</div>
          </div>
        ) : (
          <>
            {/* Cards de Estatísticas */}
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
              <div className="bg-white rounded-xl shadow-sm p-6">
                <div className="flex items-center justify-between mb-4">
                  <div className="w-12 h-12 bg-gradient-to-br from-indigo-100 to-purple-100 rounded-xl flex items-center justify-center">
                    <DollarSign className="w-6 h-6 text-indigo-600" />
                  </div>
                </div>
                <p className="text-sm text-gray-600 mb-1">Total de Mensalidades</p>
                <p className="text-2xl font-bold text-gray-900">{stats.total}</p>
              </div>

              <div className="bg-white rounded-xl shadow-sm p-6">
                <div className="flex items-center justify-between mb-4">
                  <div className="w-12 h-12 bg-gradient-to-br from-green-100 to-emerald-100 rounded-xl flex items-center justify-center">
                    <CheckCircle className="w-6 h-6 text-green-600" />
                  </div>
                </div>
                <p className="text-sm text-gray-600 mb-1">Pagas</p>
                <p className="text-2xl font-bold text-green-600">{stats.paid}</p>
                <p className="text-xs text-gray-500 mt-1">{formatCurrency(stats.totalPaid)}</p>
              </div>

              <div className="bg-white rounded-xl shadow-sm p-6">
                <div className="flex items-center justify-between mb-4">
                  <div className="w-12 h-12 bg-gradient-to-br from-yellow-100 to-amber-100 rounded-xl flex items-center justify-center">
                    <Clock className="w-6 h-6 text-yellow-600" />
                  </div>
                </div>
                <p className="text-sm text-gray-600 mb-1">Em Aberto</p>
                <p className="text-2xl font-bold text-yellow-600">{stats.open}</p>
                <p className="text-xs text-gray-500 mt-1">{formatCurrency(stats.totalOpen)}</p>
              </div>

              <div className="bg-white rounded-xl shadow-sm p-6">
                <div className="flex items-center justify-between mb-4">
                  <div className="w-12 h-12 bg-gradient-to-br from-red-100 to-rose-100 rounded-xl flex items-center justify-center">
                    <AlertCircle className="w-6 h-6 text-red-600" />
                  </div>
                </div>
                <p className="text-sm text-gray-600 mb-1">Vencidas</p>
                <p className="text-2xl font-bold text-red-600">{stats.overdue}</p>
              </div>
            </div>

            {/* Próxima Mensalidade */}
            {nextDue && (
              <div className={`rounded-xl shadow-lg p-6 mb-8 ${
                isOverdue(nextDue.vencimento, nextDue.status)
                  ? 'bg-gradient-to-br from-red-50 to-rose-50 border-2 border-red-300'
                  : 'bg-gradient-to-br from-indigo-50 to-purple-50 border-2 border-purple-300'
              }`}>
                <div className="flex items-start justify-between">
                  <div className="flex-1">
                    <div className="flex items-center space-x-2 mb-2">
                      {isOverdue(nextDue.vencimento, nextDue.status) ? (
                        <AlertCircle className="w-5 h-5 text-red-600" />
                      ) : (
                        <Calendar className="w-5 h-5 text-indigo-600" />
                      )}
                      <h3 className={`font-semibold ${
                        isOverdue(nextDue.vencimento, nextDue.status) ? 'text-red-900' : 'text-indigo-900'
                      }`}>
                        {isOverdue(nextDue.vencimento, nextDue.status) ? 'Mensalidade Vencida!' : 'Próxima Mensalidade'}
                      </h3>
                    </div>
                    <p className="text-2xl font-bold text-gray-900 mb-2">
                      {formatCurrency(nextDue.valor)}
                    </p>
                    <p className={`text-sm ${
                      isOverdue(nextDue.vencimento, nextDue.status) ? 'text-red-700' : 'text-indigo-700'
                    }`}>
                      Vencimento: {formatDate(nextDue.vencimento)}
                    </p>
                  </div>
                  <button
                    onClick={() => navigate('/my-fees')}
                    className={`px-6 py-3 rounded-lg font-semibold text-white transition shadow-md hover:shadow-lg ${
                      isOverdue(nextDue.vencimento, nextDue.status)
                        ? 'bg-gradient-to-r from-red-600 to-rose-600 hover:from-red-700 hover:to-rose-700'
                        : 'bg-gradient-to-r from-indigo-600 to-purple-600 hover:from-indigo-700 hover:to-purple-700'
                    }`}
                  >
                    Pagar Agora
                  </button>
                </div>
              </div>
            )}

            {/* Status Geral */}
            <div className="bg-white rounded-xl shadow-sm p-6">
              <h3 className="text-lg font-semibold text-gray-900 mb-4">Status Geral</h3>
              <div className="space-y-4">
                {stats.overdue > 0 ? (
                  <div className="flex items-center space-x-3 p-4 bg-red-50 rounded-lg border border-red-200">
                    <AlertCircle className="w-6 h-6 text-red-600" />
                    <div>
                      <p className="font-semibold text-red-900">Atenção!</p>
                      <p className="text-sm text-red-700">
                        Você possui {stats.overdue} mensalidade{stats.overdue > 1 ? 's' : ''} vencida{stats.overdue > 1 ? 's' : ''}.
                      </p>
                    </div>
                  </div>
                ) : stats.open > 0 ? (
                  <div className="flex items-center space-x-3 p-4 bg-yellow-50 rounded-lg border border-yellow-200">
                    <Clock className="w-6 h-6 text-yellow-600" />
                    <div>
                      <p className="font-semibold text-yellow-900">Pendente</p>
                      <p className="text-sm text-yellow-700">
                        Você possui {stats.open} mensalidade{stats.open > 1 ? 's' : ''} em aberto.
                      </p>
                    </div>
                  </div>
                ) : (
                  <div className="flex items-center space-x-3 p-4 bg-green-50 rounded-lg border border-green-200">
                    <CheckCircle className="w-6 h-6 text-green-600" />
                    <div>
                      <p className="font-semibold text-green-900">Tudo em dia!</p>
                      <p className="text-sm text-green-700">
                        Você não possui mensalidades pendentes.
                      </p>
                    </div>
                  </div>
                )}

                <button
                  onClick={() => navigate('/my-fees')}
                  className="w-full mt-4 px-4 py-3 bg-gray-100 hover:bg-gray-200 text-gray-700 font-semibold rounded-lg transition"
                >
                  Ver Todas as Mensalidades
                </button>
              </div>
            </div>
          </>
        )}
      </div>
    </Layout>
  );
}
