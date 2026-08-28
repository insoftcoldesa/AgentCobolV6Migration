# Instructivo del proceso

**Validación de reglas COBOL — Migración Enterprise COBOL V4.2 → 6.4**

Dirección de Integraciones, Banco AV Villas · Equipo INSOFTCOL

Versión 1.0

---

## Alcance y supuestos

Este instructivo aplica al equipo de desarrollo. Los supuestos de partida son:

- Sin acceso de administrador de sistemas: no se aplican PTF, no se consulta SMP/E, no se cambian opciones fijas de la instalación.
- Se controla el código fuente y el envío a compilar.
- El proceso de promoción exige código de terminación **RC=0**.
- Zowe CLI está instalado localmente pero sin endpoint z/OSMF disponible.

Todo el proceso está diseñado para operar dentro de esas restricciones.

---

## Mapa del proceso

```
ETAPA 0   Preparación del entorno            una vez
ETAPA 1   Sondas del compilador              una vez
ETAPA 2   Recolección de insumos             por programa
ETAPA 3   Análisis con el agente             por programa
ETAPA 4   Triage y remediación               por programa
ETAPA 5   Cierre y veredicto GATE            por entregable
```

---

## ETAPA 0 · Preparación del entorno

**Se hace una sola vez. Responsable: quien monta el repositorio.**

### 0.1 Clonar y descargar documentación

```bash
git clone <repo> cobol-rules-agent
cd cobol-rules-agent
bash scripts/descargar-docs-ibm.sh
```

El script baja seis manuales de 6.4 y tres de V4.2, y los convierte a texto.

**Prerrequisito:** `pdftotext`. En macOS: `brew install poppler`.

### 0.2 Verificar

```bash
ls docs-ibm/6.4/txt/ docs-ibm/origen/txt/
```

Deben aparecer nueve archivos `.txt`. Si falta alguno, revisa la salida del script: puede haber cambiado una URL en la biblioteca de IBM.

**Criterio de salida de la etapa:** los nueve manuales convertidos a texto.

> Sin la conversión a texto el agente no indexa nada y todos los hallazgos saldrán marcados `SIN-RESPALDO`. No sigas hasta que este paso esté completo.

---

## ETAPA 1 · Sondas del compilador

**Se hace una sola vez, o cuando cambie el nivel del compilador. Responsable: un desarrollador con acceso a compilar.**

El objetivo es averiguar el comportamiento real del compilador de la instalación sin depender de permisos que no se tienen.

### 1.1 Línea base (SONDA05) — sin compilar nada

Toma cualquier listado de una compilación que ya hayas hecho. Extrae dos bloques:

- El **encabezado**, que trae la versión y el nivel de servicio (`6.4.0 Pnnnnnn`).
- El **bloque de opciones en efecto**, que lista todas las opciones vigentes.

Pégalos en `sondas/RESULTADOS.md` y en `docs-ibm/INDICE.md`.

Este paso cuesta cero compilaciones y resuelve la familia OPT completa del catálogo. Es el de mejor relación valor/esfuerzo de todo el proceso.

### 1.2 SONDA01 — capacidad de diagnóstico

Compila el programa `SONDA01` de `sondas/README.md` en tu biblioteca personal.

Lee en el listado si la sentencia `CBL` fue aceptada.

| Resultado | Camino |
|---|---|
| Aceptada | Continúa con 1.3. Tienes capacidad de diagnóstico. |
| Rechazada | Salta a la ETAPA 2. Trabajarás solo con análisis sobre fuente. |

### 1.3 SONDA02, SONDA03 y SONDA04

Compila las tres restantes y anota los resultados en `sondas/RESULTADOS.md` usando la plantilla del final de `sondas/README.md`.

SONDA04 requiere ejecución además de compilación. Si no puedes ejecutar, márcala `NO EJECUTADA` y sigue.

