-- Adicionar coluna exempt_reason na tabela member_fee
ALTER TABLE member_fee ADD COLUMN IF NOT EXISTS exempt_reason TEXT;

-- Atualizar enum de status para incluir EXEMPT
-- Nota: PostgreSQL não permite adicionar valores a enums existentes facilmente
-- Se necessário, você pode recriar o tipo ou usar CHECK constraint
