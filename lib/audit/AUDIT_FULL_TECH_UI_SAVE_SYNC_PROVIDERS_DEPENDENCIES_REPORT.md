# Auditoria tecnica integral de UI, providers, persistencia y dependencias

Fecha de corte: 2026-05-31

Alcance: revision estatica del repositorio Flutter/Dart para responder si la programacion actual es correcta, si las tecnicas Flutter/Dart son modernas, si Riverpod esta bien usado, si el guardado local/remoto es confiable, si el flujo es realmente offline-first, y que librerias/widgets conviene investigar para que nutricion y entrenamiento se vean mas profesionales.

Este informe no modifica codigo. Resume evidencia observada en el arbol actual y prioriza riesgos funcionales antes que estetica.

## Resumen ejecutivo

La base tecnica general es razonable: Flutter 3.9.2, Material 3 activo, Riverpod como capa principal de estado, SQLite con WAL y bloqueo por cliente, y Firestore como backend remoto. Sin embargo, la arquitectura de sincronizacion no es todavia offline-first robusta. Hay guardado local primero para clientes y algunos artefactos clinicos, pero la cola de sync existe solo como tabla y el flujo real no la llena. Eso deja varios caminos solo locales o solo remotos, y abre huecos de consistencia entre tabs, entre dispositivos y entre UI y persistencia.

La conclusion principal es esta: el sistema funciona, pero no garantiza aun que lo que el usuario ve como "guardado" haya quedado realmente sincronizado de forma confiable en todos los dominios. El mayor riesgo no es una UI obsoleta; es una mezcla de estado local, snapshots derivados, pushes diferidos y rutas remotas que no comparten el mismo contrato de durabilidad.

## Veredicto corto

| Pregunta | Respuesta |
|---|---|
| El guardado local es seguro | Parcialmente, solo para dominios apoyados por SQLite y `ClientRepository` |
| El guardado online es seguro | Parcialmente, Firestore usa merge y repositorios tipados, pero hay rutas fire-and-forget y una desactivacion temporal del sync remoto ante `permission-denied` |
| La app es offline-first de extremo a extremo | No |
| Las ediciones offline siempre se suben despues | No hay garantia total |
| Una tab puede pisar cambios de otra tab | Si, en escenarios de rehidratacion incompleta o snapshots desfasados |
| El usuario puede creer que ya se sincronizo cuando solo se guardo localmente | Si |

## Hallazgos priorizados

### P0

1. La cola de sync existe, pero no se usa como outbox real. `SyncQueueHelper.enqueue()` no aparece conectada a ningun flujo de guardado; por tanto, el sistema no tiene una garantia durable de reintento por evento.
2. Hay dominios que siguen siendo online-first puros, especialmente citas y transacciones. Si Firestore no responde, no hay almacenamiento local equivalente ni cola persistente para reintento.
3. Parte del guardado clinico es fire-and-forget. Eso es aceptable solo si el producto acepta eventual consistency visible; no es suficiente si se promete durabilidad fuerte o continuidad offline completa.

### P1

1. Varias tabs de historia clinica rehidratan su borrador solo cuando cambia `client.id`. Si otra tab actualiza el mismo cliente sin cambiar el ID, una tab puede seguir trabajando con un snapshot viejo.
2. El provider de preferencias de cliente para entrenamiento esta incompleto y hoy retorna un valor vacio o `null` en la practica. Eso limita la personalizacion real del motor.
3. Existe una definicion de tema adicional que no parece utilizada. No rompe nada, pero ensucia la historia del diseno y sugiere duplicidad de intencion.

### P2

1. Hay codigo legado o no prioritario que conviene revisar o eliminar si no se usa: `provider`, `firebase_storage`, `firebase_analytics`, `shared_preferences`, `form_builder_validators`, `mockito`, `fake_async`, y la ruta legacy de datasource remoto de clientes.
2. El kit visual es funcional, pero varias pantallas parecen densas y muy similares entre si. Para nutricion y entrenamiento se puede elevar mucho la percepcion con componentes mas editoriales o mas de producto premium.

