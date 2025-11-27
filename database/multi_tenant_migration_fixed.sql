-- ============================================
-- MIGRAÇÃO PARA MULTI-TENANT - CORRIGIDA
-- ValleFy - Sistema de Gestão de Mensalidades
-- ============================================

-- 1. CRIAR TABELA DE TENANTS
-- ============================================
CREATE TABLE IF NOT EXISTS tenants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_name VARCHAR(100) NOT NULL,
    business_type VARCHAR(50) NOT NULL CHECK (business_type IN ('academia', 'time', 'escola', 'estudio', 'corrida', 'outro')),
    cnpj VARCHAR(18),
    subdomain VARCHAR(50) UNIQUE,
    
    -- Plano e Status
    plan VARCHAR(20) DEFAULT 'trial' CHECK (plan IN ('trial', 'basic', 'pro', 'premium')),
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'suspended', 'cancelled')),
    
    -- Trial
    trial_ends_at TIMESTAMP,
    
    -- Configurações
    settings JSONB DEFAULT '{"max_members": 30, "features": []}'::jsonb,
    
    -- Auditoria
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    
    CONSTRAINT unique_subdomain UNIQUE (subdomain)
);

CREATE INDEX IF NOT EXISTS idx_tenants_status ON tenants(status);
CREATE INDEX IF NOT EXISTS idx_tenants_plan ON tenants(plan);
CREATE INDEX IF NOT EXISTS idx_tenants_subdomain ON tenants(subdomain);

-- ============================================
-- 2. CRIAR TABELA BILLING_CYCLES
-- ============================================
CREATE TABLE IF NOT EXISTS billing_cycle (
    id SERIAL PRIMARY KEY,
    tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    due_day INTEGER NOT NULL CHECK (due_day BETWEEN 1 AND 31),
    amount_cents INTEGER NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_billing_cycle_tenant ON billing_cycle(tenant_id);
CREATE INDEX IF NOT EXISTS idx_billing_cycle_active ON billing_cycle(tenant_id, is_active);

-- ============================================
-- 3. ADICIONAR tenant_id NAS TABELAS EXISTENTES
-- ============================================

-- Member (singular)
ALTER TABLE member ADD COLUMN IF NOT EXISTS tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE;
CREATE INDEX IF NOT EXISTS idx_member_tenant ON member(tenant_id);
CREATE INDEX IF NOT EXISTS idx_member_tenant_active ON member(tenant_id, is_active);

-- Member Fee (singular)
ALTER TABLE member_fee ADD COLUMN IF NOT EXISTS tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE;
CREATE INDEX IF NOT EXISTS idx_member_fee_tenant ON member_fee(tenant_id);
CREATE INDEX IF NOT EXISTS idx_member_fee_tenant_status ON member_fee(tenant_id, status);

-- Payment (singular)
ALTER TABLE payment ADD COLUMN IF NOT EXISTS tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE;
CREATE INDEX IF NOT EXISTS idx_payment_tenant ON payment(tenant_id);

-- Member Invitation (se existir)
DO $$ 
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'member_invitation') THEN
        ALTER TABLE member_invitation ADD COLUMN IF NOT EXISTS tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE;
        CREATE INDEX IF NOT EXISTS idx_member_invitation_tenant ON member_invitation(tenant_id);
    END IF;
END $$;

-- ============================================
-- 4. HABILITAR EXTENSÃO PGCRYPTO (para digest)
-- ============================================
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ============================================
-- 5. FUNÇÃO PARA CRIAR TENANT + ADMIN
-- ============================================
CREATE OR REPLACE FUNCTION create_tenant_with_admin(
    p_business_name VARCHAR,
    p_business_type VARCHAR,
    p_cnpj VARCHAR,
    p_admin_name VARCHAR,
    p_admin_email VARCHAR,
    p_admin_phone VARCHAR,
    p_admin_cpf VARCHAR,
    p_password_hash VARCHAR DEFAULT NULL
) RETURNS TABLE(tenant_id UUID, admin_id INTEGER, trial_ends_at TIMESTAMP) AS $$
DECLARE
    v_tenant_id UUID;
    v_admin_id INTEGER;
    v_subdomain VARCHAR;
    v_trial_ends TIMESTAMP;
    v_password_hash VARCHAR;
BEGIN
    -- Gerar subdomain único
    v_subdomain := lower(regexp_replace(p_business_name, '[^a-zA-Z0-9]', '', 'g'));
    v_subdomain := substring(v_subdomain, 1, 30) || '-' || substring(md5(random()::text), 1, 6);
    
    -- Trial de 14 dias
    v_trial_ends := NOW() + INTERVAL '14 days';
    
    -- 1. Criar Tenant
    INSERT INTO tenants (
        business_name, 
        business_type, 
        cnpj, 
        subdomain, 
        plan, 
        status, 
        trial_ends_at,
        settings
    ) VALUES (
        p_business_name,
        p_business_type,
        p_cnpj,
        v_subdomain,
        'trial',
        'active',
        v_trial_ends,
        jsonb_build_object(
            'max_members', 30,
            'features', ARRAY['basic_billing', 'pix', 'whatsapp']
        )
    ) RETURNING id INTO v_tenant_id;
    
    -- 2. Criar Admin User
    -- Se não passou hash, usar senha padrão (últimos 6 dígitos do CPF)
    IF p_password_hash IS NULL THEN
        v_password_hash := '$2a$12$defaulthashaqui'; -- Será substituído no backend
    ELSE
        v_password_hash := p_password_hash;
    END IF;
    
    INSERT INTO member (
        tenant_id,
        full_name,
        email,
        phone_whatsapp,
        cpf,
        role,
        is_active,
        password_hash,
        created_at
    ) VALUES (
        v_tenant_id,
        p_admin_name,
        p_admin_email,
        p_admin_phone,
        p_admin_cpf,
        'ADMIN',
        true,
        v_password_hash,
        NOW()
    ) RETURNING id INTO v_admin_id;
    
    -- Retornar dados
    RETURN QUERY SELECT v_tenant_id, v_admin_id, v_trial_ends;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 6. FUNÇÃO PARA VERIFICAR LIMITES DO PLANO
