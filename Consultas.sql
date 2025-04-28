--Consumo por produto e mês
WITH FiltorDatas AS (
    SELECT 
        DATE '2025-02-01' AS dt_inicio,
        DATE '2025-02-28' AS dt_fim
)
SELECT 
    produto_id,
    SUM(qtde_vendida) AS ttl_consumo
FROM 
    public.venda, FiltorDatas
WHERE 
    data_emissao BETWEEN dt_inicio AND dt_fim
GROUP BY 
    produto_id
ORDER BY 
    ttl_consumo DESC;



---PRODUTOS COM REQUISIÇÃO PENDENTE
WITH FiltorDatas AS (
    SELECT 
        DATE '2025-02-01' AS dt_inicio,
        DATE '2025-02-28' AS dt_fim
)
SELECT 
    produto_id,
    descricao_produto,
    SUM(qtde_pedida) AS qtde_ttl_pedida,
    SUM(qtde_pendente) AS qtde_ttl_pendente
FROM 
    public.pedido_compra, FiltorDatas
WHERE 
    qtde_pendente > 0
    AND data_pedido BETWEEN dt_inicio AND dt_fim
GROUP BY 
    produto_id, descricao_produto
HAVING 
    SUM(qtde_pendente) > 0
ORDER BY 
    qtde_ttl_pendente DESC;



---PRODUTOS NÃO CONSUMIDOS E NÃO RECEBIDOS
WITH 
FiltroDatas AS (
    SELECT DATE '2025-02-01' AS dt_inicio, DATE '2025-02-28' AS dt_fim 
),
produtos_pedidos AS (
    SELECT 
        produto_id,
        descricao_produto,
        ordem_compra,
        SUM(qtde_pedida) AS qtde_pedida_ttl
    FROM 
        public.pedido_compra, FiltroDatas
    WHERE 
        data_pedido BETWEEN dt_inicio AND dt_fim
        AND qtde_pedida > 0
    GROUP BY 
        produto_id, descricao_produto,ordem_compra
),
produtos_recebidos AS (
    SELECT DISTINCT 
        produto_id,
        ordem_compra,
        qtde_recebida
    FROM 
        public.entradas_mercadoria, FiltroDatas
    WHERE 
        qtde_recebida > 0
        AND data_entrada BETWEEN dt_inicio AND dt_fim
),
produtos_consumidos AS (
    SELECT DISTINCT 
        produto_id
    FROM 
        public.venda, FiltroDatas
    WHERE 
        qtde_vendida > 0
        AND data_emissao BETWEEN dt_inicio AND dt_fim
)
SELECT 
    pp.produto_id,
    pp.descricao_produto,
    pp.qtde_pedida_ttl AS qtde_pedida,
    pr.qtde_recebida as qtde_recebida
FROM 
    produtos_pedidos pp
LEFT JOIN 
    produtos_recebidos pr ON pp.produto_id = pr.produto_id AND pp.ordem_compra = pr.ordem_compra
LEFT JOIN 
    produtos_consumidos pc ON pp.produto_id = pc.produto_id
  
WHERE 
    pr.produto_id IS NULL  
    AND pc.produto_id IS NULL  
    AND pp.qtde_pedida_ttl > 0
ORDER BY 
    pp.qtde_pedida_ttl
	DESC;
---ETL

SELECT
    CONCAT(ped.produto_id, ' - ',
     COALESCE(ped.descricao_produto, '')) AS produto,
    SUM(ped.qtde_pedida) AS qtde_requisitada,
    TO_CHAR(ped.data_pedido, 'DD/MM/YYYY') AS data_solicitacao
FROM
    public.pedido_compra ped
GROUP BY
    ped.produto_id, ped.descricao_produto, ped.data_pedido
HAVING
    SUM(ped.qtde_pedida) > 10

UNION ALL

SELECT
    CONCAT(vend.produto_id, ' - ',
        COALESCE(ped.descricao_produto, '')) AS produto,
    SUM(vend.qtde_vendida) AS qtde_requisitada,
    TO_CHAR(vend.data_emissao, 'DD/MM/YYYY') AS data_solicitacao
FROM
    public.venda vend
LEFT JOIN
    public.pedido_compra ped
ON
    vend.produto_id = ped.produto_id
GROUP BY
    vend.produto_id, ped.descricao_produto, vend.data_emissao
HAVING
    SUM(vend.qtde_vendida) > 10
ORDER BY
    produto;

