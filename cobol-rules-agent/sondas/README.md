# Kit de sondas

Programas mínimos que se compilan en tu biblioteca personal para revelar el comportamiento real del compilador de tu instalación, sin necesidad de permisos de administrador.

**Reglas de uso:**

- Van en tu biblioteca de trabajo, nunca en el flujo de promoción.
- No producen módulo de carga útil. Si tu proceso exige link-edit, dirige `SYSLMOD` a una biblioteca de descarte.
- Se espera que varias terminen en **RC=4** por advertencias. Eso es el resultado buscado, no un error.
- Lo que se lee es el **listado**, no el código de retorno.
- Anota cada resultado en `RESULTADOS.md`.

---

## SONDA01 — ¿Puedo sobrescribir opciones?

La primera y la que define todo lo demás. Si la instalación fijó las opciones vía `IGYCDOPT`, tus sentencias `CBL` serán rechazadas y no tendrás capacidad de diagnóstico.

```cobol
       CBL INITCHECK(STRICT),RULES(NOLAXREDEF)
       IDENTIFICATION DIVISION.
       PROGRAM-ID. SONDA01.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-A            PIC 9(4).
       PROCEDURE DIVISION.
           DISPLAY WS-A
           GOBACK.
```

**Qué leer en el listado:**

1. El bloque de opciones en efecto. ¿Aparece `INITCHECK(STRICT)` o quedó `NOINITCHECK`?
2. ¿Hay algún mensaje de diagnóstico indicando que la opción no puede sobrescribirse?
3. ¿Aparece un mensaje sobre `WS-A` usado antes de recibir valor?

**Interpretación:**

| Resultado | Significado |
|---|---|
| La opción aparece activa y sale el mensaje sobre `WS-A` | Tienes capacidad de diagnóstico. Corre las demás sondas. |
| La opción fue rechazada o quedó en `NO...` | Las opciones están fijas. Trabajas solo en modo de análisis sobre fuente. Detén el kit aquí. |

Copia también el bloque completo de opciones en efecto a `RESULTADOS.md`: resuelve toda la familia OPT del catálogo de una sola vez.

---

## SONDA02 — ¿Está corregido el defecto FLW-01?

FLW-01 describe un falso positivo al mover datos desde `LINKAGE` hacia `WORKING-STORAGE` o `LOCAL-STORAGE`.

```cobol
       CBL INITCHECK(STRICT)
       IDENTIFICATION DIVISION.
       PROGRAM-ID. SONDA02.
       DATA DIVISION.
       LOCAL-STORAGE SECTION.
       01  LS-DESTINO      PIC X(4).
       LINKAGE SECTION.
       01  LK-ORIGEN       PIC X(4).
       PROCEDURE DIVISION USING LK-ORIGEN.
           MOVE LK-ORIGEN TO LS-DESTINO
           DISPLAY LS-DESTINO
           GOBACK.
```

`LS-DESTINO` recibe su valor del `MOVE` antes de usarse. Un mensaje de "puede usarse antes de ser establecido" sobre `LS-DESTINO` sería incorrecto.

| Resultado | Significado |
|---|---|
| Sin mensaje sobre `LS-DESTINO` | Defecto corregido. FLW-01 no aplica: los hallazgos de este patrón son reales. |
| Aparece el mensaje sobre `LS-DESTINO` | Defecto presente. Marcar todos los hallazgos de este patrón como falso positivo. |

---

## SONDA03 — ¿Está corregido el defecto FLW-02?

FLW-02 describe que el compilador no siempre reconocía qué campos quedan inicializados dentro de un párrafo invocado por `PERFORM`. Es el patrón de tu caso original.

```cobol
       CBL INITCHECK(STRICT)
       IDENTIFICATION DIVISION.
       PROGRAM-ID. SONDA03.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-CONTADOR     PIC S9(4) COMP-3.
       PROCEDURE DIVISION.
           PERFORM INICIALIZAR
           ADD 1 TO WS-CONTADOR
           DISPLAY WS-CONTADOR
           GOBACK.

       INICIALIZAR.
           MOVE ZERO TO WS-CONTADOR.
```

