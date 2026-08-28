# Catálogo de reglas — Migración a IBM Enterprise COBOL for z/OS 6.4

Versión 1.0. Documento normativo del agente `cobol-rules-validator`.

Cada regla trae: condición detectable, severidad base, mensaje del compilador asociado (cuando existe) y remediación. El campo **Respaldo** indica dónde verificar en `docs-ibm/`.

Convención de severidad: `CRITICO` = cambio silencioso de comportamiento. `ALTO` = falla visible. `MEDIO` = advertencia o riesgo latente. `BAJO` = higiene.

---

## Familia INIT — Inicialización y flujo de asignación

### INIT-01 · Uso antes de asignación garantizada
**Severidad:** MEDIO (ALTO si el campo alimenta una decisión de negocio)
**Condición:** Existe al menos un camino de ejecución hacia un uso del campo que no atraviesa ningún punto de asignación.
**Mensaje:** `IGYCB7311-W` — el data item puede usarse antes de ser establecido.
**Detección:** activo solo si se compila con `INITCHECK`. Con `INITCHECK(STRICT)` se exige asignación en **todos** los caminos; con `INITCHECK(LAX)`, en **al menos uno**.
**Remediación:** cláusula `VALUE` en la declaración, o asignación en un punto que domine todos los caminos.
**Respaldo:** Customization Guide, opción INITCHECK. Migration Guide, pitfall de datos usados antes de recibir valor.

### INIT-02 · Campo de WORKING-STORAGE sin VALUE ni asignación previa
**Severidad:** MEDIO
**Condición:** Declaración en `WORKING-STORAGE` sin `VALUE`, cuyo primer uso ocurre antes del primer `MOVE`/`INITIALIZE`/`COMPUTE` que lo alcance.
**Nota:** `WORKING-STORAGE` se inicializa una sola vez al cargar el módulo. En un programa llamado repetidamente sin `IS INITIAL`, conserva el último valor de la invocación anterior. Esto es un riesgo aparte, ver INIT-07.
**Remediación:** `VALUE` en la declaración.

### INIT-03 · Inicialización condicional sin rama por defecto
**Severidad:** ALTO
**Condición:** El campo se asigna únicamente dentro de un `IF` sin `ELSE`, o de un `EVALUATE` sin `WHEN OTHER`, y se usa después del `END-IF` / `END-EVALUATE`.
**Remediación:** agregar la rama por defecto con asignación explícita, o mover la inicialización antes de la bifurcación.

### INIT-04 · Copybook con VALUE expandido en sección que no lo admite
**Severidad:** ALTO
**Condición:** Un copybook que contiene cláusulas `VALUE` en niveles distintos de 88 se expande en `LINKAGE SECTION` o `FILE SECTION`.
**Efecto:** error de compilación. Si el mismo copybook se comparte entre programas que lo expanden en `WORKING-STORAGE` y en `LINKAGE`, no se le puede agregar `VALUE`.
**Remediación:** parear el copybook de datos con un copybook de PROCEDURE DIVISION que ejecute la inicialización, invocado como primera sentencia.
**Respaldo:** Language Reference, cláusula VALUE — restricciones por sección.

### INIT-05 · Párrafo que depende del llamador para su inicialización
**Severidad:** MEDIO
**Condición:** Un párrafo invocado por `PERFORM` usa un campo que asume inicializado por el flujo previo, y existe más de un punto de invocación con estados distintos.
**Remediación:** que el párrafo se inicialice a sí mismo en su primera sentencia.

### INIT-06 · PERFORM THRU con GO TO que fragmenta el grafo de flujo
**Severidad:** MEDIO
**Condición:** Rango `PERFORM ... THRU` con salidas por `GO TO` hacia etiquetas intermedias.
**Efecto:** degrada el análisis de flujo del compilador y genera falsos positivos y falsos negativos de `INITCHECK`.
**Remediación:** eliminar el `GO TO`; usar `EXIT PARAGRAPH` o reestructurar.