-- ============================================
CREATE OR REPLACE FUNCTION check_tenant_limits(p_tenant_id UUID) 
RETURNS TABLE(
    current_members INT,
    max_members INT,
    can_add_member BOOLEAN,
    plan VARCHAR,
    status VARCHAR
) AS $$
DECLARE
    v_current_members INT;
    v_max_members INT;
    v_plan VARCHAR;
    v_status VARCHAR;
BEGIN
    -- Buscar configurações do tenant
    SELECT 
        t.plan,
        t.status,
        (t.settings->>'max_members')::INT
    INTO v_plan, v_status, v_max_members
    FROM tenants t
    WHERE t.id = p_tenant_id;
    
    -- Contar membros ativos
    SELECT COUNT(*) INTO v_current_members
    FROM member
    WHERE tenant_id = p_tenant_id AND is_active = true;
    
    -- Retornar resultado
    RETURN QUERY SELECT 
        v_current_members,
        v_max_members,
        (v_current_members < v_max_members AND v_status = 'active') as can_add_member,
        v_plan,
        v_status;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 7. TRIGGER PARA ATUALIZAR updated_at
-- ============================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_tenants_updated_at ON tenants;
CREATE TRIGGER update_tenants_updated_at 
    BEFORE UPDATE ON tenants
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_billing_cycle_updated_at ON billing_cycle;
CREATE TRIGGER update_billing_cycle_updated_at 
    BEFORE UPDATE ON billing_cycle
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- 8. VIEW PARA DASHBOARD DE TENANTS
-- ============================================
CREATE OR REPLACE VIEW v_tenant_stats AS
SELECT 
    t.id as tenant_id,
    t.business_name,
    t.business_type,
    t.plan,
    t.status,
    t.trial_ends_at,
    t.created_at,
    
    -- Contadores
    COUNT(DISTINCT m.id) as total_members,
    COUNT(DISTINCT CASE WHEN m.is_active THEN m.id END) as active_members,
    COUNT(DISTINCT mf.id) as total_fees,
    COUNT(DISTINCT CASE WHEN mf.status = 'PAID' THEN mf.id END) as paid_fees,
    
    -- Valores
    COALESCE(SUM(CASE WHEN mf.status = 'OPEN' THEN mf.amount_cents END), 0) as open_amount_cents,
    COALESCE(SUM(CASE WHEN mf.status = 'PAID' THEN mf.amount_cents END), 0) as paid_amount_cents,
    
    -- Último pagamento
    MAX(p.paid_at) as last_payment_at
    
FROM tenants t
LEFT JOIN member m ON m.tenant_id = t.id
LEFT JOIN member_fee mf ON mf.tenant_id = t.id
LEFT JOIN payment p ON p.tenant_id = t.id
GROUP BY t.id, t.business_name, t.business_type, t.plan, t.status, t.trial_ends_at, t.created_at;

-- ============================================
-- 9. POLÍTICAS DE SEGURANÇA (RLS) - OPCIONAL
-- ============================================
-- Descomente se quiser usar Row Level Security

-- ALTER TABLE member ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE member_fee ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE payment ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE billing_cycle ENABLE ROW LEVEL SECURITY;

-- DROP POLICY IF EXISTS tenant_isolation_member ON member;
-- CREATE POLICY tenant_isolation_member ON member
--     FOR ALL
--     USING (tenant_id = current_setting('app.current_tenant_id', true)::UUID);

-- DROP POLICY IF EXISTS tenant_isolation_fee ON member_fee;
-- CREATE POLICY tenant_isolation_fee ON member_fee
--     FOR ALL
--     USING (tenant_id = current_setting('app.current_tenant_id', true)::UUID);

-- DROP POLICY IF EXISTS tenant_isolation_payment ON payment;
-- CREATE POLICY tenant_isolation_payment ON payment
--     FOR ALL
--     USING (tenant_id = current_setting('app.current_tenant_id', true)::UUID);

-- DROP POLICY IF EXISTS tenant_isolation_cycle ON billing_cycle;
-- CREATE POLICY tenant_isolation_cycle ON billing_cycle
--     FOR ALL
--     USING (tenant_id = current_setting('app.current_tenant_id', true)::UUID);

-- ============================================
-- FIM DA MIGRAÇÃO
-- ============================================

-- Verificar estrutura criada
SELECT 
    'Tenants' as tabela, 
    COUNT(*) as registros 
FROM tenants
UNION ALL
SELECT 
    'Members com tenant_id', 
    COUNT(*) 
FROM member 
WHERE tenant_id IS NOT NULL;

SELECT 'Migração concluída com sucesso!' as status;
