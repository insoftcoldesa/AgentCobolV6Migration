# Prompts

Copiar y pegar en Copilot Chat con el agente `cobol-rules-validator` seleccionado.

---

## P0 · Arranque de sesión

Úsalo **una vez al inicio de cada sesión**, antes de pedir cualquier análisis. Su función es que el agente cargue el catálogo y te diga qué le falta, en lugar de improvisar más tarde.

```
Arranque de sesión.

1. Lee completo reglas/catalogo-reglas.md y docs-ibm/INDICE.md.
2. Verifica el estado del corpus documental:
   - ¿Existen los manuales 6.4 convertidos en docs-ibm/6.4/txt/?
   - ¿Existen los manuales V4.2 en docs-ibm/origen/txt/?
   - ¿Está registrado el nivel del compilador en INDICE.md?
   - ¿Están registradas las opciones en efecto?
   - ¿Existe sondas/RESULTADOS.md y qué sondas están ejecutadas?
3. Reporta en una tabla: familia de reglas, estado (EVALUABLE / NO EVALUABLE),
   y qué insumo falta para las que no lo son.
4. Para cada insumo faltante indica si el equipo de desarrollo puede
   obtenerlo por su cuenta (sonda, listado propio, lectura de fuente) o si
   requiere al área de sistemas. Separa las dos listas.
5. No analices ningún programa todavía. Espera instrucción.
```

---

## P1 · Análisis de un programa

```
Analiza el programa <NOMBRE>.

Insumos:
- Fuente:     entradas/fuentes/<NOMBRE>.cbl
- Copybooks:  entradas/copybooks/
- Listado:    entradas/listados/<NOMBRE>.lst
- Opciones:   entradas/opciones/

Sigue los siete pasos del procedimiento. No omitas el mapa de datos ni el
mapa de flujo: son la base de las familias INIT y RDF.

Antes de la tabla de hallazgos, dime explícitamente:
- Qué copybooks resolviste y cuáles no encontraste.
- Qué reglas quedaron NO EVALUABLE y por qué.

Genera salidas/hallazgos-<NOMBRE>.md.
```

---

## P2 · Correlación con el listado de compilación

Cuando ya tengas el listado y quieras cruzarlo contra el catálogo.

```
Correlaciona el listado entradas/listados/<NOMBRE>.lst con el catálogo.

Produce tres bloques separados:

A. Mensajes emitidos por el compilador, mapeados a la regla del catálogo
   que les corresponde. Marca los que coincidan con la familia FLW.

B. Condiciones del catálogo que se cumplen en el fuente pero que el
   compilador NO reportó, indicando qué opción está apagada y por eso
   quedó silenciosa. Este bloque es el más importante: son los defectos
   que hoy llegan a producción sin señal.

C. Mensajes del listado que no corresponden a ninguna regla del catálogo.
   Propón si amerita una regla nueva, sin agregarla tú.

Del encabezado del listado extrae y reporta la versión y el nivel de
servicio del compilador, y las opciones que estuvieron en efecto.
```

---

## P3 · Priorización de un lote

```
Analiza todos los programas en entradas/fuentes/.

No generes el detalle completo de cada uno. Produce un tablero de
priorización con una fila por programa:

| Programa | CRITICO | ALTO | MEDIO | BAJO | Regla de mayor riesgo | Copybooks faltantes |

Ordena por cantidad de CRITICO descendente. Al final, lista los tres
programas que recomiendas atacar primero y por qué, en una línea cada uno.

Luego espera instrucción para el detalle de alguno.
```

---

## P4 · Verificación de una regla específica

Cuando quieras auditar el propio catálogo o entender un hallazgo.

```
Explícame la regla <ID>.

Incluye:
- Texto de la regla tal como está en el catálogo.
- Dónde exactamente se sustenta en docs-ibm/ (manual y sección), citado.
- Un ejemplo mínimo de código que la dispara.
- Un ejemplo mínimo que NO la dispara, y por qué.

Si no encuentras el sustento documental, dilo. No lo construyas de memoria.
```

---

## P5 · Plan de sondas

Cuando el agente reporte reglas NO EVALUABLE y quieras saber cómo desbloquearlas
sin depender de permisos que no tienes.

```
No tenemos acceso de administrador de sistemas: no podemos aplicar PTF,
consultar SMP/E ni cambiar opciones fijas de la instalación. Solo
controlamos el fuente y el envío a compilar.

Con esa restricción, dime:

A. Qué reglas del catálogo puedo desbloquear ejecutando sondas de
   sondas/README.md, y en qué orden conviene correrlas.
B. Qué reglas quedan permanentemente NO EVALUABLE en nuestro contexto,
   y qué se debe documentar frente al GATE para que ese riesgo quede
   transferido y no ignorado.
C. Si hay alguna sonda adicional que valga la pena diseñar para nuestro
   caso, descríbela: qué construcción de código y qué se leería del
   listado. No la des por válida sin sustento documental.

No propongas acciones que requieran privilegios que no tenemos.
```