### INIT-07 · Estado residual entre invocaciones
**Severidad:** ALTO
**Condición:** Subprograma llamado múltiples veces en la misma unidad de ejecución, sin `PROGRAM-ID ... IS INITIAL` y sin `LOCAL-STORAGE`, que usa acumuladores o banderas de `WORKING-STORAGE` sin reinicializar al entrar.
**Remediación:** mover a `LOCAL-STORAGE` con `VALUE`, que se reinicializa en cada invocación, o inicializar explícitamente al entrar.

---

## Familia RDF — REDEFINES

### RDF-01 · INITIALIZE no alcanza la vista redefinida
**Severidad:** CRITICO
**Condición:** `INITIALIZE` sobre un grupo que contiene items con `REDEFINES`, seguido de uso de la vista redefinida.
**Fundamento:** `INITIALIZE` no afecta a los data items que tienen cláusula `REDEFINES` ni a sus subordinados. Solo se inicializa la definición original.
**Efecto:** la vista redefinida queda con los bytes que le dejó la definición base. Si la base es alfanumérica inicializada a espacios y la vista es zoned decimal, el resultado es dato numérico inválido.
**Remediación:** asignar explícitamente por la vista que se va a usar: `MOVE ZERO TO <campo-redefinido-numerico>`.
**Respaldo:** Language Reference, sentencia INITIALIZE — items no afectados.

### RDF-02 · Base alfanumérica con espacios bajo vista numérica
**Severidad:** CRITICO
**Condición:** Campo `PIC X(n)` inicializado a `SPACES` (o dejado sin inicializar) redefinido por un `PIC 9(n)` USAGE DISPLAY o PACKED-DECIMAL que luego se usa en contexto numérico.
**Efecto:** los bits de zona quedan en `x'4'`, que no es zona válida. Las comparaciones numéricas pueden dar resultados distintos entre la versión origen y 6.4, y entre niveles de `OPT`, **sin mensaje ni abend**.
**Remediación:** corregir en el origen del dato. Como paliativo temporal, `INVDATA` genera código compatible con el comportamiento anterior, con costo de rendimiento.
**Respaldo:** Migration Guide, datos inválidos en items numéricos USAGE DISPLAY. Programming Guide, opciones INVDATA y NUMCHECK.

### RDF-03 · REDEFINES con longitud distinta
**Severidad:** MEDIO
**Condición:** El item redefinidor tiene longitud distinta al redefinido.
**Mensajes:** `IGYDS1154-W` e `IGYDS1073-I`.
**Detección:** el valor por defecto `RULES(LAXREDEF)` emite estos mensajes solo para items que **no** son de nivel 01. Para detectarlo también en nivel 01 hay que compilar con `RULES(NOLAXREDEF)`.
**Impacto práctico:** los layouts de copybook suelen redefinirse a nivel 01, justo el caso que el default silencia.
**Remediación:** igualar longitudes con `FILLER` explícito, o documentar y justificar la diferencia.
**Respaldo:** Programming Guide y Customization Guide, opción RULES, subopciones LAXREDEF / NOLAXREDEF.

### RDF-04 · Vista numérica usada sin validación ni discriminador
**Severidad:** ALTO
**Condición:** Uso de una vista `REDEFINES` numérica sin `IF ... IS NUMERIC` previo y sin un campo discriminador externo al área redefinida que indique cuál vista es la vigente.
**Remediación:** agregar discriminador explícito y decidir con `EVALUATE ... WHEN OTHER`, o validar con `IF NUMERIC` antes de usar.

### RDF-05 · MOVE de grupo hacia estructura con vistas numéricas
**Severidad:** ALTO
**Condición:** `MOVE` a nivel de grupo (movimiento alfanumérico) hacia una estructura que contiene campos numéricos o vistas redefinidas numéricas.
**Efecto:** el movimiento es byte a byte sin conversión; puede depositar contenido no numérico en campos numéricos.
**Remediación:** `MOVE CORRESPONDING` o movimientos campo a campo por la vista correcta.

### RDF-06 · REDEFINES sobre longitud variable con OCCURS DEPENDING ON
**Severidad:** ALTO
**Condición:** Estructura redefinida donde una de las vistas contiene `OCCURS ... DEPENDING ON`, y el campo de control no está garantizado dentro de rango antes del uso.
**Remediación:** validar el campo de control antes de referenciar la tabla; compilar pruebas con `SSRANGE`.

---

## Familia NUM — Datos numéricos

