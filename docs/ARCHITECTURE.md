# Darwin Scaffold Studio - Arquitetura Enterprise

## Visão Arquitetural

### Princípios de Design
1. **Domain-Driven Design (DDD)** - Modelagem baseada no domínio científico
2. **Event-Driven Architecture** - Processamento assíncrono de análises pesadas
3. **CQRS** - Separação de comandos (mutações) e queries (leituras)
4. **Microservices** - Serviços independentes e escaláveis
5. **Scientific Reproducibility** - Versionamento de dados, modelos e resultados

---

## Arquitetura de Alto Nível

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              CLIENTS                                         │
├─────────────────────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐ │
│  │   Web App   │  │ Mobile App  │  │  CLI Tool   │  │   Jupyter/Pluto    │ │
│  │  (Next.js)  │  │  (Flutter)  │  │  (Julia)    │  │   Notebooks        │ │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘  └──────────┬──────────┘ │
└─────────┼────────────────┼────────────────┼────────────────────┼────────────┘
          │                │                │                    │
          ▼                ▼                ▼                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                           API GATEWAY                                        │
│  ┌─────────────────────────────────────────────────────────────────────────┐│
│  │                         Kong / Traefik                                  ││
│  │  • Rate Limiting  • Auth (JWT/OAuth2)  • Load Balancing  • SSL/TLS    ││
│  │  • Request Routing  • API Versioning  • Circuit Breaker  • Logging    ││
│  └─────────────────────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────────────────┘
          │
          ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                      SERVICE MESH (Istio/Linkerd)                           │
│  ┌────────────────────────────────────────────────────────────────────────┐ │
│  │  • mTLS between services  • Observability  • Traffic Management       │ │
│  └────────────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────────┘
          │
          ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                         MICROSERVICES LAYER                                  │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐             │
│  │   API Gateway   │  │  Auth Service   │  │  User Service   │             │
│  │    Service      │  │   (Keycloak)    │  │                 │             │
│  │    (GraphQL)    │  │                 │  │  • Profiles     │             │
│  │                 │  │  • OAuth2/OIDC  │  │  • Teams        │             │
│  │  • Federation   │  │  • RBAC         │  │  • Quotas       │             │
│  │  • Schema       │  │  • SSO          │  │  • Preferences  │             │
│  └────────┬────────┘  └─────────────────┘  └─────────────────┘             │
│           │                                                                  │
│  ─────────┴──────────────────────────────────────────────────────────────── │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────────┐│
│  │                    DOMAIN SERVICES (Julia)                              ││
│  ├─────────────────────────────────────────────────────────────────────────┤│
│  │                                                                         ││
│  │  ┌───────────────┐  ┌───────────────┐  ┌───────────────┐               ││
│  │  │   Material    │  │    Blend      │  │    Drug       │               ││
│  │  │   Service     │  │   Service     │  │   Service     │               ││
│  │  │               │  │               │  │               │               ││
│  │  │ • Search      │  │ • Predict     │  │ • PK/PD       │               ││
│  │  │ • Compare     │  │ • Optimize    │  │ • Compat.     │               ││
│  │  │ • Properties  │  │ • Miscibility │  │ • Release     │               ││
│  │  └───────────────┘  └───────────────┘  └───────────────┘               ││
│  │                                                                         ││
│  │  ┌───────────────┐  ┌───────────────┐  ┌───────────────┐               ││
│  │  │  Formulation  │  │   Biomarker   │  │  Simulation   │               ││
│  │  │   Service     │  │   Service     │  │   Service     │               ││
│  │  │               │  │               │  │               │               ││
│  │  │ • Design      │  │ • Panels      │  │ • Release     │               ││
│  │  │ • Validate    │  │ • Assays      │  │ • Growth      │               ││
│  │  │ • Recommend   │  │ • Protocols   │  │ • Mechanics   │               ││
│  │  └───────────────┘  └───────────────┘  └───────────────┘               ││
│  │                                                                         ││
│  └─────────────────────────────────────────────────────────────────────────┘│
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────────┐│
│  │                    COMPUTE SERVICES                                     ││
│  ├─────────────────────────────────────────────────────────────────────────┤│
│  │                                                                         ││
│  │  ┌───────────────┐  ┌───────────────┐  ┌───────────────┐               ││
│  │  │   MicroCT     │  │ Optimization  │  │     ML        │               ││
│  │  │   Analysis    │  │   Engine      │  │   Inference   │               ││
│  │  │               │  │               │  │               │               ││
│  │  │ • Segment     │  │ • NSGA-II     │  │ • Property    │               ││
│  │  │ • Metrics     │  │ • Bayesian    │  │   Prediction  │               ││
│  │  │ • 3D Recon    │  │ • TuRBO       │  │ • SAM/Vision  │               ││
│  │  │               │  │               │  │ • LLM Agent   │               ││
│  │  │ [GPU-enabled] │  │ [Distributed] │  │ [GPU-enabled] │               ││
│  │  └───────────────┘  └───────────────┘  └───────────────┘               ││
│  │                                                                         ││
│  └─────────────────────────────────────────────────────────────────────────┘│
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────────┐│
│  │                    SUPPORT SERVICES                                     ││
│  ├─────────────────────────────────────────────────────────────────────────┤│
│  │                                                                         ││
│  │  ┌───────────────┐  ┌───────────────┐  ┌───────────────┐               ││
│  │  │   Report      │  │  Notification │  │    Audit      │               ││
│  │  │   Generator   │  │   Service     │  │    Service    │               ││
│  │  │               │  │               │  │               │               ││
│  │  │ • PDF/LaTeX   │  │ • Email       │  │ • Activity    │               ││
│  │  │ • Templates   │  │ • Webhooks    │  │ • Compliance  │               ││
│  │  │ • Citations   │  │ • Real-time   │  │ • Provenance  │               ││
│  │  └───────────────┘  └───────────────┘  └───────────────┘               ││
│  │                                                                         ││
│  └─────────────────────────────────────────────────────────────────────────┘│
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
          │
          ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                         EVENT BUS / MESSAGE BROKER                          │
