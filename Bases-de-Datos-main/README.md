# Operación Marea Alta

Reto de diseño de bases de datos: gestión de ayudas humanitarias tras el sismo del 10 de agosto de 2026 en Buenaventura.

## Equipo

**Nombre del equipo:** Los Maravillas

**Integrantes:**

1. Laura Valentina Rivas Caicedo
2. Ana Sofia Mena Clarete
3. Rosa Maria Perea Micolta
4. Harvey Hernando Valdelamar Celorio

## Qué hay en este repositorio

| Archivo | Qué contiene |
|---|---|
| `01_boceto_manual.pdf` | Fotos del modelo conceptual que hicimos a mano en clase (entidades, relaciones, cardinalidades y atributos). |
| `02_modelo_conceptual.pdf` | Diagrama entidad-relación final. |
| `03_modelo_relacional.pdf` | Tablas, claves primarias y claves foráneas. |

## Cómo pensamos el problema

Antes de dibujar nada nos sentamos a sacar los hechos del enunciado: quién reporta, qué se necesita, quién dona, qué se entrega y quién lo registra. La idea central es poder seguir el camino completo de una ayuda: de qué donante vino, cuánto queda y a qué hogar llegó.

Usamos la notación de Chen: rectángulos para las entidades (con sus atributos adentro, como una tabla) y rombos para las relaciones. Una regla que nos pusimos: las relaciones no llevan atributos. Cuando una relación tenía datos propios, la convertimos en entidad y la conectamos con dos relaciones normales. Todos los nombres de entidades y tablas van en singular, y las relaciones se leen en plural (un hogar tiene muchos reportes).

## Decisiones principales

**Hogar y ubicación.** Cada hogar tiene una persona de contacto (nombre y teléfono) y el número de personas que viven ahí. La ubicación es una entidad aparte porque muchos hogares comparten el mismo barrio o vereda (1 ubicación, N hogares). Guarda si la zona es urbana o rural, la división (barrio, corregimiento o vereda), el nombre y una referencia para los sitios rurales donde no hay dirección.

**Condiciones del hogar.** Niños pequeños, personas mayores, gestantes o movilidad reducida cambian la prioridad, así que van en la entidad Condición. Un hogar puede tener varias condiciones y una condición aplica a varios hogares (N a M). Como esa relación no tiene datos propios, queda como un solo rombo (Tiene) y en el modelo relacional se vuelve una tabla intermedia.

**Necesidades y reportes.** Un hogar puede reportar varias necesidades y una necesidad la reportan muchos hogares. Como el reporte tiene datos propios (urgencia, cantidad estimada, estado, observación y fecha), lo hicimos entidad: Hogar hace Reporte y Reporte es sobre una Necesidad. Además, la entidad Seguimiento guarda cada cambio de estado del reporte, para no perder cómo fue evolucionando. El estado del Reporte es el actual y el de Seguimiento es el historial.

**Donantes y donaciones.** El tipo de donante (persona, organización comunitaria, empresa o entidad pública) es un atributo del donante, no una entidad por cada tipo. Una donación puede traer varios tipos de ayuda, por eso entre Donación y Tipo de ayuda va la entidad Detalle de donación, que guarda la cantidad recibida.

**Tipo de ayuda y unidades.** Cada tipo de ayuda tiene una sola unidad de medida estándar. La conversión (por ejemplo, arrobas a libras) se hace antes de registrar.

**Entregas.** Una entrega va a un solo hogar y se hace en un solo punto de atención. Como puede llevar varios tipos de ayuda, usamos Detalle de entrega para la cantidad entregada. Guardamos por separado la fecha de entrega y la fecha de registro, y quién dejó la constancia. Regla: la fecha de registro no puede ser anterior a la de entrega, pero sí puede ser el mismo día (en la tabla se valida con `>=`).

**Usuarios y funciones.** Un usuario puede tener varias funciones y una función puede estar en varios usuarios. Como queremos guardar desde cuándo y hasta cuándo, además del estado, lo resolvimos con la entidad Usuario por función. Así se puede quitar una función sin borrar a la persona.

**Equipos y jornadas.** Para poder trabajar en varios barrios al mismo tiempo agregamos la entidad Equipo. Un usuario puede integrar varios equipos y un equipo tiene varios usuarios. Cada vez que un equipo sale a trabajar a un barrio se registra una Jornada (con su fecha y estado), y la jornada cubre una ubicación. Así dos equipos pueden tener jornadas el mismo día en barrios distintos. Una entrega puede estar ligada a una jornada, pero no es obligatorio, porque también hay entregas en puntos de atención fijos.

**Inventario.** No lo guardamos como tabla ni como campo. Lo disponible es lo recibido menos lo entregado, y guardarlo aparte puede quedar desactualizado. Se calcula con una consulta. Para que no quede en negativo, la entrega se confirma dentro de una transacción que revisa las existencias; si no alcanza, se rechaza completa.

## Ideas del grupo que dejamos por fuera

| Idea | Por qué la dejamos fuera |
|---|---|
| Persona y Transacción | Ya las habíamos tachado en el borrador. Persona quedó repartida entre hogar, donante y usuario; Transacción era demasiado general. |
| Destinatario como entidad | Sus datos (fecha, hora, tipo de entrega) ya van en Entrega, y el destinatario es el hogar. Habría quedado repetido. |
| Misión humanitaria | Es logística de transporte (salida, destino, despacho) y el alcance llega hasta la entrega en el punto de atención. Lo que sí tomamos de la idea es la Jornada, que solo dice qué equipo trabajó en qué barrio y cuándo. |
| Inventario como tabla | Es un dato derivado, ver arriba. |
| Datos de cada integrante del hogar | El enunciado pide una persona de contacto y el número de integrantes, no una lista de todos. También evita guardar datos personales de más. |
| Tipo de afectación | Todos los hogares están afectados por el mismo sismo, y lo que de verdad cambia la atención son las condiciones. |
| Registro público | La información se consolida de forma centralizada, y publicar datos de familias damnificadas sería un problema de privacidad. |
| Encargados y Pendientes y registros (del flujo) | Los encargados son usuarios con una función. Los pendientes se sacan con una consulta (hogares con reportes sin atender), no necesitan tabla. |
| Glosario | Nos sirvió para entender el problema, pero la entrega pide solo los archivos de esta lista. |

## Cosas que agregamos al diseño

- Entidad Condición y su relación con Hogar, para registrar la prioridad.
- Nombre de la persona de contacto en el hogar.
- Cantidad estimada en el reporte, y la entidad Seguimiento para guardar los cambios de estado y no perder la evolución de cada necesidad.
- Estructura de la ubicación (zona, división y referencia).
- Detalle de donación, Detalle de entrega, Reporte y Usuario por función como entidades, para que ninguna relación tenga atributos propios.
- Entidades Equipo y Jornada, para coordinar equipos que trabajan al mismo tiempo en barrios distintos.
- Usuario que registra la entrega, y estado de la entrega (pendiente o confirmada).
- Entidad pública como tipo de donante.
- Reglas: cantidades mayores que cero; fecha de registro mayor o igual a la fecha de entrega; y, para posibles hogares duplicados, una alerta cuando coincidan teléfono de contacto y ubicación (no se exige nombre único).
