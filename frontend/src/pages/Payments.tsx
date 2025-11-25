import { useState, useEffect } from 'react';
import Layout from '../components/Layout';
import api from '../services/api';
import { Payment } from '../types';
import { CreditCard, Calendar, User } from 'lucide-react';
import { format } from 'date-fns';

export default function Payments() {
  const [payments, setPayments] = useState<Payment[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadPayments();
  }, []);

  const loadPayments = async () => {
    try {
      setLoading(true);
      const response = await api.get('/payments');
      setPayments(response.data || []);
    } catch (error) {
      console.error('Erro ao carregar pagamentos:', error);
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
      return format(new Date(dateString), 'dd/MM/yyyy HH:mm');
    } catch {
      return dateString;
    }
  };

  return (
    <Layout>
      <div className="max-w-7xl">
        <h1 className="text-3xl font-bold text-gray-900 mb-8">Pagamentos</h1>

        {loading ? (
          <div className="text-center py-12">
            <div className="text-xl text-gray-600">Carregando...</div>
          </div>
        ) : (
          <div className="bg-white rounded-xl shadow-sm overflow-hidden">
            <table className="w-full">
              <thead className="bg-gray-50 border-b">
                <tr>
                  <th className="px-6 py-4 text-left text-sm font-semibold text-gray-900">Membro</th>
                  <th className="px-6 py-4 text-left text-sm font-semibold text-gray-900">Valor</th>
                  <th className="px-6 py-4 text-left text-sm font-semibold text-gray-900">Método</th>
                  <th className="px-6 py-4 text-left text-sm font-semibold text-gray-900">Data</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-200">
                {payments.map((payment) => (
                  <tr key={payment.id} className="hover:bg-gray-50">
                    <td className="px-6 py-4">
                      <div className="flex items-center space-x-3">
                        <div className="w-10 h-10 bg-green-100 rounded-full flex items-center justify-center">
                          <User className="w-5 h-5 text-green-600" />
                        </div>
                        <span className="font-medium text-gray-900">
                          {payment.member_name || `Membro #${payment.member_fee_id}`}
                        </span>
                      </div>
                    </td>
                    <td className="px-6 py-4 text-gray-900 font-semibold">
                      {formatCurrency(payment.amount_cents)}
                    </td>
                    <td className="px-6 py-4">
                      <div className="flex items-center space-x-2 text-gray-600">
                        <CreditCard className="w-4 h-4" />
                        <span className="capitalize">{payment.method}</span>
                      </div>
                    </td>
                    <td className="px-6 py-4">
                      <div className="flex items-center space-x-2 text-gray-600">
                        <Calendar className="w-4 h-4" />
                        <span>{formatDate(payment.paid_at)}</span>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </Layout>
  );
}