**Criterio de salida de la etapa:** `sondas/RESULTADOS.md` diligenciado, aunque sea parcialmente.

> **Advertencia.** Las sondas van en tu biblioteca personal y no entran al flujo de promoción. Se espera que varias terminen en RC=4 por advertencias: eso es el resultado buscado. Nunca dejes sentencias `CBL` con `INITCHECK` o `RULES` en un fuente que va a promoción, porque elevarán el RC a 4 y tu proceso exige 0.

---

## ETAPA 2 · Recolección de insumos

**Por cada programa a analizar. Responsable: el desarrollador asignado.**

### 2.1 Obligatorio

```
entradas/fuentes/PGMXXXX.cbl
entradas/copybooks/*.cpy
```

Copia **todos** los copybooks que el fuente referencia con `COPY`, incluidos los anidados. Si falta uno, el agente marcará el hallazgo como `INCOMPLETO` en lugar de suponer.

### 2.2 Recomendado

```
entradas/listados/PGMXXXX.lst
```

El listado de la compilación normal, la que ya haces. No necesitas una compilación especial.

**Cómo bajarlo,** en orden de menor a mayor dependencia:

1. **Emulador 3270**, transferencia IND$FILE. Sin dependencias. En SDSF, `XDC` sobre la salida del job para guardarla en un dataset, y de ahí recibir con el emulador.
2. **FTP a z/OS**, con tus credenciales de TSO. Confirma modo `ascii` antes del `get`.
3. **Captura desde ISPF**, viable para listados cortos como los de las sondas.
4. **Tu herramienta de compilación**, si Endevor o Changeman permiten exportar el listado del build.
5. **Zowe CLI**, solo si z/OSMF llega a estar disponible.

**Cuidado con la página de código.** Si la conversión EBCDIC → ASCII usa el CCSID equivocado, los acentos de los comentarios se corrompen y el agente termina citando basura como evidencia. Verifícalo en la primera descarga.

### 2.3 Opcional

```
entradas/opciones/compile-v42.txt
```

El JCL o la PROC de compilación de V4.2, si tienes acceso. Habilita cuatro reglas de la familia MIG. Sin esto quedan `NO EVALUABLE`.

**Criterio de salida de la etapa:** fuente y copybooks completos en `entradas/`.

---

## ETAPA 3 · Análisis con el agente

**Por cada programa. Responsable: el desarrollador asignado.**

### 3.1 Abrir el agente

En VS Code, abre Copilot Chat y selecciona el agente `cobol-rules-validator`.

### 3.2 Arranque de sesión

Pega el prompt **P0** de `prompts/00-prompts.md`. Una vez por sesión, no por programa.

El agente carga el catálogo, revisa el corpus y te devuelve qué familias de reglas puede evaluar y cuáles no, separando lo que puedes resolver tú de lo que requiere al área de sistemas.

Si P0 reporta muchas familias `NO EVALUABLE`, vuelve a la ETAPA 0 o 1 antes de seguir.

### 3.3 Análisis

Pega el prompt **P1**, sustituyendo `<NOMBRE>` por el programa.

Si además tienes el listado, encadena el prompt **P2** para cruzar los mensajes reales contra el catálogo. El bloque B de esa salida —condiciones que se cumplen pero que el compilador no reportó— es el de mayor valor.

### 3.4 Para un lote

Usa el prompt **P3** para obtener un tablero de priorización antes de entrar al detalle de cada programa.

**Criterio de salida de la etapa:** `salidas/hallazgos-<programa>.md` generado.

---

## ETAPA 4 · Triage y remediación

**Por cada programa. Responsable: el desarrollador, con revisión del líder técnico.**

Clasifica cada hallazgo según su marca:

