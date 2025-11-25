import { X, Copy, CheckCircle } from 'lucide-react';
import { useState } from 'react';

interface PixModalProps {
  isOpen: boolean;
  onClose: () => void;
  qrCode: string;
  amount: number;
}

export default function PixModal({ isOpen, onClose, qrCode, amount }: PixModalProps) {
  const [copied, setCopied] = useState(false);

  if (!isOpen) return null;

  const formatCurrency = (cents: number) => {
    return new Intl.NumberFormat('pt-BR', {
      style: 'currency',
      currency: 'BRL',
    }).format(cents / 100);
  };

  const copyToClipboard = () => {
    navigator.clipboard.writeText(qrCode);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
      <div className="bg-white rounded-2xl shadow-2xl max-w-md w-full p-6">
        <div className="flex justify-between items-center mb-6">
          <h2 className="text-2xl font-bold text-gray-900">Pagar com PIX</h2>
          <button
            onClick={onClose}
            className="p-2 hover:bg-gray-100 rounded-lg transition"
          >
            <X className="w-6 h-6 text-gray-600" />
          </button>
        </div>

        <div className="text-center mb-6">
          <p className="text-gray-600 mb-2">Valor a pagar</p>
          <p className="text-3xl font-bold text-blue-600">{formatCurrency(amount)}</p>
        </div>

        <div className="bg-gray-50 rounded-xl p-4 mb-6">
          <div className="bg-white p-4 rounded-lg mb-4">
            <img
              src={`https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=${encodeURIComponent(qrCode)}`}
              alt="QR Code PIX"
              className="w-full h-auto"
            />
          </div>

          <div className="space-y-2">
            <p className="text-sm text-gray-600 text-center">
              Escaneie o QR Code com o app do seu banco
            </p>
            <p className="text-xs text-gray-500 text-center">
              ou copie o código PIX abaixo
            </p>
          </div>
        </div>

        <div className="mb-6">
          <div className="flex items-center space-x-2">
            <input
              type="text"
              value={qrCode}
              readOnly
              className="flex-1 px-3 py-2 border border-gray-300 rounded-lg text-sm bg-gray-50"
            />
            <button
              onClick={copyToClipboard}
              className="px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg transition flex items-center space-x-2"
            >
              {copied ? (
                <>
                  <CheckCircle className="w-4 h-4" />
                  <span>Copiado!</span>
                </>
              ) : (
                <>
                  <Copy className="w-4 h-4" />
                  <span>Copiar</span>
                </>
              )}
            </button>
          </div>
        </div>

        <div className="bg-blue-50 border border-blue-200 rounded-lg p-4">
          <p className="text-sm text-blue-800">
            ⏱️ Após o pagamento, a confirmação pode levar alguns minutos.
          </p>
        </div>
      </div>
    </div>
  );
}