## Validacion de los cuatro hallazgos previos de guardado clinico

| Hallazgo previo | Estado actual | Evidencia | Impacto |
|---|---|---|---|
| Snapshots locales desfasados | Confirmado | Las tabs de historia rehidratan solo si cambia `client.id`, y antropometria ya fue corregida para leer el cliente activo real | Puede haber perdida aparente de cambios o sobrescritura silenciosa entre tabs |
| Push remoto diferido no observable | Confirmado | `ClientRepository.saveClient()` difiere el push con debounce y el indicador de guardado no representa el exito remoto real | El usuario puede ver "guardado" sin garantia de sincronizacion |
| Push granular fire-and-forget | Confirmado | Antropometria y otros records clinicos empujan al backend sin bloquear la UI ni esperar confirmacion fuerte | Mejor UX, pero consistencia eventual y fallos silenciosos |
| Lock por cliente | Confirmado | Existe serializacion por cliente en `ClientRepository` y `updateLock`, lo que reduce carreras | Ayuda mucho, pero no cubre todos los dominios ni evita snapshots viejos |

## Estado tecnico por capa

### Flutter y Dart

La app ya usa Material 3, `ThemeData`, `ColorScheme`, `ConsumerWidget`, `ConsumerStatefulWidget`, `context.mounted` y las protecciones de analisis para `use_build_context_synchronously`. Eso es una base moderna y sana. No veo una programacion anticuada por defecto, pero si una mezcla entre patrones actuales y legado puntual.

Se observo un unico warning de analizador en la corrida revisada: un import no usado en antropometria. Eso es menor, pero confirma que hay limpieza tecnica pendiente.

### Riverpod y estado

Riverpod es la capa viva del sistema. En la practica no encontre uso real de `provider` en el arbol `lib/`, asi que el paquete `provider` parece decorativo o residual. Eso es bueno para simplificar, pero conviene confirmar que no quede ruido en `pubspec.yaml` ni en la documentacion.

Hay uso de `NotifierProvider`, `AsyncNotifierProvider`, `FutureProvider` y un puente legacy con `ChangeNotifierProvider.autoDispose` en progresion muscular. Esa mezcla es aceptable si existe una razon de migracion, pero no es una arquitectura completamente homogénea.

El punto mas debil de estado no es Riverpod en si, sino algunos providers calculados o de efecto que hoy no aportan una verdad persistente real. En particular, el provider de preferencias del cliente devuelve un valor vacio o `null` y no consolida preferencias reales del motor.

### Persistencia local

SQLite esta bien configurado: WAL activo, `busy_timeout`, foreign keys, tablas indexadas y una tabla de estado de la app. Eso es una base correcta para local-first.

Lo que falta no es SQLite; falta disciplina de outbox. Tener `sync_queue` sin encolado real significa que la intencion offline-first esta a medias.

### Persistencia remota

Firestore esta bien modelado para clientes y records clinicos: merge en escrituras, subcolecciones por dominio y dominio de fecha, y payloads filtrados para no sobreescribir campos pesados innecesarios. Eso esta bien resuelto.

El problema es la heterogeneidad: algunos dominios van por `ClientRepository`, otros por repositorios granulares, otros por Firestore directo. Si no existe un contrato comun de confirmacion, reintento y reconciliacion, el sistema termina siendo "local-first donde se pudo" y "online-first donde no hubo tiempo de montar la capa local".

## Matriz de dependencias relevantes

### Dependencias que si parecen activas

