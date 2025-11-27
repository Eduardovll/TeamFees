import { useState, useEffect } from 'react';
import Layout from '../components/Layout';
import api from '../services/api';
import { PlanInfo, Tenant } from '../types';
import { CheckCircle, Crown, Zap, X, Copy, Check } from 'lucide-react';
import { format } from 'date-fns';

const PLANS: PlanInfo[] = [
  {
    id: 'trial',
    name: 'Trial',
    price: 0,
    maxMembers: 30,
    features: ['14 dias grátis', 'Todos os recursos', 'Suporte por email']
  },
  {
    id: 'basic',
    name: 'Básico',
    price: 49,
    maxMembers: 100,
    features: ['Até 100 membros', 'PIX + WhatsApp', 'Relatórios básicos', 'Suporte prioritário']
  },
  {
    id: 'pro',
    name: 'Pro',
    price: 99,
    maxMembers: 500,
    features: ['Até 500 membros', 'Módulos especializados', 'Relatórios avançados', 'API access', 'Suporte 24/7']
  },
  {
    id: 'premium',
    name: 'Premium',
    price: 199,
    maxMembers: 999999,
    features: ['Membros ilimitados', 'White-label', 'Customizações', 'Gerente de conta dedicado']
  }
];

export default function Billing() {
  const [tenant, setTenant] = useState<Tenant | null>(null);
  const [loading, setLoading] = useState(true);
  const [showUpgradeModal, setShowUpgradeModal] = useState(false);
  const [selectedPlan, setSelectedPlan] = useState<PlanInfo | null>(null);
  const [pixCode, setPixCode] = useState('');
  const [copied, setCopied] = useState(false);
  const [upgrading, setUpgrading] = useState(false);

  useEffect(() => {
    loadTenant();
  }, []);

  const loadTenant = async () => {
    try {
      const user = JSON.parse(localStorage.getItem('user') || '{}');
      if (user.tenant) {
        setTenant(user.tenant);
      }
    } catch (error) {
      console.error('Erro ao carregar tenant:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleUpgrade = async () => {
    if (!selectedPlan) return;

    setUpgrading(true);
    try {
      const response = await api.post('/tenant/upgrade', {
        plan: selectedPlan.id,
        payment_method: 'pix'
      });

      setPixCode(response.data.pix_code);
    } catch (error: any) {
      alert(error.response?.data?.error || 'Erro ao solicitar upgrade');
    } finally {
      setUpgrading(false);
    }
  };

  const copyPixCode = () => {
    navigator.clipboard.writeText(pixCode);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  const getCurrentPlan = () => {
    return PLANS.find(p => p.id === tenant?.plan) || PLANS[0];
  };

  const canUpgrade = (plan: PlanInfo) => {
    const currentPlan = getCurrentPlan();
    const currentIndex = PLANS.findIndex(p => p.id === currentPlan.id);
    const targetIndex = PLANS.findIndex(p => p.id === plan.id);
    return targetIndex > currentIndex;
  };

  const formatDate = (dateString?: string) => {
    if (!dateString) return '-';
    try {
      return format(new Date(dateString), 'dd/MM/yyyy');
    } catch {
      return dateString;
    }
  };

  const getDaysRemaining = () => {
    if (!tenant?.plan_expires_at && !tenant?.trial_ends_at) return null;
    const expiryDate = new Date(tenant.plan_expires_at || tenant.trial_ends_at || '');
    const today = new Date();
    const diff = Math.ceil((expiryDate.getTime() - today.getTime()) / (1000 * 60 * 60 * 24));
    return diff;
  };

  const daysRemaining = getDaysRemaining();

  if (loading) {
    return (
      <Layout>
        <div className="text-center py-12">
          <div className="text-xl text-gray-600">Carregando...</div>
        </div>
      </Layout>
    );
  }

  const currentPlan = getCurrentPlan();

  return (
    <Layout>
      <div className="max-w-7xl mx-auto">
        <h1 className="text-3xl font-bold text-gray-900 mb-8">💳 Planos e Cobrança</h1>

        {/* Plano Atual */}
        <div className="bg-gradient-to-br from-indigo-600 via-purple-600 to-pink-600 rounded-xl shadow-lg p-8 mb-8 text-white">
          <div className="flex items-start justify-between">
            <div>
              <div className="flex items-center space-x-2 mb-2">
                <Crown className="w-6 h-6" />
                <h2 className="text-2xl font-bold">Plano Atual: {currentPlan.name}</h2>
              </div>
              <p className="text-indigo-100 mb-4">
                {tenant?.business_name}
              </p>
              <div className="space-y-2">
                <p className="text-sm">
                  <strong>Status:</strong> {tenant?.status === 'active' ? '✅ Ativo' : '⚠️ ' + tenant?.status}
                </p>
                {daysRemaining !== null && (
                  <p className="text-sm">
                    <strong>Expira em:</strong> {daysRemaining} dias ({formatDate(tenant?.plan_expires_at || tenant?.trial_ends_at)})
                  </p>
                )}
                <p className="text-sm">
                  <strong>Limite de membros:</strong> {currentPlan.maxMembers === 999999 ? 'Ilimitado' : currentPlan.maxMembers}
                </p>
              </div>
            </div>
            <div className="text-right">
              <div className="text-4xl font-bold mb-2">
                {currentPlan.price === 0 ? 'Grátis' : `R$ ${currentPlan.price}`}
              </div>
              {currentPlan.price > 0 && <div className="text-indigo-100">por mês</div>}
            </div>
          </div>
        </div>

        {/* Planos Disponíveis */}
        <div className="mb-8">
          <h2 className="text-2xl font-bold text-gray-900 mb-6">Planos Disponíveis</h2>
          <div className="grid md:grid-cols-2 lg:grid-cols-4 gap-6">
            {PLANS.map((plan) => {
              const isCurrent = plan.id === tenant?.plan;
              const canUpgradeToPlan = canUpgrade(plan);

              return (
                <div
                  key={plan.id}
                  className={`bg-white rounded-xl shadow-sm border-2 p-6 ${
                    isCurrent ? 'border-purple-500 ring-2 ring-purple-200' : 'border-gray-200'
                  }`}
                >
                  {isCurrent && (
                    <div className="bg-purple-100 text-purple-800 text-xs font-semibold px-3 py-1 rounded-full inline-block mb-4">
                      Plano Atual
                    </div>
                  )}
                  
                  <h3 className="text-xl font-bold text-gray-900 mb-2">{plan.name}</h3>
                  <div className="text-3xl font-bold text-gray-900 mb-4">
                    {plan.price === 0 ? 'Grátis' : `R$ ${plan.price}`}
                    {plan.price > 0 && <span className="text-sm text-gray-600">/mês</span>}
                  </div>

                  <ul className="space-y-2 mb-6">
                    {plan.features.map((feature, idx) => (
                      <li key={idx} className="flex items-start space-x-2 text-sm text-gray-700">
                        <CheckCircle className="w-4 h-4 text-green-500 mt-0.5 flex-shrink-0" />
                        <span>{feature}</span>
                      </li>
                    ))}
                  </ul>

                  {canUpgradeToPlan && (
                    <button
                      onClick={() => {
                        setSelectedPlan(plan);
                        setShowUpgradeModal(true);
                        setPixCode('');
                      }}
                      className="w-full py-2 bg-gradient-to-r from-indigo-600 via-purple-600 to-pink-600 hover:from-indigo-700 hover:via-purple-700 hover:to-pink-700 text-white rounded-lg font-semibold transition shadow-lg hover:shadow-xl"
                    >
                      Fazer Upgrade
                    </button>
                  )}

                  {isCurrent && (
                    <button
                      disabled
                      className="w-full py-2 bg-gray-100 text-gray-400 rounded-lg font-semibold cursor-not-allowed"
                    >
                      Plano Atual
                    </button>
                  )}
                </div>
              );
            })}
          </div>
        </div>

        {/* Informações */}
        <div className="bg-blue-50 border border-blue-200 rounded-lg p-6">
          <h3 className="font-semibold text-blue-900 mb-2">ℹ️ Como funciona o upgrade?</h3>
          <ul className="text-sm text-blue-800 space-y-1">
            <li>• Escolha o plano desejado e clique em "Fazer Upgrade"</li>
            <li>• Será gerado um código PIX para pagamento</li>
            <li>• Após o pagamento, envie o comprovante para nosso suporte</li>
            <li>• Seu plano será ativado em até 24 horas</li>
            <li>• O período de cobrança é mensal a partir da ativação</li>
          </ul>
        </div>
      </div>

      {/* Modal de Upgrade */}
      {showUpgradeModal && selectedPlan && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-xl shadow-2xl w-full max-w-md p-6">
            <div className="flex justify-between items-start mb-4">
              <h2 className="text-2xl font-bold text-gray-900">Upgrade para {selectedPlan.name}</h2>
              <button onClick={() => setShowUpgradeModal(false)} className="text-gray-400 hover:text-gray-600">
                <X className="w-6 h-6" />
              </button>
            </div>

            {!pixCode ? (
              <>
                <div className="mb-6">
                  <div className="bg-gradient-to-r from-indigo-50 to-purple-50 rounded-lg p-4 mb-4">
                    <div className="text-center">
                      <div className="text-4xl font-bold text-gray-900 mb-1">
                        R$ {selectedPlan.price}
                      </div>
                      <div className="text-sm text-gray-600">por mês</div>
                    </div>
                  </div>

                  <h3 className="font-semibold text-gray-900 mb-2">Recursos inclusos:</h3>
                  <ul className="space-y-2">
                    {selectedPlan.features.map((feature, idx) => (
                      <li key={idx} className="flex items-start space-x-2 text-sm text-gray-700">
                        <CheckCircle className="w-4 h-4 text-green-500 mt-0.5" />
                        <span>{feature}</span>
                      </li>
                    ))}
                  </ul>
                </div>

                <button
                  onClick={handleUpgrade}
                  disabled={upgrading}
                  className="w-full py-3 bg-gradient-to-r from-indigo-600 via-purple-600 to-pink-600 hover:from-indigo-700 hover:via-purple-700 hover:to-pink-700 text-white rounded-lg font-semibold transition disabled:opacity-50 shadow-lg hover:shadow-xl"
                >
                  {upgrading ? 'Gerando PIX...' : 'Gerar PIX para Pagamento'}
                </button>
              </>
            ) : (
              <>
                <div className="mb-6">
                  <div className="bg-green-50 border border-green-200 rounded-lg p-4 mb-4">
                    <div className="flex items-center space-x-2 text-green-800 mb-2">
                      <Zap className="w-5 h-5" />
                      <span className="font-semibold">PIX Gerado com Sucesso!</span>
                    </div>
                    <p className="text-sm text-green-700">
                      Copie o código abaixo e cole no seu app de pagamento
                    </p>
                  </div>

                  <div className="bg-gray-50 border border-gray-300 rounded-lg p-4 mb-4">
                    <p className="text-xs text-gray-600 mb-2">Código PIX:</p>
                    <p className="text-sm font-mono break-all text-gray-900 mb-3">
                      {pixCode}
                    </p>
                    <button
                      onClick={copyPixCode}
                      className="w-full py-2 bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg font-semibold transition flex items-center justify-center space-x-2"
                    >
                      {copied ? (
                        <>
                          <Check className="w-4 h-4" />
                          <span>Copiado!</span>
                        </>
                      ) : (
                        <>
                          <Copy className="w-4 h-4" />
                          <span>Copiar Código</span>
                        </>
                      )}
                    </button>
                  </div>

                  <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-4">
                    <p className="text-sm text-yellow-800">
                      <strong>⚠️ Importante:</strong> Após realizar o pagamento, envie o comprovante para nosso WhatsApp: <strong>(11) 99999-9999</strong>
                    </p>
                  </div>
                </div>

                <button
                  onClick={() => setShowUpgradeModal(false)}
                  className="w-full py-3 bg-gray-200 hover:bg-gray-300 text-gray-700 rounded-lg font-semibold transition"
                >
                  Fechar
                </button>
              </>
            )}
          </div>
        </div>
      )}
    </Layout>
  );
}
