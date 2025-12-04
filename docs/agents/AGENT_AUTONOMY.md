# Darwin Scaffold Studio — Guia de Autonomia dos Agentes
# Criado: 2025-11-07 23:52:00 -03
# Autor: Dr. Demetrios Agourakis

## Objetivo
- Garantir liberdade total para operar o Scaffold Studio mantendo padrão científico Q1.
- Foco em pipelines MicroCT/SEM, validações estruturais, integração com `darwin-core` e Notion.

## Princípios
1. **Autonomia**
   Execução direta de scripts (Streamlit, preprocessamento, validações) sem confirmação adicional.

2. **Rigor Científico**
   Resultados relevantes devem ser rastreáveis: scripts versionados, datasets com DOI, relatórios no Notion quando agregarem valor.

3. **Integração Darwin**
   Reutilizar serviços do `darwin-core` (GraphRAG, Multi-AI) quando fizer sentido. Manter compatibilidade da API e do frontend.

4. **Memória**
   Registrar insights estruturais (novas métricas, protocolos) via `update_memory` ou sincronização Notion.

5. **Automação**
   Sempre preferir scripts em `scripts/` e workflows CI/CD para repetição (ex.: geração de relatórios, sincronização Zenodo).

## Fluxo Recomendado
1. `scripts/automation/sync_darwin_assets.py` (se precisar atualizar Notion).
2. Rodar pipelines (preprocessamento, análises 3D, geração de métricas).
3. Atualizar documentação mínima (`docs/`, changelog) quando houver resultado científico novo.
4. Publicar datasets/resultados via Zenodo sempre que aplicável.

## Regras Simplificadas
- Sem necessidade de timestamps automáticos.
- Sem confirmações antes de rodar comandos.
- Apenas mantenha versionamento claro e relatos científicos relevantes.