| Paquete | Uso observado | Estado |
|---|---|---|
| `flutter_riverpod` | Providers, notifiers y consumers en toda la app | Activo |
| `firebase_core` | Inicializacion Firebase | Activo |
| `cloud_firestore` | Lectura/escritura remota de clientes, records, agenda y transacciones | Activo |
| `sqflite` | Persistencia local | Activo |
| `sqflite_common_ffi` | Compatibilidad local/test | Activo |
| `path_provider` | Soporte de almacenamiento local | Activo o muy probable |
| `path` | Rutas locales | Activo o muy probable |
| `intl` | Formato de fechas, labels y calculos | Activo |
| `fl_chart` | Graficas y paneles | Activo |
| `pdf` | Generacion de reportes/documentos | Activo |
| `printing` | Impresion/exportacion | Activo |
| `firebase_auth` | Autenticacion | Activo |
| `freezed` / `json_serializable` | Modelos inmutables y serializacion | Activo |
| `synchronized` | Locks de actualizacion | Activo |

### Dependencias que conviene revisar por posible ruido

| Paquete | Hallazgo | Recomendacion |
|---|---|---|
| `provider` | No encontre imports directos en `lib/` | Investigar si puede retirarse |
| `riverpod` | No encontre uso directo en `lib/`; la capa viva parece ser `flutter_riverpod` | Investigar si es solo dependencia transitive o si se necesita |
| `riverpod_annotation` | No encontre `@riverpod` en `lib/` | Revisar si esta sobrado o reservado para futura migracion |
| `firebase_storage` | No encontre uso directo en `lib/` o tests revisados | Revisar |
| `firebase_analytics` | No encontre uso directo en `lib/` o tests revisados | Revisar |
| `shared_preferences` | No encontre uso directo en `lib/` o tests revisados | Revisar |
| `form_builder_validators` | No encontre uso directo en la busqueda revisada | Revisar |
| `mockito` | No encontre uso directo en la busqueda revisada | Revisar |
| `fake_async` | No encontre uso directo en la busqueda revisada | Revisar |

## Guardado local y remoto por dominio

### Clientes y ficha clinica

`ClientRepository` guarda local primero y luego intenta push remoto diferido. Hay serializacion por cliente, lo cual es positivo. La parte delicada es que el exito local y el exito remoto no tienen el mismo nivel de observabilidad.

Las tabs de historia clinica usan borradores locales y vuelven a hidratarse cuando cambia el ID del cliente. Eso reduce ruido de rebuild, pero no captura cambios concurrentes sobre el mismo cliente hechos desde otra pestaña o desde otro flujo.

### Antropometria

Este era el bug funcional original. La logica ya fue corregida para leer el cliente activo real y no depender de un snapshot local viejo. Esa correccion ataca la causa raiz correcta: el problema era de estado, no de calculo antropometrico en si.

### Nutricion

Nutricion usa planes y snapshots dentro de `nutrition.extra` y `nutritionPlansV3` con `updateActiveClient`. Eso es coherente con el resto de la ficha, pero sigue dependiendo del contrato de actualizacion del cliente activo. Si el cliente activo se desincroniza, la derivacion de planes tambien se desincroniza.

### Entrenamiento

El motor de entrenamiento es el area mas compleja. Hay varias escrituras directas con `saveClient`, persistencia de evaluaciones, decisiones semanales y snapshots. El resultado es potente, pero tambien fragil: muchas piezas dependen de una consistencia derivada que no esta respaldada por una outbox comun.

### Agenda y transacciones

Aqui esta el mayor hueco de offline-first. Citas y transacciones usan Firestore directo y no tienen tabla local equivalente ni cola persistente observada. Si el usuario trabaja sin red, no existe la misma garantia de continuidad que en el flujo de clientes.

## Riesgos de persistencia

1. El sistema puede mostrar una sensacion de exito local aunque el remote push siga pendiente o haya sido diferido.
2. La cola de sync no protege lo que no se encola. Mientras no exista un outbox conectado a los saves reales, el reintento no es estructural.
3. Los dominios remotos puros rompen el ideal offline-first por diseno, no por bug.
4. Las tabs clinicas que rehidratan por ID pueden quedarse con un borrador viejo si el mismo cliente se modifica desde otro punto del flujo.

## UI y modernidad visual

### Lo que esta bien

