# Paso a paso de implementación

**Agente de validación de reglas COBOL — Migración Enterprise COBOL V4.2 → 6.4**

Dirección de Integraciones, Banco AV Villas · Equipo INSOFTCOL

Versión 1.0

---

## Punto de partida

Este documento arranca desde el corpus documental ya descargado y convertido. Si estás montando el repositorio desde cero, ejecuta primero la etapa 0 del `INSTRUCTIVO.md`.

Estado esperado al iniciar:

```
docs-ibm/6.4/         6 PDF  +  6 TXT
docs-ibm/origen/      3 PDF  +  3 TXT
```

---

## PASO 1 · Verificar el corpus

**Responsable:** quien montó el repositorio · **Duración:** 2 minutos

```bash
cd cobol-rules-agent
ls -1 docs-ibm/6.4/txt/*.txt | wc -l
ls -1 docs-ibm/origen/txt/*.txt | wc -l
```

Debe devolver `6` y `3`.

```bash
head -5 docs-ibm/6.4/txt/Migration-Guide-GC27-8715-03.txt
```

Si sale texto legible, la conversión quedó bien. Si salen caracteres extraños, el PDF se descargó corrupto y hay que rehacerlo.

- [ ] Nueve archivos de texto presentes y legibles

---

## PASO 2 · Publicar en Git

**Responsable:** líder técnico · **Duración:** 15 minutos

### 2.1 Decisión sobre el corpus

Los PDF pesan unos 20 MB y **no** deben ir al repositorio. Los `.txt` sí: pesan unos 13 MB en total y son los que el agente indexa.

Esta decisión importa. IBM bloquea las descargas automatizadas y `publibfp.dhe.ibm.com` está filtrado por el DNS corporativo. Si cada persona del equipo tuviera que reconstruir el corpus, cada una repetiría el mismo forcejeo. **Versionar los `.txt` hace el repositorio autosuficiente.**

Crea `.gitignore` en la raíz:

```
docs-ibm/6.4/*.pdf
docs-ibm/origen/*.pdf
entradas/fuentes/*
entradas/copybooks/*
entradas/listados/*
entradas/opciones/*
salidas/*
!**/.gitkeep
```

### 2.2 Publicar

```bash
git init
git add .
git commit -m "Agente de validacion de reglas COBOL V4.2 a 6.4 - version inicial"
git remote add origin <url-del-repositorio>
git push -u origin main
```

- [ ] Repositorio publicado
- [ ] Los `.txt` del corpus están versionados
- [ ] Los PDF están excluidos

---

## PASO 3 · Preparar las estaciones de trabajo

**Responsable:** cada desarrollador · **Duración:** 10 minutos por persona

### 3.1 Requisitos

| Componente | Verificación |
|---|---|
| Visual Studio Code actualizado | `Code → Acerca de` |
| Extensión GitHub Copilot Chat | Panel de extensiones |
| Licencia de Copilot activa | Icono de Copilot en la barra de estado |

### 3.2 Clonar

```bash
git clone <url-del-repositorio>
cd cobol-rules-agent
code .
```

### 3.3 Verificar que el agente aparece

Abre Copilot Chat y despliega el selector de agentes. Debe aparecer `cobol-rules-validator`.

**Si no aparece:**

1. Confirma que el archivo existe en `.github/agents/cobol-rules-validator.agent.md`.
2. Confirma que abriste la carpeta raíz del proyecto, no una subcarpeta.
3. Actualiza VS Code y la extensión de Copilot.
4. Verifica con el administrador de GitHub si la política de la organización permite agentes personalizados. En entornos corporativos suele estar restringido por defecto — **este es el punto de bloqueo más frecuente y conviene gestionarlo antes de la sesión de despliegue.**

- [ ] El agente aparece en el selector

---

## PASO 4 · Primera sesión del agente

**Responsable:** cada desarrollador · **Duración:** 5 minutos

Selecciona el agente `cobol-rules-validator` y pega el prompt **P0** de `prompts/00-prompts.md`.

El agente debe responder con una tabla de las seis familias de reglas y su estado. Con el corpus completo, esperas ver `EVALUABLE` en INIT, RDF, NUM y MIG.