### NUM-01 · Literal alfanumérico en contexto numérico
**Severidad:** ALTO
**Condición:** Literal entre comillas usado como operando de `ADD`, `SUBTRACT`, `MULTIPLY`, `DIVIDE`, `COMPUTE`, o como emisor de un `MOVE` hacia un campo numérico.
**Ejemplo:** `ADD '001' TO WK-NUM`, `MOVE '001' TO WK-NUM` donde `WK-NUM PIC 9(3)`.
**Remediación:** usar literal numérico sin comillas.

### NUM-02 · Comparación numérica sobre USAGE DISPLAY de origen externo
**Severidad:** CRITICO
**Condición:** Campo numérico USAGE DISPLAY poblado desde archivo, LINKAGE, DB2 o REDEFINES, usado en comparación o aritmética sin validación previa.
**Efecto:** si contiene zona o signo inválidos, el resultado puede diferir entre la versión origen y 6.4 y entre niveles de `OPT`.
**Remediación:** validar en el origen. Detectar con `NUMCHECK(ZON)` en pruebas.

### NUM-03 · Dependencia de comportamiento NUMPROC(MIG) del compilador origen
**Severidad:** CRITICO
**Condición:** El programa se compilaba con `NUMPROC(MIG)` en la versión origen y procesa datos con signo o zona inválidos.
**Remediación:** la ruta de compatibilidad es `INVDATA`, que reemplaza a la opción `ZONEDATA` ahora deprecada. Es paliativo, no corrección.
**Respaldo:** Migration Guide, opciones INVDATA y ZONEDATA.

### NUM-04 · Truncamiento silencioso en campos binarios
**Severidad:** MEDIO
**Condición:** Asignación a `COMP` / `BINARY` cuyo valor puede exceder el PIC declarado.
**Detección:** `DIAGTRUNC` para diagnóstico en compilación; `NUMCHECK(BIN)` en ejecución.

---

## Familia MIG — Salto de versión V4.2 → 6.4

Esta familia aplica solo porque el origen es **Enterprise COBOL for z/OS V4.2**. Es un salto de dos generaciones: V4.2 es la última versión con el generador de código antiguo, y V5 introdujo uno completamente nuevo. Todos los cambios de comportamiento documentados entre V4 y V6 aplican íntegros, sin escalones intermedios.

Referencia central: **Migration Guide 6.4, Capítulo 17 "Upgrading from Enterprise COBOL Version 4"** y **Capítulo 16 "Changes with Enterprise COBOL 6"**.

### MIG-01 · NUMPROC(MIG) en las opciones de origen
**Severidad:** CRITICO
**Condición:** El programa se compilaba en V4.2 con `NUMPROC(MIG)`. Esa subopción no existe en V6.
**Efecto:** el comportamiento frente a signo, dígitos o zona inválidos cambia. Combinado con RDF-02 o NUM-02, produce resultados distintos sin ninguna señal.
**Remediación:** aplicar la equivalencia oficial. El Customization Guide y el Performance Tuning Guide traen la tabla **"Setting INVDATA and NUMPROC options when migrating from earlier COBOL versions"** — usarla, no improvisar la equivalencia.
**Respaldo:** Customization Guide 6.4, tabla 4. Performance Tuning Guide 6.4, capítulo de ajuste de opciones.

### MIG-02 · Opción de compilación de V4.2 inexistente en V6
**Severidad:** ALTO
**Condición:** El JCL o el `PROCESS`/`CBL` del fuente especifica una opción que fue eliminada en V6. Casos conocidos: `SIZE`, la subopción `MIG` de `NUMPROC`. `OPTIMIZE` se tolera pero ya no opera igual.
**Verificación obligatoria:** contrastar contra **Migration Guide 6.4, tabla 34 "Compiler option not available in Enterprise COBOL 6"**. No usar listas de terceros ni memoria del agente.
**Remediación:** eliminar o sustituir según la tabla.

### MIG-03 · NORENT con residencia sobre la línea de 16 MB
**Severidad:** ALTO
**Condición:** Módulo compilado `NORENT` en V4.2 que se ejecuta o se espera ejecutar por encima de los 16 MB.
**Efecto:** no soportado en V6. El `RENT`/`NORENT` determina el `RMODE` y con ello dónde reside `WORKING-STORAGE`.
**Respaldo:** Customization Guide 6.4, tablas "Effect of RENT and RMODE on residency mode" y "Effect of RMODE and RENT | NORENT on residency mode".

