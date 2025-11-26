import { useState } from 'react';
import { Check, Star, Users, Shield, Zap } from 'lucide-react';

interface SignupForm {
  company_name: string;
  owner_name: string;
  email: string;
  phone: string;
  segment: string;
}

export default function Home() {
  const [form, setForm] = useState<SignupForm>({
    company_name: '',
    owner_name: '',
    email: '',
    phone: '',
    segment: 'ACADEMIA'
  });
  const [loading, setLoading] = useState(false);
  const [success, setSuccess] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    
    try {
      const response = await fetch('/api/signup', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(form)
      });
      
      if (response.ok) {
        setSuccess(true);
      }
    } catch (error) {
      console.error('Erro:', error);
    } finally {
      setLoading(false);
    }
  };

  if (success) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 flex items-center justify-center">
        <div className="bg-white p-8 rounded-xl shadow-lg text-center max-w-md">
          <Check className="w-16 h-16 text-green-500 mx-auto mb-4" />
          <h2 className="text-2xl font-bold text-gray-900 mb-2">Cadastro Realizado!</h2>
          <p className="text-gray-600">Em breve entraremos em contato para ativar sua conta.</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100">
      {/* Header */}
      <header className="bg-white shadow-sm">
        <div className="max-w-7xl mx-auto px-4 py-4 flex justify-between items-center">
          <h1 className="text-2xl font-bold text-blue-600">TeamFees</h1>
          <a href="/login" className="text-blue-600 hover:text-blue-700 font-medium">
            Já tenho conta
          </a>
        </div>
      </header>

      <div className="max-w-7xl mx-auto px-4 py-12">
        <div className="grid lg:grid-cols-2 gap-12 items-center">
          
          {/* Landing Content */}
          <div>
            <h1 className="text-5xl font-bold text-gray-900 mb-6">
              Gerencie suas <span className="text-blue-600">mensalidades</span> com facilidade
            </h1>
            <p className="text-xl text-gray-600 mb-8">
              Plataforma completa para academias, times esportivos e escolas. 
              PIX automático, WhatsApp integrado e controle total.
            </p>

            {/* Features */}
            <div className="space-y-4 mb-8">
              <div className="flex items-center space-x-3">
                <Zap className="w-6 h-6 text-blue-600" />
                <span className="text-gray-700">PIX automático via Mercado Pago</span>
              </div>
              <div className="flex items-center space-x-3">
                <Users className="w-6 h-6 text-blue-600" />
                <span className="text-gray-700">WhatsApp para cobranças</span>
              </div>
              <div className="flex items-center space-x-3">
                <Shield className="w-6 h-6 text-blue-600" />
                <span className="text-gray-700">14 dias grátis, sem cartão</span>
              </div>
            </div>

            {/* Pricing */}
            <div className="bg-white p-6 rounded-xl shadow-sm">
              <h3 className="font-bold text-gray-900 mb-4">Planos a partir de:</h3>
              <div className="flex items-baseline space-x-2">
                <span className="text-3xl font-bold text-blue-600">R$ 49</span>
                <span className="text-gray-600">/mês</span>
              </div>
              <p className="text-sm text-gray-500 mt-1">Até 100 membros</p>
            </div>
          </div>

          {/* Signup Form */}
          <div className="bg-white p-8 rounded-xl shadow-lg">
            <h2 className="text-2xl font-bold text-gray-900 mb-6">
              Comece seu teste grátis
            </h2>
            
            <form onSubmit={handleSubmit} className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Nome da Empresa/Time
                </label>
                <input
                  type="text"
                  required
                  value={form.company_name}
                  onChange={(e) => setForm({...form, company_name: e.target.value})}
                  className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  placeholder="Academia Fitness Pro"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Seu Nome
                </label>
                <input
                  type="text"
                  required
                  value={form.owner_name}
                  onChange={(e) => setForm({...form, owner_name: e.target.value})}
                  className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  placeholder="João Silva"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Email
                </label>
                <input
                  type="email"
                  required
                  value={form.email}
                  onChange={(e) => setForm({...form, email: e.target.value})}
                  className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  placeholder="joao@academia.com"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  WhatsApp
                </label>
                <input
                  type="tel"
                  required
                  value={form.phone}
                  onChange={(e) => setForm({...form, phone: e.target.value})}
                  className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  placeholder="(11) 99999-9999"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Segmento
                </label>
                <select
                  value={form.segment}
                  onChange={(e) => setForm({...form, segment: e.target.value})}
                  className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                >
                  <option value="ACADEMIA">Academia</option>
                  <option value="TIME">Time Esportivo</option>
                  <option value="ESCOLA">Escola</option>
                  <option value="ESTUDIO">Estúdio</option>
                  <option value="ASSESSORIA">Assessoria</option>
                </select>
              </div>

              <button
                type="submit"
                disabled={loading}
                className="w-full bg-blue-600 hover:bg-blue-700 text-white font-semibold py-3 px-6 rounded-lg transition disabled:opacity-50"
              >
                {loading ? 'Cadastrando...' : 'Começar Teste Grátis'}
              </button>
            </form>

            <p className="text-xs text-gray-500 text-center mt-4">
              14 dias grátis • Sem cartão de crédito • Cancele quando quiser
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}