│  ┌─────────────────────────────────────────────────────────────────────────┐│
│  │                    Apache Kafka / RabbitMQ                              ││
│  │                                                                         ││
│  │  Topics:                                                                ││
│  │  • analysis.microct.submitted    • optimization.started                ││
│  │  • analysis.microct.completed    • optimization.completed              ││
│  │  • formulation.designed          • report.generated                    ││
│  │  • experiment.created            • notification.send                   ││
│  │                                                                         ││
│  └─────────────────────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────────────────┘
          │
          ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                           DATA LAYER                                         │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐             │
│  │   PostgreSQL    │  │   TimescaleDB   │  │   MongoDB       │             │
│  │                 │  │                 │  │                 │             │
│  │ • Materials     │  │ • Experiments   │  │ • MicroCT Raw   │             │
│  │ • Drugs         │  │ • Time-series   │  │ • 3D Models     │             │
│  │ • Users         │  │ • Sensor data   │  │ • Unstructured  │             │
│  │ • Projects      │  │ • Metrics       │  │                 │             │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘             │
│                                                                              │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐             │
│  │   Neo4j         │  │   Redis         │  │   MinIO/S3      │             │
│  │                 │  │                 │  │                 │             │
│  │ • Ontologies    │  │ • Cache         │  │ • Images        │             │
│  │ • Knowledge     │  │ • Sessions      │  │ • Datasets      │             │
│  │   Graph         │  │ • Real-time     │  │ • Models        │             │
│  │ • Relations     │  │ • Pub/Sub       │  │ • Reports       │             │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘             │
│                                                                              │
│  ┌─────────────────┐  ┌─────────────────┐                                   │
│  │  Elasticsearch  │  │   ClickHouse    │                                   │
│  │                 │  │                 │                                   │
│  │ • Full-text     │  │ • Analytics     │                                   │
│  │   search        │  │ • OLAP          │                                   │
│  │ • Literature    │  │ • Aggregations  │                                   │
│  │ • Logs          │  │                 │                                   │
│  └─────────────────┘  └─────────────────┘                                   │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Domain Model (DDD)

