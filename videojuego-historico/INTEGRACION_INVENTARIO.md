# Integración del inventario espacial

El inventario de `inventario/data/inventory_grid.gd` ahora se utiliza en las escenas reales del videojuego, sin sustituir la API que consumen los sistemas del equipo.

## Cambios

- `autoload/inventory.gd`: estado persistente del inventario, cuadrícula de 8 × 6; posiciones, colisiones, rotación, selección, apilamiento y capacidad. `add_item`, `remove_item`, `has_item`, `count`, `select`, `get_selected` se mantienen.
- `scripts/items/item.gd`: `grid_size`, `can_rotate`, `grid_color`, conservando los atributos de juego.
- `inventario/data/inventory_grid.gd`: dibuja el inventario real y permite mover, rotar y seleccionar objetos. Controles de ratón y táctiles.
- `inventario/UI/inventory_ui.gd`: ventana de mochila integrada. Ambas escenas UI apuntan a este script, porque faltaba `scripts/ui/inventory_ui.gd` en el ZIP original.
- `scripts/ui/pause_menu.gd`: ESC cierra primero el inventario.
- `resources/items/`: bolsa y mapa tienen tamaños diferentes.
- `inventario/InventoryDemo.tscn`: conserva una demostración con cuatro objetos, pero ahora utiliza el backend real.

## Uso

- `I` o botón táctil `Inv`: mostrar/ocultar la mochila.
- Clic o toque: seleccionar el objeto (el evento 1 usa el seleccionado).
- Arrastrar con ratón o dedo: mover dentro de la cuadrícula.
- `R` o botón **Rotar**: girar el objeto seleccionado; durante el arrastre, `R` gira la vista previa.
- `1`–`4`: seleccionar por índice los primeros cuatro objetos.
- `Esc`: cierra la mochila antes de abrir el menú de pausa.

## Pruebas

Desde `videojuego-historico/`:

```bash
godot --headless --path . --import
godot --headless --path . res://tests/test_spatial_inventory.tscn
godot --headless --path . res://tests/test_phase5.tscn
```

Abrir el proyecto en Godot 4.7+ y ejecutar `F5` (menú → jugar) y `F6` sobre `inventario/InventoryDemo.tscn` para la muestra aislada.

## Consideraciones

- El sistema evita recoger una cantidad si no cabe completamente; el Pickup permanece en el mundo y muestra un aviso de espacio insuficiente.
- Se preservan las escenas existentes de Overworld, Evento 1 y el sistema de selección para la condición de victoria.
- `inventario/UI/item_ui.gd`, `inventario/data/inventory_item.gd` e `inventario/data/item_data.gd` siguen como borradores del prototipo original, pero no son utilizados por la integración; se pueden limpiar después.
- No se implementa guardado permanente en disco entre sesiones; la persistencia es entre escenas (el autoload se reinicia al comenzar una partida).
