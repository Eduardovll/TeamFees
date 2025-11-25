import { X, Download, CheckCircle } from 'lucide-react';
import { Fee } from '../types';
import { format } from 'date-fns';

interface ReceiptModalProps {
  isOpen: boolean;
  onClose: () => void;
  fee: Fee | null;
}

export default function ReceiptModal({ isOpen, onClose, fee }: ReceiptModalProps) {
  if (!isOpen || !fee) return null;

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

  const handlePrint = () => {
    window.print();
  };

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
      <div className="bg-white rounded-2xl max-w-md w-full p-8 relative print:shadow-none">
        <button
          onClick={onClose}
          className="absolute top-4 right-4 text-gray-400 hover:text-gray-600 print:hidden"
        >
          <X className="w-6 h-6" />
        </button>

        <div className="text-center mb-6">
          <div className="w-16 h-16 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-4">
            <CheckCircle className="w-10 h-10 text-green-600" />
          </div>
          <h2 className="text-2xl font-bold text-gray-900">Comprovante de Pagamento</h2>
        </div>

        <div className="space-y-4 border-t border-b border-gray-200 py-6">
          <div>
            <p className="text-sm text-gray-500">Mensalidade</p>
            <p className="text-lg font-semibold text-gray-900">#{fee.id}</p>
          </div>

          <div>
            <p className="text-sm text-gray-500">Valor Pago</p>
            <p className="text-2xl font-bold text-green-600">{formatCurrency(fee.valor)}</p>
          </div>

          <div>
            <p className="text-sm text-gray-500">Data do Pagamento</p>
            <p className="text-lg font-semibold text-gray-900">
              {fee.pago_em ? formatDate(fee.pago_em) : '-'}
            </p>
          </div>

          <div>
            <p className="text-sm text-gray-500">Vencimento</p>
            <p className="text-lg font-semibold text-gray-900">{formatDate(fee.vencimento)}</p>
          </div>

          <div>
            <p className="text-sm text-gray-500">Status</p>
            <span className="inline-flex items-center space-x-1 px-3 py-1 bg-green-100 text-green-800 rounded-full text-sm font-medium">
              <CheckCircle className="w-4 h-4" />
              <span>Pago</span>
            </span>
          </div>
        </div>

        <div className="mt-6 text-center text-sm text-gray-500">
          <p>TeamFees - Gestão de Mensalidades</p>
          <p className="mt-1">Pagamento confirmado via PIX</p>
        </div>

        <div className="mt-6 flex gap-3 print:hidden">
          <button
            onClick={handlePrint}
            className="flex-1 flex items-center justify-center space-x-2 bg-blue-600 hover:bg-blue-700 text-white font-semibold py-3 px-4 rounded-lg transition"
          >
            <Download className="w-5 h-5" />
            <span>Imprimir/Salvar PDF</span>
          </button>
        </div>
      </div>
    </div>
  );
}