### MIG-04 · AMODE(24) / RMODE(24)
**Severidad:** ALTO
**Condición:** Programa o subprograma llamado con `AMODE 24` o `RMODE 24`, o CSECT de ensamblador con `RMODE 24` en la cadena de llamadas.
**Efecto:** limita la residencia y bloquea las mejoras del compilador; en algunos escenarios de llamada estática desde módulos pre-V5 el patrón no es soportado.
**Remediación:** migrar a `AMODE(31|ANY)` y `RMODE(ANY)`.

### MIG-05 · Dependencia del contenido de WORKING-STORAGE no inicializada
**Severidad:** CRITICO
**Condición:** Campo de `WORKING-STORAGE` sin `VALUE` cuyo valor efectivo en V4.2 provenía de cómo el compilador antiguo disponía la memoria, y del que el programa depende.
**Efecto:** la asignación y el contenido inicial cambian en V6. Un programa que "funcionaba" en 4.2 puede comportarse distinto sin mensaje.
**Nota:** esta es precisamente la razón por la que IBM creó `INITCHECK`, descrito como especialmente problemático al migrar desde compiladores previos a V5.
**Remediación:** `VALUE` explícito. Detectar con `INITCHECK(STRICT)`, que es la herramienta diseñada para este caso.
**Respaldo:** Migration Guide 6.4, sección "WORKING-STORAGE SECTION changes".

### MIG-06 · Desajuste de longitud en parámetros de CALL
**Severidad:** CRITICO
**Condición:** `CALL ... USING` donde el llamador pasa un área menor que la declarada en la `LINKAGE SECTION` del llamado, o referencia posicional más allá del área real.
**Efecto:** corrupción de memoria más allá del fin de `WORKING-STORAGE`. En V4.2 podía pasar inadvertido; en V6 el diseño de memoria es distinto y el efecto cambia. Mensaje asociado en ejecución: `IGZ0318W`.
**Detección:** `PARMCHECK` en pruebas. La instalación tiene `NOPARMCHECK`, así que hoy no hay detección.
**Remediación:** alinear las declaraciones de ambos lados; unificar vía copybook compartido.

### MIG-07 · Palabra reservada nueva en V6 usada como nombre de dato
**Severidad:** ALTO
**Condición:** Nombre de dato, párrafo o sección que en V4.2 era válido y en 6.4 es palabra reservada.
**Verificación:** contrastar contra la lista de palabras reservadas del **Language Reference 6.4**, comparada con la del **Language Reference V4.2** en `docs-ibm/origen/txt/`. El agente debe hacer la comparación sobre los dos documentos, no desde su conocimiento previo.
**Remediación:** renombrar, o evaluar una tabla de palabras reservadas personalizada vía `IGYCDOPT`.

### MIG-08 · Convivencia de módulos V4.2 y V6 en el mismo link-edit
**Severidad:** MEDIO
**Condición:** Módulo de carga que combina objetos compilados en V4.2 y en 6.4.
**Respaldo:** Migration Guide 6.4, sección "Binding (link-editing) Enterprise COBOL programs".
**Nota:** existe una lista de PTF de Enterprise COBOL V4 requeridos para soportar la migración a V5/V6. Confirmar que estén aplicados en el entorno de origen.

### MIG-09 · REGION insuficiente en la compilación
**Severidad:** BAJO
**Condición:** JCL de compilación que conserva el `REGION` dimensionado para V4.2.
**Efecto:** V5 y posteriores requieren considerablemente más memoria para generar y optimizar el código; la compilación falla o se degrada.
**Remediación:** revisar el `REGION` del step de compilación según el Programming Guide 6.4.

---

## Familia FLW — Defectos conocidos del análisis de flujo

Estas reglas no describen defectos del código sino del compilador. Su función es evitar que el equipo reescriba código correcto por un falso positivo. Todo hallazgo que coincida se marca `POSIBLE-FALSO-POSITIVO`.

