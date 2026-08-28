# Guía de uso — CobolRulesAI

Agente de validación de reglas para la migración **Enterprise COBOL V4.2 → 6.4**.

**Contexto operativo:** equipo de desarrollo sin acceso de administrador de sistemas. Control sobre el código fuente y sobre el envío a compilar. Sin control sobre las opciones fijadas en la instalación, sin SMP/E, sin capacidad de aplicar PTF.

Esta guía está escrita para esa restricción. No pide nada que requiera un privilegio que no tienes.

---

## 1. Reencuadre: lo que sí controlas

| No controlas | Sí controlas |
|---|---|
| Opciones fijas de la instalación | Las sentencias `CBL` / `PROCESS` del fuente, si la instalación las admite |
| Aplicación de PTF | Programas sonda que revelan empíricamente el comportamiento del compilador |
| Nivel de servicio del compilador | Leerlo del encabezado del listado |
| Qué verificaciones están activas | Leerlas del bloque de opciones en efecto del listado |
| El módulo de carga de producción | Una copia del fuente en tu biblioteca personal |

**El punto central:** el listado que ya recibes en cada compilación contiene el nivel del compilador y las opciones en efecto. No necesitas preguntárselo a nadie. Lo que sí necesitas es **dejar de descartar esos listados**.

Y el análisis de mayor valor —las reglas `CRITICO` de las familias RDF y MIG— **no requiere compilar en absoluto**. Se hace sobre el fuente y los copybooks. Ese es el modo principal de trabajo, no el respaldo.

---

## 2. Puesta en marcha (una sola vez)

```bash
git clone <repo> cobol-rules-agent
cd cobol-rules-agent
bash scripts/descargar-docs-ibm.sh
```

Requiere `pdftotext` (`brew install poppler` en macOS). Sin la conversión a texto el agente no puede citar la documentación y todos los hallazgos saldrán `SIN-RESPALDO`.

Luego completa `docs-ibm/INDICE.md` con lo que **puedas** obtener. Los campos que no puedas resolver los dejas vacíos: el agente está diseñado para degradar con honestidad, no para inventar.

---

## 3. Estructura de entradas

```
entradas/
├── fuentes/       PGMXXXX.cbl        obligatorio
├── copybooks/     *.cpy              obligatorio si el fuente usa COPY
├── listados/      PGMXXXX.lst        el listado normal que ya generas
└── opciones/      compile-v42.txt    JCL o PROC de origen, si tienes acceso
sondas/
└── RESULTADOS.md  resultado de los programas sonda
```

Si falta un copybook, el agente **no adivina**: marca `INCOMPLETO`. Es preferible a un análisis que parezca completo y no lo sea.

---

## 4. Modo principal: análisis sobre fuente

Entrada: fuentes + copybooks. Sin compilar nada.

Detecta las familias INIT, RDF, NUM y MIG por lectura estructural. Aquí viven todos los hallazgos `CRITICO`, que son precisamente los que **el compilador no reporta** con las opciones apagadas de tu instalación.

Esta es la razón de ser del agente. Si el compilador reportara estos casos, no lo necesitarías.

---

## 5. Modo complementario: el listado que ya tienes

No necesitas una compilación especial. Necesitas conservar el listado de las compilaciones que ya haces.

De cada listado, aunque haya terminado en RC=0, extrae tres cosas:

**a) Nivel de servicio del compilador.** Está en el encabezado. Es el `6.4.0 Pnnnnnn`. Con ese dato el agente evalúa la familia FLW sin preguntarle a nadie.

**b) Bloque de opciones en efecto.** El listado imprime la lista completa de opciones vigentes. De ahí sale, directamente y sin intermediarios, si tienes `NOINITCHECK`, `NONUMCHECK`, `NORULES`, `NOPARMCHECK`, y qué `OPT` e `INVDATA` están activos. Ese bloque resuelve toda la familia OPT del catálogo.

**c) Mensajes emitidos.** Aunque el RC sea 0, puede haber mensajes informativos y de advertencia que no elevan el código de retorno pero sí señalan condiciones del catálogo.

Guarda el listado en `entradas/listados/` como `.txt` o `.lst`. Cuidado con la página de código al bajarlo: si la conversión EBCDIC → ASCII usa el CCSID equivocado, los acentos de los comentarios se corrompen y el agente termina citando basura.

### Cómo bajarlo, en orden de menor a mayor dependencia

**1. Transferencia del emulador 3270 (IND$FILE).** La opción con menos dependencias. Prácticamente todos los emuladores traen "Recibir archivo" o "Transfer → Receive". Funciona con tu acceso TSO normal: no requiere ningún servidor adicional ni gestión alguna. En SDSF, `XDC` sobre la salida del job la guarda en un dataset secuencial; desde ahí la recibes con el emulador. Verifica que la transferencia sea en modo texto con conversión ASCII y con la página de código correcta.

**2. FTP hacia z/OS.** Si el servidor FTP del host está habilitado —lo habitual—, funciona con tus credenciales de TSO sin configuración extra:

```
ftp <host>
get 'TUHLQ.LISTADO(PGMXXXX)' entradas/listados/PGMXXXX.lst
```

Confirma que la sesión esté en modo `ascii` antes del `get`, o el archivo llegará en EBCDIC.

**3. Copiar del propio ISPF.** Para un listado corto es viable: `BROWSE` sobre la salida y captura desde el emulador a archivo. Feo pero inmediato. Sirve para las sondas, que son de veinte líneas.