- Material 3 esta activado y aplicado desde `app.dart`.
- Hay tema centralizado en `utils/theme.dart`.
- Hay indicador visual de guardado integrado en el shell principal.
- La app ya usa patrones de Flutter modernos suficientes para sostener una base profesional.

### Lo que se puede mejorar

- Varias pantallas de nutricion y entrenamiento siguen el patron clasico de formulario/lista/tarjeta, que funciona pero no destaca.
- Hay mucho peso informativo y poca jerarquia editorial en algunas vistas de trabajo.
- El tema secundario `appTheme` parece duplicado y no usado; eso confunde el mantenimiento del lenguaje visual.

### Librerias y widgets que merece la pena investigar

#### Nutricion

- `fl_chart` ya esta en la base y conviene explotarlo mejor con graficas de progreso, adherencia, macros y tendencia.
- `syncfusion_flutter_charts` si se busca una capa visual mas rica y comercial para progresos nutrimentales.
- `flutter_slidable` para acciones rapidas sobre comidas, planes o registros.
- `responsive_framework` o `flutter_screenutil` para jerarquia consistente en pantallas grandes y pequenas.
- `animated_flip_counter` o widgets de contador animado para metrica clave.
- `shimmer` para estados de carga mas finos que un placeholder plano.

#### Entrenamiento

- `fl_chart` para dashboards de volumen, RIR, fallos y evolucion por semana.
- `flutter_staggered_animations` o animaciones sutiles para progreso y tarjetas de decision.
- `sliver_tools` o layouts sliver si la pantalla necesita mas densidad controlada.
- `intl` + chips de estado + timeline visual para historiales de sesion.
- `syncfusion_flutter_gauges` o un widget equivalente si se quiere mostrar carga, fatiga o cumplimiento con mas impacto visual.

#### Agenda y operaciones

- `table_calendar` o calendario custom si la agenda necesita ser mas tactil.
- `data_table_2` si se requiere una tabla administrativa mas limpia.
- `modal_bottom_sheet` o paneles modales mas fluidos para acciones rapidas.

### Criterio de seleccion

No conviene meter librerias solo por estetica. La seleccion deberia responder a dos objetivos: reducir densidad visual en pantallas complejas y hacer evidente el estado del plan, la adherencia y la accion siguiente.

## Plan recomendado en 3 cambios minimos

1. Conectar un outbox real a los saves clinicos importantes. `sync_queue` debe recibir eventos desde los writes que importan, no quedarse como tabla decorativa.
2. Hacer que las tabs clinicas rehidratem por version o timestamp del cliente, no solo por `client.id`. Eso reduce los conflictos entre tabs sobre el mismo paciente.
3. Unificar la observabilidad de guardado y sync remoto. Guardado local, guardado remoto en cola y resultado de sincronizacion no deberian verse como el mismo estado.

## Recomendacion por fases

### Fase 1

Hacer confiable el contrato de escritura clinica: local primero, outbox persistente, reintento y reconciliacion por evento.

### Fase 2

Homogeneizar providers y fuentes de verdad. Evitar providers efecto que devuelven placeholders permanentes y reducir puentes legacy donde ya hay equivalentes modernos.

### Fase 3

Elevar la UI a un lenguaje mas de producto: mejores jerarquias, estados vacios, micro-interacciones utiles y componentes especificos para nutricion y entrenamiento.

## Conclusiones finales

La app no esta mal construida. De hecho, ya tiene varias piezas correctas: Riverpod, Material 3, SQLite con WAL, Firestore con merge, locks por cliente y un shell con indicador de estado. El problema es que la confiabilidad global todavia no esta cerrada. Hay rutas que guardan local, rutas que guardan remoto, rutas fire-and-forget y una cola de sync que no actua como outbox real.

Si el objetivo es una experiencia clinica confiable y offline-first real, el siguiente salto no es reescribir todo. El siguiente salto es formalizar el contrato de persistencia, eliminar el desfase entre snapshots y cliente activo, y convertir la sincronizacion en una parte observable del producto.
