# Interfaz de maleta de viaje (inventario espacial)

Este rediseño **sí forma parte del proyecto Godot**. Sustituye la apariencia del inventario por una maleta de cuero en pixel art; no cambia el autoload `Inventory` ni la lógica de recoger, colocar, mover, apilar o seleccionar objetos.

## Uso

- Abre el proyecto `videojuego-historico/project.godot` en Godot 4.7 (o la versión correspondiente al proyecto).
- Ejecuta el juego con F5, entra en una partida y pulsa **I** o el botón táctil **Inv**: se despliega una maleta con animación de apertura. Para cerrar: **I**, **Esc** o botón **CERRAR**.
- Clic/toque sobre un objeto para seleccionarlo. Arrastra para moverlo. Usa **R** o **ROTAR** para girar los objetos que lo permitan. Teclas **1–4** seleccionan entradas del inventario.
- Para probar el rediseño con elementos de ejemplo sin jugar todo el nivel: abre `res://inventario/InventoryDemo.tscn` y ejecuta la escena actual con F6.

## Cómo funciona la transición

`inventario/UI/inventory_ui.gd` crea tres capas artísticas independientes y la cuadrícula interactiva: `TrayArt` (cuerpo), `OpenLid` (tapa interior decorada), `Contents` (objetos, información, botones), `ClosedCover` (tapa de cuero exterior). Un `Tween` de Godot repliega `ClosedCover`, despliega `OpenLid` y desvanece `Contents`. Al cerrar se invierte la secuencia. Las dimensiones del conjunto se escalan para caber dentro del viewport, conservando la proporción pixel art. El estado de la mochila y el movimiento del jugador siguen siendo inmediatos aunque la animación aún continúe.

## Archivos relevantes

- `inventario/art/suitcase_tray.png`, `suitcase_open_lid.png`, `suitcase_closed_cover.png`: ilustraciones pixel art, hechas específicamente para el tamaño y distribución de la maleta.
- `inventario/art/icons/*.png`: iconos transparentes pixel art para mapa, bolsa de monedas, pistola, escopeta, botiquín, radio y municiones.
- `inventario/UI/inventory_ui.gd`: marco, etiquetas, botones, escalado y animación de apertura/cierre.
- `inventario/data/inventory_grid.gd`: dibuja las casillas con paleta oscura y bordes de bronce y usa las texturas de los objetos.
- `resources/items/{mapa,bolsa_monedas}.tres` y `inventario/items/*.tres`: ahora referencian iconos pixel art.
- `inventario/InventoryDemo.tscn` y `inventario/inventory_demo.gd`: escena para visualizar el resultado y probar el inventario.

## Pruebas

En la carpeta `videojuego-historico/`:

```bash
godot --headless --path . --import
godot --headless --path . res://tests/test_spatial_inventory.tscn
godot --headless --path . res://tests/test_suitcase_ui.tscn
```

> Este entorno no dispone del ejecutable de Godot, así que las pruebas incluidas no se han ejecutado aquí. Hay que importar los assets y ejecutar los tests en la computadora de desarrollo antes de fusionar a `main`.

## Para ajustar el efecto

En `inventario/UI/inventory_ui.gd`, cambia las duraciones (segundos) dentro de `_animate_open()` y `_animate_close()`. Los colores y el diseño de las casillas se encuentran en `inventario/data/inventory_grid.gd`. Los PNG se pueden reemplazar por otras ilustraciones conservando su tamaño: bandeja 820×560, tapa abierta 820×190, tapa cerrada 820×340.

El inventario guarda su estado entre escenas mediante `Inventory` (autoload), como en la integración previa. No guarda automáticamente una partida entre sesiones.
