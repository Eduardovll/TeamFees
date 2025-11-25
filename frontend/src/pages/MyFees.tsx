import { useState, useEffect } from 'react';
import Layout from '../components/Layout';
import PixModal from '../components/PixModal';
import ReceiptModal from '../components/ReceiptModal';
import api from '../services/api';
import { Fee } from '../types';
import { DollarSign, Calendar, CheckCircle, Clock, QrCode, FileText, AlertCircle } from 'lucide-react';
import { format } from 'date-fns';

export default function MyFees() {
  const [fees, setFees] = useState<Fee[]>([]);
  const [filteredFees, setFilteredFees] = useState<Fee[]>([]);
  const [loading, setLoading] = useState(true);
  const [statusFilter, setStatusFilter] = useState<'ALL' | 'PAID' | 'OPEN' | 'OVERDUE'>('ALL');
  const [pixModal, setPixModal] = useState<{ isOpen: boolean; qrCode: string; amount: number }>({
    isOpen: false,
    qrCode: '',
    amount: 0,
  });

  useEffect(() => {
    loadFees();
  }, []);

  const loadFees = async () => {
    try {
      setLoading(true);
      const response = await api.get('/my-fees');
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
      setFilteredFees(sorted);
    } catch (error) {
      console.error('Erro ao carregar mensalidades:', error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    applyFilter();
  }, [statusFilter, fees]);

  const applyFilter = () => {
    let filtered = [...fees];
    
    if (statusFilter === 'PAID') {
      filtered = filtered.filter(f => f.status === 'PAID');
    } else if (statusFilter === 'OPEN') {
      filtered = filtered.filter(f => f.status === 'OPEN' && !isOverdue(f.vencimento, f.status));
    } else if (statusFilter === 'OVERDUE') {
      filtered = filtered.filter(f => isOverdue(f.vencimento, f.status));
    }
    
    setFilteredFees(filtered);
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

  const isOverdue = (dueDate: string, status: string) => {
    if (status === 'PAID') return false;
    return new Date(dueDate) < new Date();
  };

  const handleGeneratePix = async (feeId: number, amount: number) => {
    try {
      const response = await api.post(`/my-fees/${feeId}/generate-pix`);
      setPixModal({
        isOpen: true,
        qrCode: response.data.pix_qr_code,
        amount,
      });
    } catch (error) {
      console.error('Erro ao gerar PIX:', error);
      alert('Erro ao gerar QR Code PIX');
    }
  };

  const [receiptModal, setReceiptModal] = useState<{ isOpen: boolean; fee: Fee | null }>({
    isOpen: false,
    fee: null,
  });

  const handleViewReceipt = (fee: Fee) => {
    setReceiptModal({
      isOpen: true,
      fee,
    });
  };

  const getFilterStats = () => {
    const total = fees.length;
    const paid = fees.filter(f => f.status === 'PAID').length;
    const open = fees.filter(f => f.status === 'OPEN' && !isOverdue(f.vencimento, f.status)).length;
    const overdue = fees.filter(f => isOverdue(f.vencimento, f.status)).length;
    return { total, paid, open, overdue };
  };

  const stats = getFilterStats();

  return (
    <Layout>
      <div className="max-w-7xl">
        <h1 className="text-3xl font-bold text-gray-900 mb-6">Minhas Mensalidades</h1>
        
        <div className="mb-6 flex flex-wrap gap-3">
          <button
            onClick={() => setStatusFilter('ALL')}
            className={`px-4 py-2 rounded-lg font-medium transition ${
              statusFilter === 'ALL'
                ? 'bg-blue-600 text-white'
                : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
            }`}
          >
            Todas ({stats.total})
          </button>
          <button
            onClick={() => setStatusFilter('OVERDUE')}
            className={`px-4 py-2 rounded-lg font-medium transition ${
              statusFilter === 'OVERDUE'
                ? 'bg-red-600 text-white'
                : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
            }`}
          >
            Vencidas ({stats.overdue})
          </button>
          <button
            onClick={() => setStatusFilter('OPEN')}
            className={`px-4 py-2 rounded-lg font-medium transition ${
              statusFilter === 'OPEN'
                ? 'bg-yellow-600 text-white'
                : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
            }`}
          >
            Em Aberto ({stats.open})
          </button>
          <button
            onClick={() => setStatusFilter('PAID')}
            className={`px-4 py-2 rounded-lg font-medium transition ${
              statusFilter === 'PAID'
                ? 'bg-green-600 text-white'
                : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
            }`}
          >
            Pagas ({stats.paid})
          </button>
        </div>

        {loading ? (
          <div className="text-center py-12">
            <div className="text-xl text-gray-600">Carregando...</div>
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {filteredFees.map((fee) => {
              const overdue = isOverdue(fee.vencimento, fee.status);
              return (
              <div key={fee.id} className={`rounded-xl shadow-sm p-6 hover:shadow-md transition ${
                overdue ? 'bg-red-50 border-2 border-red-200' : 'bg-white'
              }`}>
                <div className="flex justify-between items-start mb-4">
                  <div className="flex items-center space-x-3">
                    <div className={`w-12 h-12 rounded-full flex items-center justify-center ${
                      overdue ? 'bg-red-100' : 'bg-blue-100'
                    }`}>
                      <DollarSign className={`w-6 h-6 ${
                        overdue ? 'text-red-600' : 'text-blue-600'
                      }`} />
                    </div>
                    <div>
                      <h3 className="font-semibold text-gray-900">Mensalidade</h3>
                      <p className="text-sm text-gray-500">#{fee.id}</p>
                    </div>
                  </div>
                  {fee.status === 'PAID' ? (
                    <CheckCircle className="w-6 h-6 text-green-500" />
                  ) : overdue ? (
                    <AlertCircle className="w-6 h-6 text-red-500" />
                  ) : (
                    <Clock className="w-6 h-6 text-yellow-500" />
                  )}
                </div>

                {overdue && (
                  <div className="mb-3">
                    <span className="inline-flex items-center px-3 py-1 rounded-full text-xs font-semibold bg-red-600 text-white">
                      <AlertCircle className="w-3 h-3 mr-1" />
                      VENCIDA
                    </span>
                  </div>
                )}

                <div className="space-y-3">
                  <div>
                    <p className="text-2xl font-bold text-gray-900">
                      {formatCurrency(fee.valor)}
                    </p>
                  </div>

                  <div className={`flex items-center space-x-2 ${
                    overdue ? 'text-red-600 font-semibold' : 'text-gray-600'
                  }`}>
                    <Calendar className="w-4 h-4" />
                    <span className="text-sm">Vencimento: {formatDate(fee.vencimento)}</span>
                  </div>

                  {fee.pago_em && (
                    <div className="flex items-center space-x-2 text-green-600">
                      <CheckCircle className="w-4 h-4" />
                      <span className="text-sm">Pago em: {formatDate(fee.pago_em)}</span>
                    </div>
                  )}

                  <div className="pt-3 border-t">
                    {fee.status === 'PAID' ? (
                      <button 
                        onClick={() => handleViewReceipt(fee)}
                        className="w-full flex items-center justify-center space-x-2 bg-green-600 hover:bg-green-700 text-white font-semibold py-2 px-4 rounded-lg transition"
                      >
                        <FileText className="w-5 h-5" />
                        <span>Ver Comprovante</span>
                      </button>
                    ) : (
                      <button 
                        onClick={() => handleGeneratePix(fee.id, fee.valor)}
                        className={`w-full flex items-center justify-center space-x-2 text-white font-semibold py-2 px-4 rounded-lg transition ${
                          overdue ? 'bg-red-600 hover:bg-red-700' : 'bg-blue-600 hover:bg-blue-700'
                        }`}
                      >
                        <QrCode className="w-5 h-5" />
                        <span>Pagar com PIX</span>
                      </button>
                    )}
                  </div>
                </div>
              </div>
            )})}
          </div>
        )}

        {!loading && fees.length === 0 && (
          <div className="text-center py-12">
            <p className="text-gray-600">Você não possui mensalidades no momento.</p>
          </div>
        )}
        
        {!loading && fees.length > 0 && filteredFees.length === 0 && (
          <div className="text-center py-12">
            <p className="text-gray-600">Nenhuma mensalidade encontrada com este filtro.</p>
          </div>
        )}
      </div>

      <PixModal
        isOpen={pixModal.isOpen}
        onClose={() => setPixModal({ ...pixModal, isOpen: false })}
        qrCode={pixModal.qrCode}
        amount={pixModal.amount}
      />

      <ReceiptModal
        isOpen={receiptModal.isOpen}
        onClose={() => setReceiptModal({ isOpen: false, fee: null })}
        fee={receiptModal.fee}
      />
    </Layout>
  );
}
