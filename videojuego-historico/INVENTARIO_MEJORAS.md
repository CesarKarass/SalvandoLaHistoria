# Mejoras del inventario en maleta

## Qué se modificó

1. Se eliminó el cuadro central de la textura `inventario/art/suitcase_tray.png` y se redibujaron **dos paneles**.
2. El panel superior muestra nombre, descripción desplazable y tamaño/cantidad del objeto seleccionado.
3. El panel inferior muestra capacidad utilizada, barra de ocupación, casillas libres, cantidad de objetos y botones **GIRAR**, **CERRAR** y **?**.
4. El antiguo texto permanente de instrucciones ahora es una **ventana flotante** que se presenta al completar la primera apertura de la maleta. Al pulsar **ENTENDIDO**, se marca como leído en `user://inventario_ayuda.cfg`, por lo que no se muestra automáticamente en las siguientes aperturas, incluso al reiniciar el juego. El botón **?** permite abrirla a voluntad. Si se cierra sin aceptarla, reaparecerá la siguiente vez.
5. Al girar, se prueba la ubicación solicitada; si no cabe, se busca la posición libre más cercana sin superponer objetos. Si no existe ninguna, se conserva el objeto tal como estaba y la maleta vibra con un aviso temporal.
6. Para rotar mientras arrastras un objeto, la recolocación también se intenta y, si se usa un lugar alternativo, termina el arrastre para evitar previsualizaciones incorrectas.

## Configuración

- Modifica **Animation Speed** en el inspector de `InventoryUI` para controlar el tiempo de apertura/cierre.
- `show_first_open_tutorial` permite desactivar la apertura automática de la ayuda durante pruebas.
- El archivo `user://inventario_ayuda.cfg` se crea automáticamente al pulsar **ENTENDIDO**. Para volver a probar el comportamiento de primera apertura, elimina ese archivo de los datos de usuario de Godot, o utiliza **?** para releerlo sin borrar datos.

## Pruebas

Desde la carpeta `videojuego-historico/`:

```bash
godot --headless --path . --import
godot --headless --path . res://tests/test_spatial_inventory.tscn
godot --headless --path . res://tests/test_suitcase_ui.tscn
godot --headless --path . res://tests/test_inventory_improvements.tscn
```

**Importante:** no reemplaces manualmente tu proyecto completo si el equipo ha modificado archivos después del ZIP original. Trabaja en una rama y aplica el parche con `git apply --check` primero.
