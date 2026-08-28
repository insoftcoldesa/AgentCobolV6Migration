# Índice del corpus documental

Mapa de qué manual responde qué pregunta. El agente consulta esta tabla antes de buscar.

## Destino — IBM Enterprise COBOL for z/OS 6.4

| Archivo | Manual | Nº de orden | Se consulta para |
|---|---|---|---|
| `Migration-Guide-GC27-8715-03` | Migration Guide | GC27-8715-03 | Diferencias de comportamiento entre versiones, pitfalls de migración, datos inválidos, cambios en opciones del compilador entre V5 y V6 |
| `Programming-Guide-SC27-8714-03` | Programming Guide | SC27-8714-03 | Descripción funcional de cada opción del compilador, INVDATA, NUMCHECK, RULES, SSRANGE, ejemplos de uso |
| `Language-Reference-SC27-8713-03` | Language Reference | SC27-8713-03 | Semántica del lenguaje: INITIALIZE, REDEFINES, VALUE, MOVE, restricciones por sección de la DATA DIVISION |
| `Customization-Guide-SC27-8712-03` | Customization Guide | SC27-8712-03 | Valores por defecto de las opciones, macro IGYCDOPT, cómo fijar opciones en la instalación |
| `Performance-Tuning-Guide-SC27-9202-02` | Performance Tuning Guide | SC27-9202-02 | Costo de las opciones de verificación, diferencias de generación de código COBOL 4 vs COBOL 6, ARCH y TUNE |
| `What-Is-New` | What's New | — | Qué se agregó en cada PTF y con qué APAR |

## Origen — IBM Enterprise COBOL for z/OS V4.2

Migración confirmada: **V4.2 → 6.4**. Salto de dos generaciones; V4.2 es la última versión con el generador de código anterior a V5.

| Archivo | Manual | Nº de orden | Se consulta para |
|---|---|---|---|
| `V42-Programming-Guide-SC23-8529-01` | Programming Guide V4.2 | SC23-8529-01 | Comportamiento y opciones vigentes en el origen; qué hacía NUMPROC(MIG) |
| `V42-Language-Reference-SC23-8528-01` | Language Reference V4.2 | SC23-8528-01 | Lista de palabras reservadas de origen, para diferencia contra la de 6.4 (regla MIG-07) |
| `V42-Customization-Guide-SC23-8526-01` | Customization Guide V4.2 | SC23-8526-01 | Valores por defecto de opciones en el origen |

Descarga desde `https://publibfp.dhe.ibm.com/epubs/pdf/` (mirror alterno: `publibfp.boulder.ibm.com`). El script `scripts/descargar-docs-ibm.sh` ya los incluye.

## Secciones clave del Migration Guide 6.4 para esta migración

| Sección | Para qué |
|---|---|
| Cap. 17 — Upgrading from Enterprise COBOL Version 4 | Punto de entrada obligatorio. Incluye el enlace a la lista de PTF de V4 requeridos |
| Cap. 16 — Changes with Enterprise COBOL 6 | Cambios de comportamiento acumulados |
| Tabla 34 — Compiler option not available in Enterprise COBOL 6 | Regla MIG-02. Fuente única para decidir qué opción se elimina |
| WORKING-STORAGE SECTION changes | Regla MIG-05 |
| Binding (link-editing) Enterprise COBOL programs | Regla MIG-08 |
| FAQs before migration | Contexto general antes de la primera corrida |

En el Customization Guide 6.4 y en el Performance Tuning Guide 6.4 está la tabla **"Setting INVDATA and NUMPROC options when migrating from earlier COBOL versions"**, que es la equivalencia oficial para la regla MIG-01.

## Nivel de servicio

El comportamiento de `INITCHECK` y de los mensajes `IGYCB7311-W` depende de los PTF aplicados. Registrar aquí el nivel real del compilador instalado:

```
Origen:      IBM Enterprise COBOL for z/OS V4.2
Destino:     IBM Enterprise COBOL for z/OS 6.4.0
Nivel PTF:   P240621
Fecha:       <completar>
APARs verificados como aplicados:
  PH23443 / PH25226  (falso positivo LINKAGE → WS/LOCAL-STORAGE)
  PH37213            (INITCHECK y análisis de PERFORM)
  PH35976 / PH37332  (INITCHECK(STRICT) con OPT(0) y EXEC CICS HANDLE)
  PH37328            (INVDATA reemplaza a ZONEDATA)
  PH33122 / PH36688  (RULES LAXREDEF | NOLAXREDEF)
```

Sin este bloque completo, el agente no puede descartar falsos positivos de la familia `FLW` y marcará los hallazgos correspondientes como `POSIBLE-FALSO-POSITIVO`.

## Opciones de compilación vigentes

Registrar las opciones reales de cada ambiente. El agente las usa para decidir qué reglas de la familia `OPT` aplican.

| Ambiente | INITCHECK | NUMCHECK | RULES | INVDATA | OPT | SSRANGE | PARMCHECK |
|---|---|---|---|---|---|---|---|
| Desarrollo | | | | | | | |
| Pruebas | | | | | | | |
| Producción | NOINITCHECK | NONUMCHECK | NORULES | | | | NOPARMCHECK |