**4. Tu herramienta de compilación.** Si usas Endevor, Changeman o similar, casi siempre permiten visualizar y exportar el listado del último build desde la propia herramienta. Suele ser lo más rápido y ya tienes el permiso.

**5. Zowe CLI.** Es solo el cliente. Requiere que z/OSMF esté corriendo y expuesto por HTTPS, con la interfaz REST de jobs (`/zosmf/restjobs/`) habilitada y con tu userid autorizado en el gestor de seguridad. No es algo que el equipo de desarrollo pueda habilitar.

Antes de descartarlo, verifica si ya existe: apunta el navegador a `https://<host>:443/zosmf/restjobs/jobs` con tus credenciales de TSO. Si responde, z/OSMF está arriba y lo único que falta es el perfil de seguridad para tu usuario, que es una solicitud de servicio y no un privilegio de administrador. Desde z/OS V2.3 z/OSMF arranca por defecto en el IPL, así que hay probabilidad razonable de que ya esté disponible.

Si lo consigues, la ganancia es real: `zowe zos-jobs download output <JOBID> --directory entradas/listados/` automatiza todo el paso. Pero el montaje no depende de ello.

---

## 6. Programas sonda: cómo saber sin permisos

No puedes consultar qué PTF están aplicados. Pero puedes **provocar que el compilador te lo diga**.

Un programa sonda es un fuente mínimo, en tu biblioteca personal, construido para que su listado revele un comportamiento concreto del compilador. Lo compilas, lees el listado, anotas el resultado y lo descartas. No entra al flujo de promoción y no genera módulo de producción.

Ver `sondas/README.md` para el kit completo. En resumen:

| Sonda | Qué revela |
|---|---|
| `SONDA01` | Si la instalación te deja sobrescribir opciones con `CBL` |
| `SONDA02` | Si el defecto FLW-01 está corregido en tu compilador |
| `SONDA03` | Si el defecto FLW-02 está corregido |
| `SONDA04` | Qué hace realmente `INITIALIZE` sobre una vista `REDEFINES` en tu instalación |

`SONDA01` es la primera y la más importante: define si tienes o no capacidad de diagnóstico.

Registra los resultados en `sondas/RESULTADOS.md`. El agente lo lee y con eso evalúa la familia FLW sin depender del administrador.

---

## 7. Advertencia sobre el código de retorno

Si tu proceso de promoción exige **RC=0**, ten presente que activar `INITCHECK` o `RULES` produce mensajes de advertencia que elevan el código de retorno a **RC=4**.

Consecuencia práctica: **nunca actives esas opciones en el fuente que va a promoción.** Se usan solo en las sondas y en copias de trabajo dentro de tu biblioteca personal.

Si tu instalación no admite sobrescribir opciones (`SONDA01` negativa), este riesgo desaparece pero también desaparece la posibilidad de compilación diagnóstica. En ese caso trabajas exclusivamente en el modo de la sección 4, que sigue siendo el de mayor valor.

---

## 8. Flujo de trabajo

**Una vez, al inicio del proyecto:**

1. Corre `SONDA01`. Anota si puedes sobrescribir opciones.
2. Si `SONDA01` es positiva, corre `SONDA02`, `SONDA03` y `SONDA04`.
3. Guarda un listado cualquiera y extrae el nivel del compilador y las opciones en efecto.
4. Llena `docs-ibm/INDICE.md` y `sondas/RESULTADOS.md` con lo obtenido.

**Por cada programa:**

1. Copia el fuente y sus copybooks a `entradas/`.
2. Si tienes el listado, guárdalo también.
3. Abre Copilot Chat en VS Code, selecciona `cobol-rules-validator`.
4. Prompt `P0` una vez por sesión, luego `P1`.
5. Revisa `salidas/hallazgos-<programa>.md`.

---

## 9. Cómo leer la salida

| Marca | Significado | Qué hacer |
|---|---|---|
| `CRITICO` | Cambio silencioso de comportamiento frente a V4.2 | Corregir antes de promover. Bloquea GATE. |
| `POSIBLE-FALSO-POSITIVO` | Coincide con un defecto conocido del compilador | Resolver con la sonda correspondiente |
| `INCOMPLETO` | Falta un copybook o dato para concluir | Aportar el insumo y reprocesar |
| `SIN-RESPALDO` | Sin sustento documental localizable | Observación, no hallazgo |
| `NO EVALUABLE` | Falta corpus o insumo estructural | Completar lo que esté a tu alcance |

Un informe con `NO EVALUABLE` no es un mal informe. Es el agente diciéndote qué le falta, en lugar de rellenar con suposiciones. Dado tu contexto de permisos, es esperable que algunas reglas queden permanentemente en ese estado, y está bien.

---

## 10. Lo que este montaje no puede resolver

Sé explícito con esto ante el negocio y ante el GATE:

- **No puedes confirmar el inventario de PTF.** Las sondas te dan comportamiento observado, no la lista aplicada. Es suficiente para decidir sobre código, no para un reporte de cumplimiento.
- **No puedes cambiar las opciones de producción.** Los hallazgos de la familia OPT quedan como recomendación documentada hacia el área de sistemas, no como acción tuya.
- **RDF-02 y NUM-02 solo se confirman en ejecución.** El agente detecta la condición estructural. Confirmar que el dato realmente llega inválido requiere `NUMCHECK` activo o una prueba con datos reales.

Documentar estos límites protege al equipo: un hallazgo `CRITICO` que el desarrollo detectó y no pudo verificar por falta de permisos es un riesgo transferido, no un riesgo ignorado.