### Bounded Contexts

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         BOUNDED CONTEXTS                                     │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────────┐│
│  │                     MATERIAL SCIENCE CONTEXT                            ││
│  │                                                                         ││
│  │  Aggregates:                                                            ││
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐                     ││
│  │  │  Material   │  │   Blend     │  │  Composite  │                     ││
│  │  │             │  │             │  │             │                     ││
│  │  │ - id        │  │ - id        │  │ - id        │                     ││
│  │  │ - name      │  │ - components│  │ - matrix    │                     ││
│  │  │ - category  │  │ - ratios    │  │ - filler    │                     ││
│  │  │ - mechanical│  │ - predicted │  │ - interface │                     ││
│  │  │ - thermal   │  │   Properties│  │ - properties│                     ││
│  │  │ - surface   │  │ - confidence│  │             │                     ││
│  │  └─────────────┘  └─────────────┘  └─────────────┘                     ││
│  │                                                                         ││
│  │  Value Objects: MechanicalProperties, ThermalProperties, Density       ││
│  │  Domain Events: MaterialCreated, BlendPredicted, PropertyUpdated       ││
│  │                                                                         ││
│  └─────────────────────────────────────────────────────────────────────────┘│
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────────┐│
│  │                     DRUG DELIVERY CONTEXT                               ││
│  │                                                                         ││
│  │  Aggregates:                                                            ││
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐                     ││
│  │  │    Drug     │  │  Formulation│  │  Release    │                     ││
│  │  │             │  │             │  │   Profile   │                     ││
│  │  │ - drugbankId│  │ - scaffold  │  │             │                     ││
│  │  │ - pk_params │  │ - drug      │  │ - model     │                     ││
│  │  │ - therapeutic│ │ - loading   │  │ - parameters│                     ││
│  │  │   Range     │  │ - release   │  │ - timepoints│                     ││
│  │  │ - metabolism│  │   Duration  │  │ - fit_R2    │                     ││
│  │  └─────────────┘  └─────────────┘  └─────────────┘                     ││
│  │                                                                         ││
│  │  Value Objects: PKParameters, TherapeuticWindow, ReleaseKinetics       ││
│  │  Domain Events: FormulationDesigned, ReleaseSimulated                  ││
│  │                                                                         ││
│  └─────────────────────────────────────────────────────────────────────────┘│
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────────┐│
│  │                     TISSUE ENGINEERING CONTEXT                          ││
│  │                                                                         ││
│  │  Aggregates:                                                            ││
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐                     ││
│  │  │   Scaffold  │  │  Experiment │  │   Sample    │                     ││
│  │  │   Design    │  │             │  │             │                     ││
│  │  │             │  │ - protocol  │  │ - scaffold  │                     ││
│  │  │ - tissue    │  │ - samples   │  │ - cells     │                     ││
│  │  │ - material  │  │ - timepoints│  │ - culture   │                     ││
│  │  │ - porosity  │  │ - biomarkers│  │   Conditions│                     ││
│  │  │ - poreSize  │  │ - outcomes  │  │ - results   │                     ││
│  │  └─────────────┘  └─────────────┘  └─────────────┘                     ││
│  │                                                                         ││
│  │  Value Objects: TissueTarget, CellType, CultureProtocol                ││
│  │  Domain Events: ScaffoldDesigned, ExperimentStarted, ResultRecorded    ││
│  │                                                                         ││
│  └─────────────────────────────────────────────────────────────────────────┘│
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────────┐│
│  │                     IMAGE ANALYSIS CONTEXT                              ││
│  │                                                                         ││
│  │  Aggregates:                                                            ││
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐                     ││
│  │  │   Imaging   │  │  Analysis   │  │   3D Model  │                     ││
│  │  │   Dataset   │  │    Job      │  │             │                     ││
│  │  │             │  │             │  │             │                     ││
│  │  │ - modality  │  │ - dataset   │  │ - mesh      │                     ││
│  │  │ - resolution│  │ - pipeline  │  │ - metrics   │                     ││
│  │  │ - slices    │  │ - status    │  │ - volume    │                     ││
│  │  │ - metadata  │  │ - results   │  │ - export    │                     ││
│  │  └─────────────┘  └─────────────┘  └─────────────┘                     ││
│  │                                                                         ││
│  │  Value Objects: Resolution, Metrics, SegmentationMask                  ││
│  │  Domain Events: DatasetUploaded, AnalysisCompleted, ModelExported      ││
│  │                                                                         ││
│  └─────────────────────────────────────────────────────────────────────────┘│
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────────┐│
│  │                     KNOWLEDGE GRAPH CONTEXT                             ││
│  │                                                                         ││
│  │  Entities:                                                              ││
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐                     ││
│  │  │  Ontology   │  │  Relation   │  │  Literature │                     ││
│  │  │    Term     │  │             │  │  Reference  │                     ││
│  │  │             │  │             │  │             │                     ││
│  │  │ - oboId     │  │ - subject   │  │ - doi       │                     ││
│  │  │ - name      │  │ - predicate │  │ - authors   │                     ││
│  │  │ - definition│  │ - object    │  │ - claims    │                     ││
│  │  │ - synonyms  │  │ - evidence  │  │ - evidence  │                     ││
│  │  │ - xrefs     │  │ - confidence│  │   Level     │                     ││
│  │  └─────────────┘  └─────────────┘  └─────────────┘                     ││
│  │                                                                         ││
│  └─────────────────────────────────────────────────────────────────────────┘│
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## CQRS + Event Sourcing

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         CQRS ARCHITECTURE                                    │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│                              ┌─────────────┐                                │
│                              │   Client    │                                │
│                              └──────┬──────┘                                │
│                                     │                                        │
│                    ┌────────────────┴────────────────┐                      │
│                    │                                 │                      │
│                    ▼                                 ▼                      │
│  ┌─────────────────────────────┐  ┌─────────────────────────────┐          │
│  │      COMMAND SIDE           │  │       QUERY SIDE            │          │
│  │                             │  │                             │          │
│  │  ┌───────────────────────┐  │  │  ┌───────────────────────┐  │          │
│  │  │    Command Handler    │  │  │  │    Query Handler      │  │          │
│  │  │                       │  │  │  │                       │  │          │
│  │  │ • ValidateCommand     │  │  │  │ • MaterialSearch      │  │          │
│  │  │ • LoadAggregate       │  │  │  │ • BlendPrediction     │  │          │
│  │  │ • ExecuteLogic        │  │  │  │ • FormulationQuery    │  │          │
│  │  │ • PersistEvents       │  │  │  │ • AnalyticsQuery      │  │          │
│  │  └───────────┬───────────┘  │  │  └───────────┬───────────┘  │          │
│  │              │              │  │              │              │          │
│  │              ▼              │  │              ▼              │          │
│  │  ┌───────────────────────┐  │  │  ┌───────────────────────┐  │          │
│  │  │    Event Store        │  │  │  │    Read Models        │  │          │
│  │  │    (EventStoreDB)     │──┼──┼─▶│                       │  │          │
│  │  │                       │  │  │  │ • MaterialReadModel   │  │          │
│  │  │ • Append-only log     │  │  │  │ • BlendReadModel      │  │          │
│  │  │ • Event streams       │  │  │  │ • AnalyticsReadModel  │  │          │
│  │  │ • Snapshots           │  │  │  │                       │  │          │
│  │  └───────────────────────┘  │  │  │ (PostgreSQL +         │  │          │
│  │                             │  │  │  Elasticsearch +      │  │          │
│  │                             │  │  │  ClickHouse)          │  │          │
│  └─────────────────────────────┘  │  └───────────────────────┘  │          │
│                                   │                             │          │
│                                   └─────────────────────────────┘          │
│                                                                              │
│  Event Flow:                                                                │
│  ┌──────────────────────────────────────────────────────────────────────┐  │
│  │                                                                      │  │
│  │  Command ──▶ Validate ──▶ Execute ──▶ Event ──▶ Store ──▶ Project   │  │
│  │                                                                      │  │
│  │  CreateBlend   Domain      Apply     Blend      Event    Update     │  │
│  │  Command       Logic       Change    Created    Store    ReadModel  │  │
│  │                                                                      │  │
│  └──────────────────────────────────────────────────────────────────────┘  │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Scientific Workflow Engine

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    SCIENTIFIC WORKFLOW ENGINE                                │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────────┐│
│  │                         Temporal.io / Airflow                           ││
│  │                                                                         ││
│  │  Workflow Types:                                                        ││
│  │                                                                         ││
│  │  ┌─────────────────────────────────────────────────────────────────┐   ││
│  │  │  MICROCT_ANALYSIS_WORKFLOW                                      │   ││
│  │  │                                                                 │   ││
│  │  │  ┌──────┐   ┌──────┐   ┌──────┐   ┌──────┐   ┌──────┐         │   ││
│  │  │  │Upload│──▶│Prepro│──▶│Segment│──▶│Metrics│──▶│Report│         │   ││
│  │  │  └──────┘   └──────┘   └──────┘   └──────┘   └──────┘         │   ││
│  │  │      │          │          │          │          │             │   ││
│  │  │      ▼          ▼          ▼          ▼          ▼             │   ││
│  │  │  [validate] [denoise] [SAM/Otsu] [compute]  [generate]         │   ││
│  │  │  [store]    [resample][3D recon] [validate] [notify]           │   ││
│  │  │                                                                 │   ││
│  │  │  Retry: 3x    Timeout: 5min/step    Checkpoint: enabled        │   ││
│  │  └─────────────────────────────────────────────────────────────────┘   ││
│  │                                                                         ││
│  │  ┌─────────────────────────────────────────────────────────────────┐   ││
│  │  │  OPTIMIZATION_WORKFLOW                                          │   ││
│  │  │                                                                 │   ││
│  │  │  ┌──────┐   ┌──────┐   ┌──────┐   ┌──────┐   ┌──────┐         │   ││
│  │  │  │Define│──▶│Sample│──▶│Evaluate│──▶│Update│──▶│Pareto│         │   ││
│  │  │  │Problem│  │Points│   │Fitness│   │Model│   │Front│           │   ││
│  │  │  └──────┘   └──────┘   └──────┘   └──────┘   └──────┘         │   ││
│  │  │                            │                                    │   ││
│  │  │                            ▼                                    │   ││
│  │  │                   ┌────────────────┐                           │   ││
│  │  │                   │ Parallel Eval  │ (Distributed Julia)       │   ││
│  │  │                   │ GPU Workers    │                           │   ││
│  │  │                   └────────────────┘                           │   ││
│  │  │                                                                 │   ││
│  │  │  Max iterations: 1000    Population: 100    Workers: auto      │   ││
│  │  └─────────────────────────────────────────────────────────────────┘   ││
│  │                                                                         ││
│  │  ┌─────────────────────────────────────────────────────────────────┐   ││
│  │  │  EXPERIMENT_WORKFLOW                                            │   ││
│  │  │                                                                 │   ││
│  │  │  ┌──────┐   ┌──────┐   ┌──────────┐   ┌──────┐   ┌──────┐     │   ││
│  │  │  │Design│──▶│Fabricate│──▶│Culture│──▶│Analyze│──▶│Publish│     │   ││
│  │  │  │      │   │(manual)│   │(manual)│   │       │   │       │     │   ││
│  │  │  └──────┘   └──────┘   └──────────┘   └──────┘   └──────┘     │   ││
│  │  │      │          │           │            │           │         │   ││
│  │  │      ▼          ▼           ▼            ▼           ▼         │   ││
│  │  │  [simulate] [checklist] [reminders]  [qPCR]     [report]       │   ││
│  │  │  [validate] [QC]        [data entry] [imaging]  [DOI]          │   ││
│  │  │                                                                 │   ││
│  │  │  Human-in-the-loop: enabled    Notifications: Slack/Email      │   ││
│  │  └─────────────────────────────────────────────────────────────────┘   ││
│  │                                                                         ││
│  └─────────────────────────────────────────────────────────────────────────┘│
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## ML/AI Infrastructure

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         ML/AI INFRASTRUCTURE                                 │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────────┐│
│  │                      MODEL REGISTRY (MLflow)                            ││
│  │                                                                         ││
│  │  Models:                                                                ││
│  │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐         ││
│  │  │ PropertyPredict │  │ SAM3-Scaffold   │  │ ReleasePredict  │         ││
│  │  │ v2.3.1          │  │ v1.0.0          │  │ v1.2.0          │         ││
│  │  │                 │  │                 │  │                 │         ││
│  │  │ • GNN-based     │  │ • Fine-tuned    │  │ • Physics-      │         ││
│  │  │ • R²=0.94       │  │   SAM2          │  │   informed NN   │         ││
│  │  │ • 45 materials  │  │ • IoU=0.92      │  │ • RMSE=0.05     │         ││
│  │  └─────────────────┘  └─────────────────┘  └─────────────────┘         ││
│  │                                                                         ││
│  │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐         ││
│  │  │ ScaffoldLLM     │  │ ViabilityModel  │  │ OptimalBlend    │         ││
│  │  │ v0.1.0          │  │ v3.1.0          │  │ v2.0.0          │         ││
│  │  │                 │  │                 │  │                 │         ││
│  │  │ • Fine-tuned    │  │ • Random Forest │  │ • Gaussian      │         ││
│  │  │   Llama-3       │  │ • AUC=0.89      │  │   Process       │         ││
│  │  │ • RAG-enabled   │  │ • 1000+ samples │  │ • Multi-obj     │         ││
│  │  └─────────────────┘  └─────────────────┘  └─────────────────┘         ││
│  │                                                                         ││
│  └─────────────────────────────────────────────────────────────────────────┘│
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────────┐│
│  │                      FEATURE STORE (Feast)                              ││
│  │                                                                         ││
│  │  Feature Groups:                                                        ││
│  │  • material_properties    (45 features, hourly refresh)                ││
│  │  • drug_pk_features       (30 features, daily refresh)                 ││
│  │  • experiment_outcomes    (50 features, real-time)                     ││
│  │  • image_embeddings       (512-dim, on-demand)                         ││
│  │                                                                         ││
│  └─────────────────────────────────────────────────────────────────────────┘│
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────────┐│
│  │                      INFERENCE SERVING                                  ││
│  │                                                                         ││
│  │  ┌───────────────────────────────────────────────────────────────────┐ ││
│  │  │                    Triton Inference Server                        │ ││
│  │  │                                                                   │ ││
│  │  │  GPU Pool:  4x NVIDIA A100 (40GB)                                │ ││
│  │  │  CPU Pool:  16x AMD EPYC cores                                   │ ││
│  │  │                                                                   │ ││
│  │  │  Endpoints:                                                       │ ││
│  │  │  • /v2/models/property_predict/infer     (batch, async)          │ ││
│  │  │  • /v2/models/sam3_scaffold/infer        (streaming)             │ ││
│  │  │  • /v2/models/scaffold_llm/generate      (streaming, SSE)        │ ││
│  │  │                                                                   │ ││
│  │  │  Auto-scaling: min=1, max=10, target_latency=100ms               │ ││
│  │  └───────────────────────────────────────────────────────────────────┘ ││
│  │                                                                         ││
│  └─────────────────────────────────────────────────────────────────────────┘│
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────────┐│
│  │                      RAG SYSTEM (LangChain + Weaviate)                  ││
│  │                                                                         ││
│  │  Knowledge Sources:                                                     ││
│  │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐         ││
│  │  │ Literature      │  │ Ontologies      │  │ Experiment      │         ││
│  │  │ (PubMed, 50K+)  │  │ (OBO, ChEBI)    │  │ Records (10K+)  │         ││
│  │  └─────────────────┘  └─────────────────┘  └─────────────────┘         ││
│  │                                                                         ││
│  │  Embedding: OpenAI ada-002 / local SentenceTransformers                ││
│  │  Reranking: Cohere Rerank / cross-encoder                              ││
│  │  Retrieval: Hybrid (BM25 + Dense)                                      ││
│  │                                                                         ││
│  └─────────────────────────────────────────────────────────────────────────┘│
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Observability Stack

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         OBSERVABILITY                                        │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌──────────────────────┐  ┌──────────────────────┐  ┌────────────────────┐ │
│  │      Grafana         │  │     Prometheus       │  │      Jaeger        │ │
│  │                      │  │                      │  │                    │ │
│  │  Dashboards:         │  │  Metrics:            │  │  Tracing:          │ │
│  │  • Service Health    │  │  • Request latency   │  │  • Distributed     │ │
│  │  • ML Model Perf     │  │  • Error rates       │  │    traces          │ │
│  │  • Workflow Status   │  │  • GPU utilization   │  │  • Service maps    │ │
│  │  • Resource Usage    │  │  • Queue depths      │  │  • Bottleneck      │ │
│  │                      │  │  • Model accuracy    │  │    analysis        │ │
│  └──────────────────────┘  └──────────────────────┘  └────────────────────┘ │
│                                                                              │
│  ┌──────────────────────┐  ┌──────────────────────┐  ┌────────────────────┐ │
│  │       Loki           │  │     AlertManager     │  │   OpenTelemetry    │ │
│  │                      │  │                      │  │                    │ │
│  │  Logs:               │  │  Alerts:             │  │  Instrumentation:  │ │
│  │  • Application logs  │  │  • SLO violations    │  │  • Auto-inject     │ │
│  │  • Audit logs        │  │  • Error spikes      │  │  • Custom spans    │ │
│  │  • Workflow logs     │  │  • Resource limits   │  │  • Baggage         │ │
│  │  • Scientific logs   │  │  • Model drift       │  │    propagation     │ │
│  │    (experiments)     │  │                      │  │                    │ │
│  └──────────────────────┘  └──────────────────────┘  └────────────────────┘ │
│                                                                              │
│  SLOs:                                                                       │
│  • API Availability: 99.9%                                                  │
│  • P99 Latency (queries): < 200ms                                           │
│  • P99 Latency (predictions): < 500ms                                       │
│  • Workflow Success Rate: > 95%                                             │
│  • Model Accuracy Drift: < 5%                                               │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Security Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         SECURITY ARCHITECTURE                                │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────────┐│
│  │                      IDENTITY & ACCESS                                  ││
│  │                                                                         ││
│  │  ┌───────────────┐  ┌───────────────┐  ┌───────────────┐               ││
│  │  │   Keycloak    │  │     RBAC      │  │    ABAC       │               ││
│  │  │               │  │               │  │               │               ││
│  │  │ • OAuth2/OIDC │  │ Roles:        │  │ Policies:     │               ││
│  │  │ • SAML 2.0    │  │ • Admin       │  │ • Data owner  │               ││
│  │  │ • MFA         │  │ • Researcher  │  │ • Team member │               ││
│  │  │ • SSO         │  │ • Analyst     │  │ • Public view │               ││
│  │  │ • Federation  │  │ • Viewer      │  │ • Time-based  │               ││
│  │  └───────────────┘  └───────────────┘  └───────────────┘               ││
│  │                                                                         ││
│  └─────────────────────────────────────────────────────────────────────────┘│
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────────┐│
│  │                      DATA PROTECTION                                    ││
│  │                                                                         ││
│  │  • Encryption at rest: AES-256 (all databases)                         ││
│  │  • Encryption in transit: TLS 1.3 (mTLS between services)              ││
│  │  • Key management: HashiCorp Vault                                     ││
│  │  • Data masking: PII fields auto-masked in logs                        ││
│  │  • Backup encryption: GPG with split keys                              ││
│  │                                                                         ││
│  └─────────────────────────────────────────────────────────────────────────┘│
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────────┐│
│  │                      COMPLIANCE                                         ││
│  │                                                                         ││
│  │  • GDPR: Data subject rights, consent management, DPO                  ││
│  │  • HIPAA: PHI handling (if clinical data)                              ││
│  │  • SOC 2 Type II: Security controls audit                              ││
│  │  • ISO 27001: Information security management                          ││
│  │  • 21 CFR Part 11: Electronic records (FDA)                            ││
│  │                                                                         ││
│  └─────────────────────────────────────────────────────────────────────────┘│
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────────┐│
│  │                      SCIENTIFIC INTEGRITY                               ││
│  │                                                                         ││
│  │  • Provenance tracking: All data transformations logged                ││
│  │  • Immutable audit log: Event-sourced history                          ││
│  │  • Reproducibility: Workflow + environment versioning                  ││
│  │  • Digital signatures: Results signed with researcher key              ││
│  │  • DOI integration: Automatic dataset/result registration              ││
│  │                                                                         ││
│  └─────────────────────────────────────────────────────────────────────────┘│
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Deployment Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         KUBERNETES DEPLOYMENT                                │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────────┐│
│  │                      CLUSTER TOPOLOGY                                   ││
│  │                                                                         ││
│  │  Production Cluster (AWS EKS / GKE)                                    ││
│  │  ┌─────────────────────────────────────────────────────────────────┐   ││
│  │  │                                                                 │   ││
│  │  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐             │   ││
│  │  │  │ System Pool │  │ Compute Pool│  │  GPU Pool   │             │   ││
│  │  │  │             │  │             │  │             │             │   ││
│  │  │  │ 3x m5.xlarge│  │ Auto-scale  │  │ 2x p4d.24xl │             │   ││
│  │  │  │             │  │ 2-20 nodes  │  │ (A100 GPUs) │             │   ││
│  │  │  │ • Gateway   │  │ • Services  │  │ • ML Infer  │             │   ││
│  │  │  │ • Monitoring│  │ • Workflows │  │ • Training  │             │   ││
│  │  │  │ • Databases │  │ • Analysis  │  │ • MicroCT   │             │   ││
│  │  │  └─────────────┘  └─────────────┘  └─────────────┘             │   ││
│  │  │                                                                 │   ││
│  │  └─────────────────────────────────────────────────────────────────┘   ││
│  │                                                                         ││
│  │  Namespaces:                                                            ││
│  │  • darwin-prod          (production workloads)                         ││
│  │  • darwin-staging       (pre-production testing)                       ││
│  │  • darwin-ml            (ML training jobs)                             ││
│  │  • darwin-data          (databases, storage)                           ││
│  │  • darwin-monitoring    (observability stack)                          ││
│  │                                                                         ││
│  └─────────────────────────────────────────────────────────────────────────┘│
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────────┐│
│  │                      GitOps (ArgoCD + Flux)                             ││
│  │                                                                         ││
│  │  Repositories:                                                          ││
│  │  • darwin-infra        (Terraform, Helm charts)                        ││
│  │  • darwin-apps         (Application manifests)                         ││
│  │  • darwin-ml-ops       (ML pipelines, model configs)                   ││
│  │                                                                         ││
│  │  Environments:                                                          ││
│  │  ┌─────────┐   ┌─────────┐   ┌─────────┐   ┌─────────┐                 ││
│  │  │   Dev   │──▶│ Staging │──▶│  Prod   │──▶│  DR     │                 ││
│  │  │         │   │         │   │         │   │ (cold)  │                 ││
│  │  │ auto    │   │ manual  │   │ manual  │   │         │                 ││
│  │  │ deploy  │   │ promote │   │ approve │   │         │                 ││
│  │  └─────────┘   └─────────┘   └─────────┘   └─────────┘                 ││
│  │                                                                         ││
│  └─────────────────────────────────────────────────────────────────────────┘│
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Data Flow Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         END-TO-END DATA FLOW                                 │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  USER JOURNEY: Design Drug-Loaded Scaffold                                  │
│                                                                              │
│  ┌──────────────────────────────────────────────────────────────────────┐  │
│  │                                                                      │  │
│  │  1. User Input                                                       │  │
│  │  ┌─────────────┐                                                     │  │
│  │  │ • Tissue: Bone                                                   │  │
│  │  │ • Drug: Vancomycin                                               │  │
│  │  │ • Porosity: 70%                                                  │  │
│  │  │ • Release: 14 days                                               │  │
│  │  └──────┬──────┘                                                     │  │
│  │         │                                                            │  │
│  │         ▼                                                            │  │
│  │  2. API Gateway (Kong)                                               │  │
│  │  ┌─────────────┐                                                     │  │
│  │  │ • Auth check (JWT)                                               │  │
│  │  │ • Rate limit                                                     │  │
│  │  │ • Route to service                                               │  │
│  │  └──────┬──────┘                                                     │  │
│  │         │                                                            │  │
│  │         ▼                                                            │  │
│  │  3. GraphQL Gateway                                                  │  │
│  │  ┌─────────────┐                                                     │  │
│  │  │ mutation {                                                       │  │
│  │  │   designFormulation(                                             │  │
│  │  │     tissue: BONE,                                                │  │
│  │  │     drug: "vancomycin",                                          │  │
│  │  │     porosity: 0.7                                                │  │
│  │  │   ) { ... }                                                      │  │
│  │  │ }                                                                │  │
│  │  └──────┬──────┘                                                     │  │
│  │         │                                                            │  │
│  │         ▼                                                            │  │
│  │  4. Command Handler (CQRS)                                           │  │
│  │  ┌─────────────┐                                                     │  │
│  │  │ DesignFormulationCommand                                         │  │
│  │  │ • Validate input                                                 │  │
│  │  │ • Create FormulationAggregate                                    │  │
│  │  └──────┬──────┘                                                     │  │
│  │         │                                                            │  │
│  │         ▼                                                            │  │
│  │  5. Domain Logic (Julia Services)                                    │  │
│  │  ┌─────────────────────────────────────────────────────────────┐    │  │
│  │  │                                                             │    │  │
│  │  │  ┌─────────────┐      ┌─────────────┐      ┌────────────┐  │    │  │
│  │  │  │  Material   │      │    Drug     │      │ Compat.    │  │    │  │
│  │  │  │  Service    │      │  Service    │      │ Service    │  │    │  │
│  │  │  │             │      │             │      │            │  │    │  │
│  │  │  │ find_for_   │      │ get_pk()    │      │ check()    │  │    │  │
│  │  │  │ tissue()    │      │             │      │            │  │    │  │
│  │  │  └──────┬──────┘      └──────┬──────┘      └─────┬──────┘  │    │  │
│  │  │         │                    │                   │         │    │  │
│  │  │         └────────────────────┼───────────────────┘         │    │  │
│  │  │                              ▼                             │    │  │
│  │  │                    ┌─────────────────┐                     │    │  │
│  │  │                    │  Formulation    │                     │    │  │
│  │  │                    │  Aggregator     │                     │    │  │
│  │  │                    │                 │                     │    │  │
│  │  │                    │ • Score combos  │                     │    │  │
│  │  │                    │ • Rank options  │                     │    │  │
│  │  │                    │ • Select best   │                     │    │  │
│  │  │                    └────────┬────────┘                     │    │  │
│  │  │                             │                              │    │  │
│  │  └─────────────────────────────┼──────────────────────────────┘    │  │
│  │                                │                                    │  │
│  │                                ▼                                    │  │
│  │  6. Event Publishing                                                │  │
│  │  ┌─────────────┐                                                     │  │
│  │  │ FormulationDesigned {                                            │  │
│  │  │   material: "PCL/HA",                                            │  │
│  │  │   drug: "vancomycin",                                            │  │
│  │  │   score: 0.87,                                                   │  │
│  │  │   timestamp: ...                                                 │  │
│  │  │ }                                                                │  │
│  │  └──────┬──────┘                                                     │  │
│  │         │                                                            │  │
│  │    ┌────┴────┬────────────────┬─────────────────┐                   │  │
│  │    ▼         ▼                ▼                 ▼                   │  │
│  │ ┌──────┐ ┌──────┐        ┌──────┐         ┌──────┐                 │  │
│  │ │Event │ │Read  │        │Notif.│         │Audit │                 │  │
│  │ │Store │ │Model │        │Svc   │         │Log   │                 │  │
│  │ │      │ │Update│        │      │         │      │                 │  │
│  │ └──────┘ └──────┘        └──────┘         └──────┘                 │  │
│  │                                                                      │  │
│  │                                ▼                                    │  │
│  │  7. Response                                                        │  │
│  │  ┌─────────────┐                                                     │  │
│  │  │ {                                                                │  │
│  │  │   "formulation": {                                               │  │
│  │  │     "material": "PCL/HA (80:20)",                               │  │
│  │  │     "modulus": 240,                                              │  │
│  │  │     "drugLoading": 500,                                          │  │
│  │  │     "releaseProfile": {...},                                     │  │
│  │  │     "biomarkers": [...],                                         │  │
│  │  │     "fabrication": [...],                                        │  │
│  │  │     "recommendations": [...]                                     │  │
│  │  │   }                                                              │  │
│  │  │ }                                                                │  │
│  │  └─────────────┘                                                     │  │
│  │                                                                      │  │
│  └──────────────────────────────────────────────────────────────────────┘  │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Technology Stack Summary

