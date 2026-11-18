# Salvando la Historia — Menú de inicio (Godot 4.7)

Menú de inicio para **dispositivos móviles**, construido con los assets de
Pixelorama de esta carpeta y probado con Godot 4.7.2 (el mismo que tienes
instalado).

## Cómo abrirlo

1. Godot > **Importar** > selecciona `menu_inicio_godot/project.godot`.
2. **F5** para jugar (la ventana mide 1280×720 y se adapta a cualquier tamaño).

Controles: flechas ↑/↓ para moverse, **Enter** para aceptar, o simplemente
toca los botones (el táctil funciona igual que el ratón).

## Qué hace cada cosa

| Archivo | Función |
|---|---|
| `scenes/menu_inicio.tscn` | Escena principal (fondo + viñeta + título + 4 botones) |
| `scripts/menu_inicio.gd` | Ancla el bloque **abajo a la izquierda** y lo escala según la pantalla |
| `scripts/boton_menu.gd` | El botón: plato propio, viñeta al enfocar, gris + encogido al pulsar |
| `assets/` | PNG exportados de los `.pxo` (capas separadas: texto y viñetas) |
| `preview/captura.tscn` | Genera las imágenes de preview (ver abajo) |
| `preview/prueba_interaccion.tscn` | Prueba automática de foco/navegación/activación |
| `preview/salidas/` | Imágenes ya generadas |

## Las animaciones de los botones

1. **NORMAL** — solo el texto dorado (asset amarillo).
2. **MARCADO** (foco) — entra la **viñeta** deslizándose desde fuera con fundido
   y un pulso suave; el plato se aclara y el botón crece un 5 %.
3. **PRESIONADO** — cambia al **asset gris** y se **encoge al 88 %** manteniendo
   el centro fijo; si se arrastra fuera del botón, se cancela.

Todo el estado visual está controlado por `_enfocado` / `_pulsado` en
`scripts/boton_menu.gd`.

## Cómo se adapta a cada pantalla

- `project.godot`: `stretch/mode = canvas_items`, `stretch/aspect = expand` →
  el lienzo ocupa **toda** la pantalla sin deformar nada.
- El fondo usa `KEEP_ASPECT_COVERED` + filtro **nearest** (se ve nítido, sin
  estirarse ni barras negras).
- El bloque del menú se escala al **40 % del lado corto** de la pantalla
  (múltiplos de 0.5 para conservar los píxeles) y se ancla a
  **5 % del borde izquierdo / 7 % del inferior**.
- Orientación: `sensor_landscape` (apaisada, permite ambos sentidos).

## Regenerar los previews

```bash
cd menu_inicio_godot
flatpak run org.godotengine.Godot --path . res://preview/captura.tscn
```

Salida en `preview/salidas/`:

- `menu_1280x720.png`, `menu_1920x1080.png`, `menu_2400x1080.png`,
  `menu_2560x1600.png`, `menu_1080x1920.png` — el menú completo en distintos
  dispositivos.
- `estado_1_normal.png`, `estado_2_marcado.png`, `estado_3_presionado.png` y
  `estados_boton.png` — los tres estados del botón.

Prueba de interacción:

```bash
flatpak run org.godotengine.Godot --path . res://preview/prueba_interaccion.tscn
```

## Exportar a Android

`export_presets.cfg` ya trae el preset **Android** (con gradle habilitado).
En el editor: **Proyecto > Exportar > Android**. Necesitas el SDK de Android,
JDK y las plantillas de exportación de Godot 4.7 (Instalar plantillas de
exportación).

- Paquete por defecto: `com.example.salvandolahistoria` — cámbialo en el
  preset antes de publicar.
- El APK de prueba queda en `android/build/build/outputs/apk/standard/debug/`.

## De dónde salieron los assets

Los `.pxo` de la carpeta `../pxo` traen las capas separadas (`texto`,
`vinetas`); se extrajeron a PNG en `assets/` tal cual están, sin recomponer
ni redibujar nada:

- `texto_<boton>_amarillo.png` / `_gris.png` — el texto solo.
- `vineta_<amarilla|gris>_<izq|der>.png` — las flechas, partidas en dos para
  poder animarlas por separado.
- `titulo.png` = capas `texto` + `adorno` compuestas.
- `fondo.png` — el fondo panorámico 917×512.