`WS-CONTADOR` queda inicializado por el único camino posible. Un mensaje sobre él sería incorrecto.

| Resultado | Significado |
|---|---|
| Sin mensaje sobre `WS-CONTADOR` | El análisis de `PERFORM` funciona. Los hallazgos INIT sobre `PERFORM` son reales. |
| Aparece el mensaje | Defecto presente. Los hallazgos INIT que dependan de `PERFORM` son sospechosos. |

**Variante útil.** Duplica la sonda agregando una bifurcación, para distinguir `STRICT` de `LAX`:

```cobol
           IF WS-BANDERA = 'S'
               PERFORM INICIALIZAR
           END-IF
           ADD 1 TO WS-CONTADOR
```

Aquí el mensaje **sí es correcto** bajo `STRICT` y **no** debe aparecer bajo `LAX`. Compila las dos variantes para confirmar cuál subopción está realmente en efecto.

---

## SONDA04 — ¿Qué hace INITIALIZE sobre un REDEFINES?

Esta es la regla `CRITICO` central del catálogo (RDF-01). Requiere **ejecutar**, no solo compilar. Si tienes un job de prueba disponible, vale mucho la pena.

```cobol
       IDENTIFICATION DIVISION.
       PROGRAM-ID. SONDA04.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-GRUPO.
           05  WS-TEXTO        PIC X(4).
           05  WS-NUMERO REDEFINES WS-TEXTO  PIC 9(4).
       PROCEDURE DIVISION.
           INITIALIZE WS-GRUPO
           DISPLAY 'TEXTO  : [' WS-TEXTO ']'
           DISPLAY 'NUMERO : [' WS-NUMERO ']'
           IF WS-NUMERO IS NUMERIC
               DISPLAY 'ES NUMERICO'
           ELSE
               DISPLAY 'NO ES NUMERICO'
           END-IF
           GOBACK.
```

**Resultado esperado:** `WS-TEXTO` queda en espacios y `WS-NUMERO` reporta `NO ES NUMERICO`, porque `INITIALIZE` no alcanza a los items con `REDEFINES`.

Este es el experimento que hace tangible la regla ante el equipo y ante el negocio. Cuesta una compilación y una ejecución, y convierte una advertencia teórica en evidencia propia.

Si además puedes compilarlo con `NUMCHECK(ZON)`, verás el mensaje de detección en ejecución. Anota si tu instalación lo permite.

---

## SONDA05 — Línea base de opciones

No requiere programa nuevo. Toma **cualquier** listado de una compilación que ya hayas hecho y extrae:

- Versión y nivel de servicio del compilador, del encabezado.
- El bloque completo de opciones en efecto.

Pégalos tal cual en `RESULTADOS.md` y en `docs-ibm/INDICE.md`. Es el insumo de mayor relación valor/esfuerzo de todo el kit: cuesta cero compilaciones y resuelve la familia OPT completa.

---

## Plantilla de RESULTADOS.md

Crea `sondas/RESULTADOS.md` con esta estructura. El agente la lee.

```markdown
# Resultados de sondas

Fecha:
Ejecutado por:
Ambiente:

## Nivel del compilador
<pegar encabezado del listado>

## Opciones en efecto
<pegar bloque completo>

## SONDA01 — Override de opciones
Resultado: PERMITE / NO PERMITE
Evidencia:

## SONDA02 — FLW-01
Resultado: CORREGIDO / PRESENTE / NO EJECUTADA
Evidencia:

## SONDA03 — FLW-02
Resultado: CORREGIDO / PRESENTE / NO EJECUTADA
Subopción de INITCHECK confirmada: STRICT / LAX / NO DETERMINADA
Evidencia:

## SONDA04 — INITIALIZE sobre REDEFINES
Resultado: CONFIRMADO / NO CONFIRMADO / NO EJECUTADA
Salida obtenida:
```