### Core Services
| Component | Technology | Justification |
|-----------|------------|---------------|
| API Gateway | Kong / Traefik | Enterprise-grade, plugins ecosystem |
| GraphQL | Apollo Federation | Schema stitching, type safety |
| Domain Services | Julia (Oxygen.jl) | Scientific computing, performance |
| Workflow Engine | Temporal.io | Durability, visibility, versioning |
| Event Bus | Apache Kafka | High throughput, exactly-once |
| Event Store | EventStoreDB | Native event sourcing |

### Data Layer
| Component | Technology | Use Case |
|-----------|------------|----------|
| Primary DB | PostgreSQL 15 | Transactional data, JSONB |
| Time Series | TimescaleDB | Experiments, sensor data |
| Document Store | MongoDB | MicroCT metadata, unstructured |
| Graph DB | Neo4j | Ontologies, knowledge graph |
| Search | Elasticsearch | Full-text, literature |
| Analytics | ClickHouse | OLAP, aggregations |
| Cache | Redis Cluster | Sessions, hot data |
| Object Storage | MinIO / S3 | Images, models, datasets |

### ML/AI
| Component | Technology | Use Case |
|-----------|------------|----------|
| Model Registry | MLflow | Versioning, lineage |
| Feature Store | Feast | Feature engineering |
| Inference | Triton Server | Multi-framework, GPU |
| Training | Kubeflow | Distributed training |
| RAG | LangChain + Weaviate | Literature, QA |
| LLM | Ollama / vLLM | Local inference |

