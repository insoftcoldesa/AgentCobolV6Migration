# CobolRulesAI

Agente de validación de reglas para la migración **IBM Enterprise COBOL for z/OS V4.2 → 6.4**.

Dirección de Integraciones, Banco AV Villas · Equipo INSOFTCOL

---

## Por dónde empezar

| Si eres | Lee |
|---|---|
| Quien monta el entorno | `INSTRUCTIVO.md`, etapa 0 |
| Desarrollador que va a analizar | `INSTRUCTIVO.md`, etapas 2 a 4 |
| Líder técnico que aprueba el GATE | `INSTRUCTIVO.md`, etapa 5 |
| Quien quiere entender el diseño | `GUIA-USO.md` |
| Quien va a auditar o extender las reglas | `reglas/catalogo-reglas.md` |

---

## Contenido del paquete

```
cobol-rules-agent/
├── INSTRUCTIVO.md                              proceso paso a paso, por etapas
├── GUIA-USO.md                                 guía de referencia y diseño
├── .github/agents/
│   └── cobol-rules-validator.agent.md          perfil del agente para Copilot
├── reglas/
│   └── catalogo-reglas.md                      37 reglas en 6 familias
├── prompts/
│   └── 00-prompts.md                           P0 a P5, listos para pegar
├── sondas/
│   └── README.md                               kit de diagnóstico sin permisos
├── docs-ibm/
│   └── INDICE.md                               mapa del corpus documental
└── scripts/
    └── descargar-docs-ibm.sh                   descarga y conversión de manuales
```

Directorios que se crean al usar: `entradas/`, `salidas/`, `docs-ibm/6.4/`, `docs-ibm/origen/`.

---

## Puesta en marcha en tres comandos

```bash
brew install poppler
bash scripts/descargar-docs-ibm.sh
ls docs-ibm/6.4/txt/ docs-ibm/origen/txt/
```

Luego sigue `INSTRUCTIVO.md` desde la etapa 1.

---

## Las seis familias de reglas

| Familia | Qué cubre | Nº |
|---|---|---|
| `INIT` | Inicialización y flujo de asignación | 7 |
| `RDF` | REDEFINES y vistas superpuestas | 6 |
| `NUM` | Datos numéricos y literales | 4 |
| `MIG` | Salto de versión V4.2 → 6.4 | 9 |
| `FLW` | Defectos conocidos del compilador | 3 |
| `OPT` | Configuración de compilación | 5 |

---

## Principio de diseño

El compilador de esta instalación corre con las verificaciones apagadas. Eso significa que las condiciones de mayor riesgo —`RDF-01`, `RDF-02`, `MIG-05`— **no producen ningún mensaje**.

De ahí la premisa del agente: su valor no está en explicar los warnings que ya ves, sino en detectar las condiciones sobre las que el compilador guarda silencio. Por eso el análisis sobre fuente y copybooks es el modo principal, y el listado de compilación es complemento.

Todo hallazgo exige triple evidencia: línea del fuente, identificador de regla y sección del manual IBM. Sin las tres, se degrada a observación y no cuenta para el veredicto GATE.

---

## Relación con los demás agentes del SDD

Este agente trabaja sobre código. No genera historias de usuario, Gherkin, arquitectura ni planes de prueba: eso corresponde a RefinAI, ReqMasterAI, ScopeAI, SolicitaAI y TestForgeAI.

Conserva el veredicto GATE y la clasificación D/C/M/P para consolidar con los analizadores NUMCHECK, PARMCHECK, SSRANGE, RULES y DIAGTRUNC ya existentes.