| Marca | Acción | ¿Bloquea? |
|---|---|---|
| `CRITICO` | Corregir antes de promover | Sí |
| `ALTO` | Corregir o justificar por escrito | Sí, salvo justificación aceptada |
| `MEDIO` / `BAJO` | Registrar como deuda técnica | No |
| `FALSO-POSITIVO-CONFIRMADO` | No corregir. Documentar la sonda que lo descartó | No |
| `POSIBLE-FALSO-POSITIVO` | Correr la sonda que el agente indica antes de tocar código | Sí, hasta resolver |
| `INCOMPLETO` | Aportar el copybook faltante y reprocesar | Sí |
| `SIN-RESPALDO` | Tratar como observación, no como hallazgo | No |
| `NO EVALUABLE` | Documentar como limitación de alcance | No |

**Regla de oro del triage:** nunca modifiques código por un hallazgo marcado `POSIBLE-FALSO-POSITIVO` sin correr antes la sonda. Ese es el error más costoso del proceso, porque se reescribe código correcto.

Los hallazgos de la familia OPT no son acciones tuyas. Se acumulan en un documento de recomendaciones hacia el área de sistemas.

---

## ETAPA 5 · Cierre y veredicto GATE

**Por entregable. Responsable: el líder técnico.**

### 5.1 Consolidar

Reúne los `salidas/hallazgos-*.md` del entregable.

### 5.2 Veredicto

| Veredicto | Condición |
|---|---|
| `APROBADO` | Sin `CRITICO` ni `ALTO` pendientes |
| `APROBADO CON CONDICIONES` | Sin `CRITICO`; `ALTO` justificados por escrito |
| `NO APROBADO` | Al menos un `CRITICO` sin remediar |

### 5.3 Declarar límites de alcance

Documenta explícitamente en el cierre lo que este proceso **no** puede verificar con los permisos actuales:

- No se confirma el inventario de PTF aplicados. Las sondas dan comportamiento observado, no lista instalada. Suficiente para decidir sobre código, insuficiente para un reporte de cumplimiento.
- No se modifican las opciones de compilación de producción. Los hallazgos OPT quedan como recomendación hacia sistemas.
- Las reglas RDF-02 y NUM-02 se detectan estructuralmente pero solo se confirman en ejecución con `NUMCHECK` activo o con datos reales.

Esta declaración no es un descargo: convierte un riesgo detectado y no verificable en un **riesgo transferido**, que es la posición correcta del equipo de desarrollo frente al GATE.

---

## Anexo · Errores frecuentes

| Error | Consecuencia |
|---|---|
| Dejar los PDF sin convertir a texto | El agente no cita nada; todo sale `SIN-RESPALDO` |
| Analizar solo con el listado, sin el fuente | Se pierden todos los `CRITICO`, que no generan mensaje |
| Omitir copybooks | Análisis aparentemente completo pero falso |
| No correr SONDA01 | No se sabe si hay capacidad de diagnóstico; se pierde tiempo |
| Dejar `CBL INITCHECK` en un fuente de promoción | RC=4 y rechazo del proceso |
| Bajar el spool con página de código errada | Citas corrompidas presentadas como evidencia |
| Corregir por un `POSIBLE-FALSO-POSITIVO` sin sonda | Se reescribe código correcto |

---

## Anexo · Glosario

| Término | Significado |
|---|---|
| **APAR** | *Authorized Program Analysis Report*. Número del reporte de defecto de IBM. El ticket del bug. |
| **PTF** | *Program Temporary Fix*. El parche que corrige un APAR, aplicado por el administrador con SMP/E. |
| **Nivel de servicio** | El `Pnnnnnn` del encabezado del listado. Indica hasta qué PTF está actualizado el compilador. |
| **Sonda** | Programa mínimo compilado para revelar un comportamiento del compilador sin necesidad de permisos. |
| **Familia de reglas** | Agrupación del catálogo: INIT, RDF, NUM, MIG, FLW, OPT. |
| **Hallazgo silencioso** | Condición de riesgo que el compilador no reporta con las opciones vigentes. Son los `CRITICO`. |
