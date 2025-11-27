import { useState, useEffect } from 'react';
import Layout from '../components/Layout';
import api from '../services/api';
import { Fee } from '../types';
import { DollarSign, Filter, Calendar, CheckCircle, Clock, PlusCircle } from 'lucide-react';
import { format } from 'date-fns';
import { useNavigate } from 'react-router-dom';

export default function Fees() {
  const navigate = useNavigate();
  const [fees, setFees] = useState<Fee[]>([]);
  const [loading, setLoading] = useState(true);
  const [statusFilter, setStatusFilter] = useState<'ALL' | 'OPEN' | 'PAID'>('ALL');
  const [page, setPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);

  useEffect(() => {
    loadFees();
  }, [page, statusFilter]);

  const loadFees = async () => {
    try {
      setLoading(true);
      const params: any = { page, limit: 20 };
      if (statusFilter !== 'ALL') params.status = statusFilter;

      const response = await api.get('/fees', { params });
      const data = response.data.data || [];
      
      // Ordena: Em Aberto primeiro (por vencimento desc), depois Pagas (por vencimento asc)
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

  return (
    <Layout>
      <div className="max-w-7xl">
        <div className="flex justify-between items-center mb-8">
          <h1 className="text-3xl font-bold text-gray-900">Mensalidades</h1>
          
          <div className="flex items-center space-x-4">
            <button
              onClick={() => navigate('/generate-fees')}
              className="flex items-center space-x-2 bg-gradient-to-r from-indigo-600 via-purple-600 to-pink-600 hover:from-indigo-700 hover:via-purple-700 hover:to-pink-700 text-white font-semibold px-6 py-3 rounded-lg transition shadow-lg hover:shadow-xl"
            >
              <PlusCircle className="w-5 h-5" />
              <span>Gerar Mensalidades</span>
            </button>
            <div className="flex items-center space-x-2">
            <Filter className="w-5 h-5 text-gray-600" />
            <select
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value as any)}
              className="px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
            >
              <option value="ALL">Todas</option>
              <option value="OPEN">Em Aberto</option>
              <option value="PAID">Pagas</option>
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
                        ) : (
                          <span className="text-gray-400">-</span>
                        )}
                      </td>
                      <td className="px-6 py-4">
                        {fee.status === 'PAID' ? (
                          <span className="inline-flex items-center space-x-1 px-3 py-1 bg-green-100 text-green-800 rounded-full text-sm font-medium">
                            <CheckCircle className="w-4 h-4" />
                            <span>Paga</span>
                          </span>
                        ) : (
                          <span className="inline-flex items-center space-x-1 px-3 py-1 bg-yellow-100 text-yellow-800 rounded-full text-sm font-medium">
                            <Clock className="w-4 h-4" />
                            <span>Em Aberto</span>
                          </span>
                        )}
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
    </Layout>
  );
}