`FLW` y `OPT` saldrán `NO EVALUABLE` hasta que ejecutes las sondas del paso 5. Es lo correcto.

**Señal de alarma:** si el agente responde con hallazgos o explicaciones generales sin haber leído el catálogo, no está usando el perfil. Revisa el paso 3.3.

- [ ] P0 devuelve la tabla de estado de las seis familias

---

## PASO 5 · Sondas del compilador

**Responsable:** un desarrollador con acceso a compilar · **Duración:** media jornada

Se hace **una sola vez** para todo el equipo. El resultado se comparte por el repositorio.

### 5.1 SONDA05 — línea base, sin compilar

Toma cualquier listado de compilación existente. Extrae dos bloques:

- El **encabezado** con la versión y el nivel de servicio (`6.4.0 Pnnnnnn`).
- El **bloque de opciones en efecto**.

Créalos en `sondas/RESULTADOS.md` con la plantilla que está al final de `sondas/README.md`, y replica los mismos datos en `docs-ibm/INDICE.md`.

Cuesta cero compilaciones y desbloquea la familia OPT completa. **Empieza por aquí.**

### 5.2 SONDA01 — capacidad de diagnóstico

Compila `SONDA01` de `sondas/README.md` en tu biblioteca personal.

| Resultado del listado | Camino |
|---|---|
| La sentencia `CBL` fue aceptada | Continúa con 5.3 |
| Fue rechazada | Detén el kit. Anótalo y salta al paso 6 |

### 5.3 SONDA02, SONDA03 y SONDA04

Compila las tres y anota resultados. SONDA04 además requiere ejecución; si no puedes ejecutar, márcala `NO EJECUTADA`.

### 5.4 Publicar

```bash
git add sondas/RESULTADOS.md docs-ibm/INDICE.md
git commit -m "Resultados de sondas del compilador"
git push
```

> **Advertencia para el equipo.** Las sondas viven en bibliotecas personales y nunca entran al flujo de promoción. Se espera que varias terminen en RC=4: ese es el resultado buscado. Jamás dejes una sentencia `CBL` con `INITCHECK` o `RULES` en un fuente que va a promoción, porque elevará el RC a 4 y el proceso lo rechazará.

- [ ] `sondas/RESULTADOS.md` publicado en el repositorio

---

## PASO 6 · Programa piloto

**Responsable:** líder técnico + un desarrollador · **Duración:** 2 horas

No arranques con un lote. Escoge **un** programa representativo: que use copybooks, que tenga al menos un `REDEFINES` y que sea de un módulo que el equipo conozca bien.

### 6.1 Cargar insumos

```bash
cp <ruta>/PGMXXXX.cbl entradas/fuentes/
cp <ruta>/*.cpy entradas/copybooks/
```

Copia **todos** los copybooks, incluidos los anidados. Si falta uno, el agente marcará `INCOMPLETO` en lugar de suponer.

### 6.2 Analizar

Prompt **P0**, luego prompt **P1** con el nombre del programa.

### 6.3 Validar contra criterio humano

Este es el paso que define si el montaje sirve. Con el líder técnico, revisen hallazgo por hallazgo:

| Pregunta | Si la respuesta es no |
|---|---|
| ¿La cita del fuente corresponde a la línea real? | Falla de lectura. Revisar copybooks |
| ¿El respaldo documental existe en el manual citado? | El corpus está incompleto o mal convertido |
| ¿La severidad es razonable? | Ajustar el catálogo, no el agente |
| ¿Falta algún riesgo que ustedes sí ven? | Regla nueva para el catálogo |

Los ajustes van a `reglas/catalogo-reglas.md`. El perfil del agente casi nunca necesita tocarse.

- [ ] Piloto analizado y revisado con criterio humano
- [ ] Ajustes al catálogo aplicados y publicados

---

## PASO 7 · Despliegue al equipo

**Responsable:** líder técnico · **Duración:** sesión de 1 hora

### 7.1 Sesión de arranque

Orden sugerido:

1. El problema: por qué las reglas `CRITICO` no generan mensaje del compilador (15 min).
2. Demostración con SONDA04, que hace tangible que `INITIALIZE` no alcanza la vista `REDEFINES` (10 min).
3. Recorrido del `INSTRUCTIVO.md`, etapas 2 a 4 (20 min).
4. Los tres prompts de uso diario: P0, P1, P3 (15 min).

### 7.2 Reglas de operación

Acuerdos que conviene dejar escritos:

- Un hallazgo `CRITICO` bloquea la promoción.
- **Nunca se modifica código por un `POSIBLE-FALSO-POSITIVO` sin correr antes la sonda que el agente indica.** Es el error más caro del proceso: se reescribe código correcto.
- Los hallazgos de la familia OPT no son acción del equipo; se acumulan como recomendación hacia el área de sistemas.
- Todo ajuste al catálogo pasa por pull request, no por edición directa.

- [ ] Sesión realizada
- [ ] Reglas de operación acordadas

---

## PASO 8 · Integración con el GATE del SDD

**Responsable:** líder técnico

El veredicto del agente se incorpora al cierre del entregable:

| Veredicto | Condición |
|---|---|
| `APROBADO` | Sin `CRITICO` ni `ALTO` pendientes |
| `APROBADO CON CONDICIONES` | Sin `CRITICO`; `ALTO` justificados por escrito |
| `NO APROBADO` | Al menos un `CRITICO` sin remediar |

En el cierre se declaran además los límites de alcance, que con los permisos actuales son permanentes:

- No se confirma el inventario de PTF aplicados. Las sondas dan comportamiento observado, no lista instalada.
- No se modifican opciones de compilación de producción.
- Las reglas RDF-02 y NUM-02 se detectan estructuralmente pero solo se confirman en ejecución.

Esta declaración convierte un riesgo detectado y no verificable en un **riesgo transferido**, que es la posición correcta del equipo de desarrollo. No es un descargo: es trazabilidad.

- [ ] Veredicto incorporado al GATE
- [ ] Límites de alcance documentados

---

## Roles

| Rol | Responsabilidad |
|---|---|
| Líder técnico | Publica el repositorio, valida el piloto, aprueba cambios al catálogo, emite el veredicto GATE |
| Desarrollador de sondas | Ejecuta el kit una vez y publica `RESULTADOS.md` |
| Desarrollador | Carga insumos, ejecuta P0 y P1, remedia hallazgos |
| Administrador de GitHub | Habilita la política de agentes personalizados |
| Área de sistemas | Destinataria de las recomendaciones de la familia OPT. No participa en la operación diaria |

---

## Checklist de aceptación

Marca todo antes de declarar el montaje operativo:

- [ ] Nueve archivos de texto en `docs-ibm/*/txt/`
- [ ] Repositorio publicado, con los `.txt` versionados y los PDF excluidos
- [ ] El agente aparece en el selector de Copilot en al menos dos estaciones
- [ ] P0 devuelve la tabla de las seis familias
- [ ] `sondas/RESULTADOS.md` con SONDA05 y SONDA01 como mínimo
- [ ] Nivel del compilador y opciones en efecto registrados en `docs-ibm/INDICE.md`
- [ ] Un programa piloto analizado y validado con criterio humano
- [ ] Sesión de arranque realizada y reglas de operación acordadas
- [ ] Veredicto GATE integrado al cierre de entregables

---

## Problemas frecuentes

| Síntoma | Causa probable | Acción |
|---|---|---|
| El agente no aparece en el selector | Política de la organización, o carpeta raíz mal abierta | Paso 3.3 |
| Todos los hallazgos salen `SIN-RESPALDO` | Los `.txt` no están o no se indexaron | Paso 1 |
| Todo sale `NO EVALUABLE` | Falta `sondas/RESULTADOS.md` o el bloque de opciones | Paso 5 |
| Hallazgos con líneas que no corresponden | Faltan copybooks | Paso 6.1 |
| Citas con caracteres corrompidos | Página de código errada al bajar el listado | Rehacer la descarga con el CCSID correcto |
| El agente propone acciones de administrador | El perfil no se está aplicando | Paso 3.3 |