### FLW-01 · MOVE desde LINKAGE hacia WORKING-STORAGE o LOCAL-STORAGE
**Condición:** `IGYCB7311-W` sobre el receptor de un `MOVE` cuyo emisor está en `LINKAGE SECTION`.
**Estado:** defecto documentado y corregido por PTF. **Verificar el nivel de PTF instalado antes de reportar.**
**Respaldo:** APAR PH23443 / PH25226.

### FLW-02 · INITCHECK y análisis de PERFORM
**Condición:** Mensajes `IGYCB7311-W` inconsistentes en programas con `PERFORM` sobre campos que sí quedan inicializados por el párrafo invocado.
**Estado:** corregido por PTF; el compilador no usaba correctamente la información de qué items quedan inicializados por cada `PERFORM`.
**Respaldo:** APAR PH37213.

### FLW-03 · INITCHECK(STRICT) con OPT(0) y EXEC CICS HANDLE
**Condición:** Mensajes adicionales de `IGYCB7311-W` frente a `INITCHECK(LAX)` u `OPT(1|2)`, en programas con múltiples `EXEC CICS HANDLE`.
**Circunvención documentada:** compilar con `OPT(1|2)`, `NOINITCHECK` o `INITCHECK(LAX)`.
**Respaldo:** APAR PH35976 / PH37332.

---

## Familia OPT — Configuración de compilación

### OPT-01 · Ausencia de red de seguridad en pruebas
**Severidad:** ALTO
**Condición:** Ambiente de desarrollo o pruebas compilando con `NONUMCHECK`.
**Efecto:** sin detección en ejecución de datos no numéricos. Combinado con RDF-01 o RDF-02, el defecto llega a producción sin ninguna señal.
**Remediación:** `NUMCHECK(ZON,PAC,BIN)` en pruebas. En producción se retira por costo de rendimiento.

### OPT-02 · NORULES en desarrollo
**Severidad:** MEDIO
**Condición:** Compilación sin `RULES`.
**Efecto:** se pierden los avisos de REDEFINES con longitud desigual y de construcciones ineficientes.
**Remediación:** `RULES(NOLAXREDEF,NOLAXPERF)` en desarrollo.

### OPT-03 · INITCHECK ausente o degradado a LAX en desarrollo
**Severidad:** MEDIO
**Remediación:** `INITCHECK(STRICT)` en desarrollo. Degradar a `LAX` solo cuando se haya confirmado que los mensajes provienen de un patrón de la familia `FLW`.

### OPT-04 · INVDATA usado como solución permanente
**Severidad:** ALTO
**Condición:** `INVDATA` activo en producción sin un plan de corrección de los datos de origen.
**Efecto:** el defecto de datos persiste y se paga costo de rendimiento de forma indefinida.
**Remediación:** registrar la deuda técnica con fecha de corrección.

### OPT-05 · PARMCHECK y SSRANGE ausentes en pruebas
**Severidad:** MEDIO
**Remediación:** activar en el ciclo de pruebas de la migración; retirar en producción.

---

## Matriz de trazabilidad regla → manual

| Familia | Manual principal | Manual de apoyo |
|---|---|---|
| INIT | Customization Guide 6.4 (opciones) | Migration Guide 6.4 (pitfalls) |
| RDF | Language Reference 6.4 (INITIALIZE, REDEFINES) | Programming Guide 6.4 (RULES) |
| NUM | Migration Guide 6.4 (datos inválidos) | Programming Guide 6.4 (INVDATA, NUMCHECK) |
| MIG | Migration Guide 6.4, cap. 16 y 17 | Language Reference y Programming Guide V4.2 (`docs-ibm/origen/`) |
| FLW | APARs en IBM Support | Migration Guide 6.4 |
| OPT | Customization Guide 6.4 | Performance Tuning Guide 6.4 |

---

## Nota sobre la comparación entre versiones

La familia `MIG` es la única que exige leer **dos** corpus: el de destino y el de origen. Para MIG-02 y MIG-07 el agente debe comparar textualmente listas de las dos versiones. Si `docs-ibm/origen/txt/` está vacío, esas dos reglas se marcan `NO EVALUABLE` y se declara así en la cobertura del informe. No se sustituyen por conocimiento del modelo.
