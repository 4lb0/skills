---
name: crear-diario
description: >
  Convierte una nota o artículo periodístico en un HTML imprimible con formato de diario
  (masthead, volanta, titular, copete, firma, columnas, letra capital y citas destacadas),
  listo para imprimir o guardar como PDF en A4. Genera `print.html` (multipágina, una hoja
  A4 por página) y, cuando el usuario pide "en una sola página" o una "versión resumida",
  genera `print_v2.html` (todo en una única hoja).
  TRIGGER — usar SIEMPRE que el usuario: pase una nota/texto periodístico y pida dejarlo
  "como un diario", "como si fuera un diario", "para imprimir", "imprimible", "print.html",
  "maquetar una nota", "que se vea como periódico", "para imprimir en A4"; mencione "diario",
  "periódico" o "nota" junto con "imprimir"; aporte el texto con los marcadores `<Titulo>` /
  `<Cuerpo>`; o pida una "versión resumida", "en una sola página", "que entre en una hoja",
  "en un solo folio" de una nota. También si el usuario ya tiene un `print.html` y quiere
  una versión de una página.
  SKIP cuando: el usuario quiere un documento de texto común (Word/Google Docs/PDF de texto),
  una presentación/slides, o pide "imprimir" algo que no es una nota (por ejemplo una tabla,
  una receta o una factura) sin el formato de diario.
---

# Crear diario — de una nota a un HTML imprimible

## Qué hace

Toma una nota y la maqueta con estética de diario, en un archivo HTML **autocontenido**
(sin CDN, sin fuentes externas, todo el CSS embebido) para imprimir o exportar a PDF.

Dos salidas según lo que pida el usuario:

| Pedido del usuario | Archivo | Contenido |
|---|---|---|
| Por defecto | `print.html` | Multipágina: reparte la nota completa en hojas A4. |
| "en una sola página", "que entre en una hoja", "versión resumida" | `print_v2.html` | Una única hoja A4 con la nota **resumida**. |

Los archivos se escriben en el directorio de trabajo actual.

## Regla de oro: hojas autocontenidas, nunca columnas continuas

Esta es la lección más importante y la razón por la que existe esta skill.

NO maquetar la nota como **un solo bloque de columnas CSS continuo** que el navegador tenga
que partir entre páginas al imprimir. Firefox, al imprimir, tiene problemas conocidos al
fragmentar `column-count` entre hojas: las columnas se "salen" de la hoja, se cortan o se
solapan con el pie. En pantalla se ve bien, pero en la impresión se rompe.

La solución es modelar **cada página impresa como una hoja independiente**:

- Cada página es un `<article class="sheet">` con **alto fijo** (296 mm), padding interno y
  `overflow: hidden`.
- En `@media print` cada `.sheet` lleva `break-after: page` (y `page-break-after: always`).
- Las columnas `.cols` viven **dentro** de una hoja y nunca cruzan de página.

Así cada hoja se imprime tal cual, igual en Chrome, Firefox y Safari, y sin depender de que
el navegador sepa fragmentar columnas.

## Entrada

El usuario puede pasar la nota de varias formas:

- Con marcadores: `<Titulo> … </Titulo>` y `<Cuerpo> … </Cuerpo>` (los que usa este usuario).
- Texto plano con un primer renglón que es el título.
- Un archivo (`.md`, `.txt`) o un link.

Extraé: **título**, **cuerpo** (párrafos separados por línea en blanco) y, si existen,
**frases entre comillas** fuertes (candidatas a cita destacada). Descartá líneas de servicio
que no sean parte de la nota (por ejemplo banners de "periodismo crítico" o avisos).

Datos de la cabecera: si el usuario no aclara nombre de diario, sección ni fecha, usá un
nombre genérico (por defecto **La Crónica**), la sección del tema (p. ej. "Sociedad") y la
fecha de hoy en español. Ofrecé cambiar esos datos al final.

## Flujo de trabajo

1. **Leer la nota** y separar título, copete/lead y párrafos.
2. **Elegir la plantilla**
   - Multipágina → `assets/plantilla-multipagina.html`
   - Una página → `assets/plantilla-una-pagina.html`
3. **Completar los `{{PLACEHOLDERS}}`** con el contenido real (no dejar marcadores).
4. **Repartir el contenido** (ver abajo).
5. **Escribir** `print.html` o `print_v2.html`.
6. **Verificar** con `scripts/verificar.sh` (ver abajo). Esto NO es opcional en la práctica:
   el objetivo es que ninguna hoja se corte.
7. **Avisar cómo imprimir**: A4, escala 100% (que NO esté en "ajustar al área imprimible").

## Modo multipágina (`print.html`)

- Replicá un `<article class="sheet">` por cada página.
- La primera hoja lleva masthead, volanta, titular, copete, firma y lede; las siguientes
  llevan un `runhead` (cabecera corrida con sección + "Página N").
- Repartí los párrafos entre hojas apuntando a que cada hoja **llene bien pero sin desbordar**
  (dejá ~1 cm de aire sobre el pie). Un punto de corte natural cada ~2 a 4 párrafos largos.
- Reglas de maquetación:
  - Primer párrafo de la nota con `class="dropcap"` (letra capital).
  - Convertí las frases fuertes entre comillas en `.pullquote` con su `.attribution`.
  - Usá `.section-title` en los cambios de tema (equivalentes a los "subtítulos" del texto).
- Si una hoja se pasa: mové el último párrafo a la hoja siguiente. Si queda muy vacía: traé
  un párrafo de la anterior. Ajustá antes de tocar el tamaño de fuente.

## Modo una página (`print_v2.html`)

- Resumí la nota a **~300–360 palabras**, conservando: qué pasó, quién, dónde, los datos
  duros (lugares, cifras, nombres de colegios/organismos) y 1–2 citas textuales.
- Estructura sugerida: intro → el patrón/hecho central → desarrollo → subtítulo (`section-title`)
  → otros hechos → cierre.
- Sirve cualquier cita destacada; si hay dos buenas, usá las dos.
- Si se pasa por 1–2 líneas **acortá frases** (no bajes la fuente más allá de ~9.4 pt) y
  volvé a verificar. No dejes texto cortado.

## Verificación (clave)

Corré:

```bash
bash scripts/verificar.sh print.html        # o print_v2.html
```

Esto imprime el HTML a PDF con **Chrome** y (si `puppeteer-core` está instalado) con
**Firefox**, y exporta un PNG por página a la carpeta de salida. Después **mirá los PNG** y
confirmá que:

- La cantidad de páginas es la esperada.
- **Ninguna** página tiene texto cortado abajo ni tapado por el pie (`.colophon`).
- En una sola página: el contenido termina con aire antes del pie.

Si algo se corta o sobra, reajustá el reparto de párrafos (o el resumen) y volvé a verificar.
La verificación con Firefox importa especialmente porque es donde fallaba el multicol continuo.

## Impresión

- Papel **A4** y **Escala 100%** (evitar "ajustar al área imprimible" / "shrink to fit").
- El fondo crema es opcional: si "Imprimir fondos" está desactivado, sale sobre blanco y se
  ve igual de bien.

## Recursos

- `assets/plantilla-multipagina.html` — base autocontenida con el CSS y una hoja de ejemplo.
- `assets/plantilla-una-pagina.html` — base de una sola hoja (tipografía más compacta).
- `scripts/verificar.sh` — imprime a PDF (Chrome/Firefox) y exporta PNG por página.
- `scripts/firefox-print.js` — impresión Firefox headless (requiere `puppeteer-core`).
