import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { 
  DollarSign, Users, Calendar, TrendingUp, 
  CheckCircle, Smartphone, Zap, Shield,
  ArrowRight, Star, MessageCircle
} from 'lucide-react';
import { tenantService } from '../services/tenantService';
import { SignupRequest } from '../types';

export default function Landing() {
  const navigate = useNavigate();
  const [showSignup, setShowSignup] = useState(false);

  return (
    <div className="min-h-screen bg-white">
      {/* Header */}
      <header className="fixed top-0 w-full bg-white/95 backdrop-blur-sm shadow-sm z-50">
        <div className="container mx-auto px-4 py-4 flex justify-between items-center">
          <div className="flex items-center gap-2">
            <div className="w-10 h-10 bg-gradient-to-br from-blue-600 to-purple-600 rounded-lg flex items-center justify-center">
              <DollarSign className="w-6 h-6 text-white" />
            </div>
            <span className="text-2xl font-bold bg-gradient-to-r from-blue-600 to-purple-600 bg-clip-text text-transparent">
              TeamFees
            </span>
          </div>
          <div className="flex gap-4">
            <button 
              onClick={() => navigate('/login')}
              className="px-4 py-2 text-gray-700 hover:text-blue-600 font-medium"
            >
              Entrar
            </button>
            <button 
              onClick={() => setShowSignup(true)}
              className="px-6 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-medium transition"
            >
              Teste Grátis
            </button>
          </div>
        </div>
      </header>

      {/* Hero Section */}
      <section className="pt-32 pb-20 px-4 bg-gradient-to-br from-blue-50 via-purple-50 to-pink-50">
        <div className="container mx-auto text-center max-w-4xl">
          <div className="inline-flex items-center gap-2 bg-blue-100 text-blue-700 px-4 py-2 rounded-full text-sm font-medium mb-6">
            <Zap className="w-4 h-4" />
            14 dias grátis • Sem cartão de crédito
          </div>
          
          <h1 className="text-5xl md:text-6xl font-bold text-gray-900 mb-6 leading-tight">
            Gestão de Mensalidades
            <span className="block bg-gradient-to-r from-blue-600 to-purple-600 bg-clip-text text-transparent">
              Simples e Poderosa
            </span>
          </h1>
          
          <p className="text-xl text-gray-600 mb-8 max-w-2xl mx-auto">
            Controle completo de mensalidades para academias, times esportivos, 
            escolas e qualquer negócio com pagamentos recorrentes.
          </p>

          <div className="flex flex-col sm:flex-row gap-4 justify-center mb-12">
            <button 
              onClick={() => setShowSignup(true)}
              className="px-8 py-4 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-semibold text-lg transition flex items-center justify-center gap-2"
            >
              Começar Agora <ArrowRight className="w-5 h-5" />
            </button>
            <button 
              onClick={() => document.getElementById('features')?.scrollIntoView({ behavior: 'smooth' })}
              className="px-8 py-4 bg-white hover:bg-gray-50 text-gray-700 rounded-lg font-semibold text-lg transition border-2 border-gray-200"
            >
              Ver Recursos
            </button>
          </div>

          <div className="flex items-center justify-center gap-8 text-sm text-gray-600">
            <div className="flex items-center gap-2">
              <CheckCircle className="w-5 h-5 text-green-500" />
              <span>Sem taxa de setup</span>
            </div>
            <div className="flex items-center gap-2">
              <CheckCircle className="w-5 h-5 text-green-500" />
              <span>Suporte incluído</span>
            </div>
            <div className="flex items-center gap-2">
              <CheckCircle className="w-5 h-5 text-green-500" />
              <span>Cancele quando quiser</span>
            </div>
          </div>
        </div>
      </section>

      {/* Features Section */}
      <section id="features" className="py-20 px-4">
        <div className="container mx-auto max-w-6xl">
          <div className="text-center mb-16">
            <h2 className="text-4xl font-bold text-gray-900 mb-4">
              Tudo que você precisa em um só lugar
            </h2>
            <p className="text-xl text-gray-600">
              Recursos pensados para facilitar sua gestão
            </p>
          </div>

          <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-8">
            {[
              {
                icon: Users,
                title: 'Gestão de Membros',
                description: 'Cadastre e organize seus alunos, atletas ou associados com facilidade'
              },
              {
                icon: Calendar,
                title: 'Ciclos de Cobrança',
                description: 'Configure mensalidades automáticas com vencimentos personalizados'
              },
              {
                icon: DollarSign,
                title: 'PIX Integrado',
                description: 'Gere QR Codes PIX automaticamente via Mercado Pago'
              },
              {
                icon: MessageCircle,
                title: 'WhatsApp Automático',
                description: 'Envie lembretes e cobranças direto no WhatsApp dos membros'
              },
              {
                icon: TrendingUp,
                title: 'Relatórios Completos',
                description: 'Acompanhe inadimplência, receitas e métricas em tempo real'
              },
              {
                icon: Shield,
                title: 'Seguro e Confiável',
                description: 'Seus dados protegidos com criptografia e backups diários'
              }
            ].map((feature, idx) => (
              <div key={idx} className="bg-white p-6 rounded-xl border-2 border-gray-100 hover:border-blue-200 hover:shadow-lg transition">
                <div className="w-12 h-12 bg-blue-100 rounded-lg flex items-center justify-center mb-4">
                  <feature.icon className="w-6 h-6 text-blue-600" />
                </div>
                <h3 className="text-xl font-semibold text-gray-900 mb-2">
                  {feature.title}
                </h3>
                <p className="text-gray-600">
                  {feature.description}
                </p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Pricing Section */}
      <section className="py-20 px-4 bg-gray-50">
        <div className="container mx-auto max-w-6xl">
          <div className="text-center mb-16">
            <h2 className="text-4xl font-bold text-gray-900 mb-4">
              Planos que cabem no seu bolso
            </h2>
            <p className="text-xl text-gray-600">
              Comece grátis e escolha o melhor plano para você
            </p>
          </div>

          <div className="grid md:grid-cols-3 gap-8 max-w-5xl mx-auto">
            {/* Trial */}
            <div className="bg-white rounded-2xl p-8 border-2 border-gray-200">
              <div className="text-center mb-6">
                <h3 className="text-2xl font-bold text-gray-900 mb-2">Trial</h3>
                <div className="text-4xl font-bold text-gray-900 mb-2">
                  Grátis
                </div>
                <p className="text-gray-600">14 dias</p>
              </div>
              <ul className="space-y-3 mb-8">
                <li className="flex items-start gap-2">
                  <CheckCircle className="w-5 h-5 text-green-500 mt-0.5" />
                  <span className="text-gray-700">Até 30 membros</span>
                </li>
                <li className="flex items-start gap-2">
                  <CheckCircle className="w-5 h-5 text-green-500 mt-0.5" />
                  <span className="text-gray-700">Todos os recursos</span>
                </li>
                <li className="flex items-start gap-2">
                  <CheckCircle className="w-5 h-5 text-green-500 mt-0.5" />
                  <span className="text-gray-700">Suporte por email</span>
                </li>
              </ul>
              <button 
                onClick={() => setShowSignup(true)}
                className="w-full py-3 bg-gray-100 hover:bg-gray-200 text-gray-900 rounded-lg font-semibold transition"
              >
                Começar Trial
              </button>
            </div>

            {/* Básico */}
            <div className="bg-white rounded-2xl p-8 border-2 border-blue-500 relative">
              <div className="absolute -top-4 left-1/2 -translate-x-1/2 bg-blue-500 text-white px-4 py-1 rounded-full text-sm font-semibold">
                Mais Popular
              </div>
              <div className="text-center mb-6">
                <h3 className="text-2xl font-bold text-gray-900 mb-2">Básico</h3>
                <div className="text-4xl font-bold text-gray-900 mb-2">
                  R$ 49
                  <span className="text-lg text-gray-600">/mês</span>
                </div>
                <p className="text-gray-600">Ideal para começar</p>
              </div>
              <ul className="space-y-3 mb-8">
                <li className="flex items-start gap-2">
                  <CheckCircle className="w-5 h-5 text-green-500 mt-0.5" />
                  <span className="text-gray-700">Até 100 membros</span>
                </li>
                <li className="flex items-start gap-2">
                  <CheckCircle className="w-5 h-5 text-green-500 mt-0.5" />
                  <span className="text-gray-700">PIX + WhatsApp</span>
                </li>
                <li className="flex items-start gap-2">
                  <CheckCircle className="w-5 h-5 text-green-500 mt-0.5" />
                  <span className="text-gray-700">Relatórios básicos</span>
                </li>
                <li className="flex items-start gap-2">
                  <CheckCircle className="w-5 h-5 text-green-500 mt-0.5" />
                  <span className="text-gray-700">Suporte prioritário</span>
                </li>
              </ul>
              <button 
                onClick={() => setShowSignup(true)}
                className="w-full py-3 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-semibold transition"
              >
                Começar Agora
              </button>
            </div>

            {/* Pro */}
            <div className="bg-white rounded-2xl p-8 border-2 border-gray-200">
              <div className="text-center mb-6">
                <h3 className="text-2xl font-bold text-gray-900 mb-2">Pro</h3>
                <div className="text-4xl font-bold text-gray-900 mb-2">
                  R$ 99
                  <span className="text-lg text-gray-600">/mês</span>
                </div>
                <p className="text-gray-600">Para crescer</p>
              </div>
              <ul className="space-y-3 mb-8">
                <li className="flex items-start gap-2">
                  <CheckCircle className="w-5 h-5 text-green-500 mt-0.5" />
                  <span className="text-gray-700">Até 500 membros</span>
                </li>
                <li className="flex items-start gap-2">
                  <CheckCircle className="w-5 h-5 text-green-500 mt-0.5" />
                  <span className="text-gray-700">Módulos especializados</span>
                </li>
                <li className="flex items-start gap-2">
                  <CheckCircle className="w-5 h-5 text-green-500 mt-0.5" />
                  <span className="text-gray-700">Relatórios avançados</span>
                </li>
                <li className="flex items-start gap-2">
                  <CheckCircle className="w-5 h-5 text-green-500 mt-0.5" />
                  <span className="text-gray-700">API access</span>
                </li>
              </ul>
              <button 
                onClick={() => setShowSignup(true)}
                className="w-full py-3 bg-gray-100 hover:bg-gray-200 text-gray-900 rounded-lg font-semibold transition"
              >
                Começar Agora
              </button>
            </div>
          </div>
        </div>
      </section>

      {/* CTA Section */}
      <section className="py-20 px-4 bg-gradient-to-br from-blue-600 to-purple-600">
        <div className="container mx-auto max-w-4xl text-center text-white">
          <h2 className="text-4xl font-bold mb-4">
            Pronto para simplificar sua gestão?
          </h2>
          <p className="text-xl mb-8 text-blue-100">
            Comece seu teste grátis agora. Não precisa cartão de crédito.
          </p>
          <button 
            onClick={() => setShowSignup(true)}
            className="px-8 py-4 bg-white hover:bg-gray-100 text-blue-600 rounded-lg font-semibold text-lg transition inline-flex items-center gap-2"
          >
            Começar Teste Grátis <ArrowRight className="w-5 h-5" />
          </button>
        </div>
      </section>

      {/* Footer */}
      <footer className="py-12 px-4 bg-gray-900 text-gray-400">
        <div className="container mx-auto max-w-6xl text-center">
          <div className="flex items-center justify-center gap-2 mb-4">
            <div className="w-8 h-8 bg-gradient-to-br from-blue-600 to-purple-600 rounded-lg flex items-center justify-center">
              <DollarSign className="w-5 h-5 text-white" />
            </div>
            <span className="text-xl font-bold text-white">TeamFees</span>
          </div>
          <p className="mb-4">Gestão de Mensalidades Inteligente</p>
          <p className="text-sm">© 2024 TeamFees. Desenvolvido por Eduardo Valle.</p>
        </div>
      </footer>

      {/* Signup Modal */}
      {showSignup && <SignupModal onClose={() => setShowSignup(false)} />}
    </div>
  );
}

function SignupModal({ onClose }: { onClose: () => void }) {
  const [step, setStep] = useState(1);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  
  const [formData, setFormData] = useState({
    // Dados da empresa/loja
    businessName: '',
    businessType: 'academia',
    cnpj: '',
    
    // Dados do admin
    adminName: '',
    adminEmail: '',
    adminPhone: '',
    adminCpf: '',
    
    // Aceite
    acceptTerms: false
  });

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setLoading(true);

    try {
      const signupData: SignupRequest = {
        business_name: formData.businessName,
        business_type: formData.businessType as any,
        cnpj: formData.cnpj || undefined,
        admin_name: formData.adminName,
        admin_email: formData.adminEmail,
        admin_phone: formData.adminPhone,
        admin_cpf: formData.adminCpf
      };

      await tenantService.signup(signupData);
      setStep(3); // Sucesso
    } catch (err: any) {
      setError(err.response?.data?.error || 'Erro ao criar conta. Tente novamente.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-black/50 flex items-center justify-center p-4 z-50">
      <div className="bg-white rounded-2xl max-w-2xl w-full max-h-[90vh] overflow-y-auto">
        <div className="p-8">
          {/* Header */}
          <div className="flex justify-between items-start mb-6">
            <div>
              <h2 className="text-3xl font-bold text-gray-900 mb-2">
                {step === 3 ? '🎉 Conta Criada!' : 'Comece seu Teste Grátis'}
              </h2>
              <p className="text-gray-600">
                {step === 3 ? 'Enviamos as instruções por email' : '14 dias grátis • Sem cartão de crédito'}
              </p>
            </div>
            <button onClick={onClose} className="text-gray-400 hover:text-gray-600">
              <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
          </div>

          {step === 3 ? (
            // Success State
            <div className="text-center py-8">
              <div className="w-20 h-20 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-6">
                <CheckCircle className="w-10 h-10 text-green-600" />
              </div>
              <h3 className="text-2xl font-bold text-gray-900 mb-4">
                Bem-vindo ao TeamFees!
              </h3>
              <p className="text-gray-600 mb-2">
                Enviamos um email para <strong>{formData.adminEmail}</strong>
              </p>
              <p className="text-gray-600 mb-8">
                com suas credenciais de acesso e próximos passos.
              </p>
              <button 
                onClick={onClose}
                className="px-8 py-3 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-semibold transition"
              >
                Entendi
              </button>
            </div>
          ) : (
            // Form
            <form onSubmit={handleSubmit} className="space-y-6">
              {/* Progress */}
              <div className="flex gap-2 mb-8">
                <div className={`flex-1 h-2 rounded-full ${step >= 1 ? 'bg-blue-600' : 'bg-gray-200'}`} />
                <div className={`flex-1 h-2 rounded-full ${step >= 2 ? 'bg-blue-600' : 'bg-gray-200'}`} />
              </div>

              {step === 1 && (
                <>
                  <h3 className="text-xl font-semibold text-gray-900 mb-4">
                    Dados do seu Negócio
                  </h3>
                  
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      Nome do Negócio *
                    </label>
                    <input
                      type="text"
                      value={formData.businessName}
                      onChange={(e) => setFormData({...formData, businessName: e.target.value})}
                      className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                      placeholder="Ex: Academia Fitness Pro"
                      required
                    />
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      Tipo de Negócio *
                    </label>
                    <select
                      value={formData.businessType}
                      onChange={(e) => setFormData({...formData, businessType: e.target.value})}
                      className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                      required
                    >
                      <option value="academia">Academia / Box</option>
                      <option value="time">Time Esportivo</option>
                      <option value="escola">Escola / Curso</option>
                      <option value="estudio">Estúdio (Dança/Yoga/Pilates)</option>
                      <option value="corrida">Assessoria Esportiva</option>
                      <option value="outro">Outro</option>
                    </select>
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      CNPJ (opcional)
                    </label>
                    <input
                      type="text"
                      value={formData.cnpj}
                      onChange={(e) => setFormData({...formData, cnpj: e.target.value})}
                      className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                      placeholder="00.000.000/0000-00"
                    />
                  </div>

                  <button
                    type="button"
                    onClick={() => setStep(2)}
                    className="w-full py-3 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-semibold transition"
                  >
                    Continuar
                  </button>
                </>
              )}

              {step === 2 && (
                <>
                  <h3 className="text-xl font-semibold text-gray-900 mb-4">
                    Seus Dados (Administrador)
                  </h3>

                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      Nome Completo *
                    </label>
                    <input
                      type="text"
                      value={formData.adminName}
                      onChange={(e) => setFormData({...formData, adminName: e.target.value})}
                      className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                      placeholder="Seu nome completo"
                      required
                    />
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      Email *
                    </label>
                    <input
                      type="email"
                      value={formData.adminEmail}
                      onChange={(e) => setFormData({...formData, adminEmail: e.target.value})}
                      className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                      placeholder="seu@email.com"
                      required
                    />
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      WhatsApp *
                    </label>
                    <input
                      type="tel"
                      value={formData.adminPhone}
                      onChange={(e) => setFormData({...formData, adminPhone: e.target.value})}
                      className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                      placeholder="11999999999"
                      required
                    />
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      CPF *
                    </label>
                    <input
                      type="text"
                      value={formData.adminCpf}
                      onChange={(e) => setFormData({...formData, adminCpf: e.target.value})}
                      className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                      placeholder="000.000.000-00"
                      required
                    />
                    <p className="text-xs text-gray-500 mt-1">
                      Sua senha inicial será os últimos 6 dígitos do CPF
                    </p>
                  </div>

                  <div className="flex items-start gap-2">
                    <input
                      type="checkbox"
                      id="terms"
                      checked={formData.acceptTerms}
                      onChange={(e) => setFormData({...formData, acceptTerms: e.target.checked})}
                      className="mt-1"
                      required
                    />
                    <label htmlFor="terms" className="text-sm text-gray-600">
                      Aceito os termos de uso e política de privacidade
                    </label>
                  </div>

                  {error && (
                    <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-lg text-sm">
                      {error}
                    </div>
                  )}

                  <div className="flex gap-3">
                    <button
                      type="button"
                      onClick={() => setStep(1)}
                      className="flex-1 py-3 bg-gray-100 hover:bg-gray-200 text-gray-700 rounded-lg font-semibold transition"
                    >
                      Voltar
                    </button>
                    <button
                      type="submit"
                      disabled={loading || !formData.acceptTerms}
                      className="flex-1 py-3 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-semibold transition disabled:opacity-50 disabled:cursor-not-allowed"
                    >
                      {loading ? 'Criando...' : 'Criar Conta'}
                    </button>
                  </div>
                </>
              )}
            </form>
          )}
        </div>
      </div>
    </div>
  );
}