### Observability
| Component | Technology | Use Case |
|-----------|------------|----------|
| Metrics | Prometheus + Grafana | Dashboards, alerting |
| Tracing | Jaeger | Distributed tracing |
| Logs | Loki | Log aggregation |
| Profiling | Pyroscope | Continuous profiling |

### Infrastructure
| Component | Technology | Use Case |
|-----------|------------|----------|
| Orchestration | Kubernetes (EKS/GKE) | Container orchestration |
| Service Mesh | Istio | mTLS, traffic management |
| GitOps | ArgoCD + Flux | Declarative deployments |
| IaC | Terraform + Pulumi | Infrastructure as code |
| Secrets | HashiCorp Vault | Key management |
| CI/CD | GitHub Actions | Automation |

---

## Estimativa de Recursos

### Infraestrutura (Produção)
```
Compute:
  - EKS Control Plane: $0.10/hour
  - System nodes (3x m5.xlarge): ~$500/month
  - Compute nodes (auto-scale 2-20): ~$1,000-5,000/month
  - GPU nodes (2x p4d.24xlarge on-demand): ~$3,000/month (quando ativo)

Storage:
  - EBS (500GB gp3): ~$50/month
  - S3 (1TB): ~$25/month
  - RDS PostgreSQL (db.r5.xlarge): ~$400/month

Networking:
  - Load Balancer: ~$20/month
  - NAT Gateway: ~$50/month
  - Data transfer: ~$100/month

Total estimado: $2,000-6,000/month (dependendo do uso de GPU)
```

### Time Estimado (Full Stack)
```
Phase 1 (MVP): 4-6 meses
  - 2 Backend Engineers (Julia + Python)
  - 2 Frontend Engineers (React)
  - 1 DevOps/Platform Engineer
  - 1 ML Engineer
  - 1 Tech Lead

Phase 2 (Scale): +4 meses
  - +1 Data Engineer
  - +1 Security Engineer

Phase 3 (Enterprise): +4 meses
  - +1 SRE
  - +1 Product Manager
```
