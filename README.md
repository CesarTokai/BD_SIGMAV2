# SIGMAV2 - Sistema de Gestion de Inventario y Almacenes

## Descripcion General

SIGMAV2 es un sistema de gestion de inventario multialmacen que permite administrar productos, existencias, etiquetas de conteo fisico y periodos de inventario. La base de datos utilizada es **sigmav2_2** sobre MySQL 8.0.

---

## Tecnologias

- Motor de base de datos: MySQL 8.0
- Motor de tablas: InnoDB
- Juego de caracteres: utf8mb4 (utf8mb4_0900_ai_ci)

---

## Estructura de la Base de Datos

### Tablas Principales

#### products
Catalogo de productos del sistema.

| Columna     | Tipo           | Descripcion                     |
|-------------|----------------|---------------------------------|
| id_product  | bigint (PK, AI)| Identificador unico del producto|
| cve_art     | varchar(255)   | Clave del articulo              |
| descr       | varchar(255)   | Descripcion del producto        |
| lin_prod    | varchar(255)   | Linea de producto               |
| uni_med     | varchar(255)   | Unidad de medida                |
| status      | varchar(255)   | Estado del producto             |
| created_at  | datetime(6)    | Fecha de creacion               |

---

#### warehouse
Catalogo de almacenes registrados en el sistema.

| Columna         | Tipo           | Descripcion                          |
|-----------------|----------------|--------------------------------------|
| id_warehouse    | bigint (PK, AI)| Identificador unico del almacen      |
| name_warehouse  | varchar(255)   | Nombre del almacen (unico)           |
| warehouse_key   | varchar(50)    | Clave del almacen (unico)            |
| observations    | varchar(255)   | Observaciones                        |
| created_at      | datetime(6)    | Fecha de creacion                    |
| created_by      | bigint         | Usuario que lo creo                  |
| updated_at      | datetime(6)    | Fecha de actualizacion               |
| updated_by      | bigint         | Usuario que lo actualizo             |
| deleted_at      | datetime(6)    | Fecha de eliminacion logica          |
| deleted_by      | bigint         | Usuario que lo elimino               |

Indices adicionales: uk_warehouse_name, uk_warehouse_key, idx_warehouse_key, idx_warehouse_deleted

---

#### period
Periodos de inventario.

| Columna    | Tipo                                      | Descripcion              |
|------------|-------------------------------------------|--------------------------|
| id_period  | bigint (PK, AI)                           | Identificador del periodo|
| period     | date (unico)                              | Fecha del periodo        |
| state      | enum('CLOSED','DRAFT','LOCKED','OPEN')    | Estado del periodo       |
| comments   | varchar(255)                              | Comentarios              |

---

#### inventory_stock
Stock de inventario por producto, almacen y periodo.

| Columna      | Tipo              | Descripcion                         |
|--------------|-------------------|-------------------------------------|
| id_stock     | bigint (PK, AI)   | Identificador del registro de stock |
| id_product   | bigint (FK)       | Referencia a products               |
| id_warehouse | bigint (FK)       | Referencia a warehouse              |
| id_period    | bigint            | Periodo de inventario               |
| exist_qty    | decimal(10,2)     | Cantidad en existencia              |
| status       | enum('A','B')     | Estado del registro                 |
| created_at   | datetime(6)       | Fecha de creacion                   |
| updated_at   | datetime(6)       | Fecha de actualizacion              |

Restriccion unica: (id_product, id_warehouse, id_period)
Llaves foraneas: id_product -> products.id_product, id_warehouse -> warehouse.id_warehouse

---

#### inventory_snapshot
Instantanea del inventario para un producto, almacen y periodo.

| Columna      | Tipo           | Descripcion                    |
|--------------|----------------|--------------------------------|
| id           | bigint (PK, AI)| Identificador                  |
| product_id   | bigint         | Referencia a producto          |
| warehouse_id | bigint         | Referencia a almacen           |
| period_id    | bigint         | Referencia a periodo           |
| exist_qty    | decimal(38,2)  | Cantidad en existencia         |
| status       | varchar(255)   | Estado                         |
| created_at   | datetime(6)    | Fecha de creacion              |

---

#### inventory_import_jobs
Registro de trabajos de importacion de inventario.

| Columna        | Tipo           | Descripcion                          |
|----------------|----------------|--------------------------------------|
| id             | bigint (PK, AI)| Identificador del trabajo            |
| file_name      | varchar(255)   | Nombre del archivo importado         |
| id_warehouse   | bigint         | Almacen relacionado                  |
| id_period      | bigint         | Periodo relacionado                  |
| status         | varchar(255)   | Estado del trabajo                   |
| total_rows     | int            | Total de filas procesadas            |
| inserted_rows  | int            | Filas insertadas                     |
| updated_rows   | int            | Filas actualizadas                   |
| skipped_rows   | int            | Filas omitidas                       |
| total_records  | int            | Total de registros                   |
| errors_json    | longtext       | Errores en formato JSON              |
| checksum       | varchar(255)   | Suma de verificacion del archivo     |
| log_file_path  | varchar(255)   | Ruta del archivo de log              |
| username       | varchar(255)   | Usuario que realizo la importacion   |
| created_by     | varchar(255)   | Creado por                           |
| started_at     | datetime(6)    | Inicio del proceso                   |
| finished_at    | datetime(6)    | Fin del proceso                      |

---

#### multiwarehouse_existences
Existencias multialmacen (vista desnormalizada).

| Columna        | Tipo           | Descripcion                       |
|----------------|----------------|-----------------------------------|
| id             | bigint (PK, AI)| Identificador                     |
| product_code   | varchar(255)   | Codigo del producto               |
| product_name   | varchar(255)   | Nombre del producto               |
| warehouse_id   | bigint         | ID del almacen                    |
| warehouse_key  | varchar(255)   | Clave del almacen                 |
| warehouse_name | varchar(255)   | Nombre del almacen                |
| period_id      | bigint         | Periodo                           |
| stock          | decimal(38,2)  | Existencia                        |
| status         | varchar(1)     | Estado                            |

Indice: idx_warehouse_product (warehouse_id, product_code)

---

#### multiwarehouse_import_log
Log de importaciones multialmacen.

| Columna     | Tipo           | Descripcion                    |
|-------------|----------------|--------------------------------|
| id          | bigint (PK, AI)| Identificador                  |
| file_name   | varchar(255)   | Nombre del archivo             |
| file_hash   | varchar(64)    | Hash del archivo               |
| import_date | datetime(6)    | Fecha de importacion           |
| period      | varchar(255)   | Periodo                        |
| status      | varchar(255)   | Estado                         |
| stage       | varchar(20)    | Etapa del proceso              |
| message     | varchar(1000)  | Mensaje de resultado           |

---

### Tablas de Etiquetas (Conteo Fisico)

#### labels
Etiquetas individuales para el conteo fisico.

| Columna          | Tipo                                      | Descripcion                          |
|------------------|-------------------------------------------|--------------------------------------|
| folio            | bigint (PK)                               | Numero de folio unico                |
| id_product       | bigint                                    | Producto asociado                    |
| id_warehouse     | bigint                                    | Almacen asociado                     |
| id_period        | bigint                                    | Periodo de inventario                |
| id_label_request | bigint                                    | Referencia a la solicitud de etiqueta|
| estado           | enum('CANCELADO','GENERADO','IMPRESO')    | Estado de la etiqueta                |
| created_by       | bigint                                    | Usuario que genero la etiqueta       |
| created_at       | datetime(6)                               | Fecha de creacion                    |
| impreso_at       | datetime(6)                               | Fecha de impresion                   |

---

#### label_requests
Solicitudes de generacion de etiquetas.

| Columna           | Tipo           | Descripcion                            |
|-------------------|----------------|----------------------------------------|
| id_label_request  | bigint (PK, AI)| Identificador de la solicitud          |
| id_product        | bigint         | Producto solicitado                    |
| id_warehouse      | bigint         | Almacen solicitante                    |
| id_period         | bigint         | Periodo de inventario                  |
| requested_labels  | int            | Cantidad de etiquetas solicitadas      |
| folios_generados  | int            | Folios generados                       |
| created_by        | bigint         | Usuario creador                        |
| created_at        | datetime(6)    | Fecha de creacion                      |

Restriccion unica: (id_product, id_warehouse, id_period)

---

#### label_generation_batches
Lotes de generacion de etiquetas.

| Columna           | Tipo           | Descripcion                       |
|-------------------|----------------|-----------------------------------|
| id_batch          | bigint (PK, AI)| Identificador del lote            |
| id_label_request  | bigint         | Solicitud relacionada             |
| id_warehouse      | bigint         | Almacen                           |
| id_period         | bigint         | Periodo                           |
| primer_folio      | bigint         | Primer folio generado             |
| ultimo_folio      | bigint         | Ultimo folio generado             |
| total_generados   | int            | Total de etiquetas generadas      |
| generado_por      | bigint         | Usuario que genero el lote        |
| generado_at       | datetime(6)    | Fecha de generacion               |

---

#### label_prints
Registros de impresion de etiquetas.

| Columna          | Tipo           | Descripcion                        |
|------------------|----------------|------------------------------------|
| id_label_print   | bigint (PK, AI)| Identificador del registro         |
| id_warehouse     | bigint         | Almacen                            |
| id_period        | bigint         | Periodo                            |
| folio_inicial    | bigint         | Folio inicial del rango impreso    |
| folio_final      | bigint         | Folio final del rango impreso      |
| cantidad_impresa | int            | Cantidad de etiquetas impresas     |
| printed_by       | bigint         | Usuario que imprimio               |
| printed_at       | datetime(6)    | Fecha de impresion                 |

---

#### label_counts
Resultados del conteo por folio.

| Columna          | Tipo           | Descripcion                       |
|------------------|----------------|-----------------------------------|
| id_label_count   | bigint (PK, AI)| Identificador                     |
| folio            | bigint (unico) | Folio de etiqueta                 |
| one_count        | decimal(38,2)  | Primer conteo                     |
| one_count_at     | datetime(6)    | Fecha del primer conteo           |
| one_count_by     | bigint         | Usuario del primer conteo         |
| second_count     | decimal(38,2)  | Segundo conteo                    |
| second_count_at  | datetime(6)    | Fecha del segundo conteo          |
| second_count_by  | bigint         | Usuario del segundo conteo        |

---

#### label_count_events
Eventos de conteo de etiquetas.

| Columna        | Tipo                                                                    | Descripcion                         |
|----------------|-------------------------------------------------------------------------|-------------------------------------|
| id_count_event | bigint (PK, AI)                                                         | Identificador del evento            |
| folio          | bigint                                                                  | Folio de la etiqueta                |
| count_number   | int                                                                     | Numero de conteo (1, 2, etc.)       |
| counted_value  | decimal(18,4)                                                           | Valor contado                       |
| previous_value | decimal(18,4)                                                           | Valor anterior                      |
| user_id        | bigint                                                                  | Usuario que realizo el conteo       |
| role_at_time   | enum('ADMINISTRADOR','ALMACENISTA','AUXILIAR','AUXILIAR_DE_CONTEO')     | Rol del usuario al momento del conteo|
| is_final       | bit(1)                                                                  | Indica si es el conteo final        |
| created_at     | datetime(6)                                                             | Fecha del evento                    |
| updated_at     | datetime(6)                                                             | Fecha de actualizacion              |
| updated_by     | bigint                                                                  | Usuario que actualizo               |

Restriccion unica: (folio, count_number)

---

#### label_folio_sequence
Control de secuencia de folios por periodo.

| Columna      | Tipo    | Descripcion                 |
|--------------|---------|-----------------------------|
| id_period    | bigint (PK) | Periodo                 |
| ultimo_folio | bigint  | Ultimo folio asignado       |

---

#### labels_cancelled
Registro de etiquetas canceladas.

| Columna                 | Tipo           | Descripcion                              |
|-------------------------|----------------|------------------------------------------|
| id_label_cancelled      | bigint (PK, AI)| Identificador de cancelacion             |
| folio                   | bigint (unico) | Folio cancelado                          |
| id_product              | bigint         | Producto                                 |
| id_warehouse            | bigint         | Almacen                                  |
| id_period               | bigint         | Periodo                                  |
| id_label_request        | bigint         | Solicitud de etiqueta                    |
| cancelado_by            | bigint         | Usuario que cancelo                      |
| cancelado_at            | datetime(6)    | Fecha de cancelacion                     |
| motivo_cancelacion      | varchar(255)   | Motivo de la cancelacion                 |
| notas                   | tinytext       | Notas adicionales                        |
| existencias_actuales    | int            | Existencias al momento de cancelar       |
| existencias_al_cancelar | int            | Existencias registradas al cancelar      |
| conteo1_al_cancelar     | decimal(18,4)  | Conteo 1 al momento de cancelar         |
| conteo2_al_cancelar     | decimal(18,4)  | Conteo 2 al momento de cancelar         |
| reactivado              | bit(1)         | Indica si fue reactivada                 |
| reactivado_at           | datetime(6)    | Fecha de reactivacion                    |
| reactivado_by           | bigint         | Usuario que reactivo                     |

---

### Tablas de Usuarios y Seguridad

#### users
Usuarios del sistema.

| Columna    | Tipo           | Descripcion              |
|------------|----------------|--------------------------|
| user_id    | bigint (PK, AI)| Identificador de usuario |
| (otros campos de acceso y credenciales)      |

---

#### personal_information
Informacion personal de los usuarios.

| Columna                  | Tipo           | Descripcion                      |
|--------------------------|----------------|----------------------------------|
| personal_information_id  | bigint (PK, AI)| Identificador                    |
| user_id                  | bigint (FK, unico) | Referencia a users           |
| name                     | varchar(255)   | Nombre                           |
| first_last_name          | varchar(255)   | Primer apellido                  |
| second_last_name         | varchar(255)   | Segundo apellido                 |
| phone_number             | varchar(255)   | Telefono                         |
| image                    | longblob       | Imagen de perfil                 |
| comments                 | varchar(255)   | Comentarios                      |
| created_at               | datetime(6)    | Fecha de creacion                |
| updated_at               | datetime(6)    | Fecha de actualizacion           |

---

#### user_warehouses
Almacenes asignados a usuarios.

| Columna | Tipo | Descripcion |
|---------|------|-------------|
| (relacion usuario-almacen) |

---

#### user_warehouse_assignments
Asignaciones de usuarios a almacenes.

| Columna | Tipo | Descripcion |
|---------|------|-------------|
| (relacion detallada usuario-almacen) |

---

#### password_reset_attempts
Intentos de restablecimiento de contrasena.

| Columna        | Tipo           | Descripcion                          |
|----------------|----------------|--------------------------------------|
| attempt_id     | bigint (PK, AI)| Identificador del intento            |
| user_id        | bigint (FK)    | Referencia a users                   |
| attempt_type   | varchar(255)   | Tipo de intento                      |
| is_successful  | bit(1)         | Indica si fue exitoso                |
| ip_address     | varchar(255)   | Direccion IP                         |
| error_message  | varchar(255)   | Mensaje de error                     |
| attempt_at     | datetime(6)    | Fecha del intento                    |

---

#### request_recovery_password
Solicitudes de recuperacion de contrasena.

| Columna           | Tipo                                         | Descripcion                        |
|-------------------|----------------------------------------------|------------------------------------|
| id                | bigint (PK)                                  | Identificador                      |
| email             | varchar(255)                                 | Correo electronico                 |
| verification_code | varchar(255)                                 | Codigo de verificacion             |
| status            | enum('ACTIVE','EXPIRED','REPLACED','USED')   | Estado de la solicitud             |
| request_reason    | varchar(255)                                 | Razon de la solicitud              |
| created_at        | datetime(6)                                  | Fecha de creacion                  |
| expires_at        | datetime(6)                                  | Fecha de expiracion                |

---

#### verification_code_logs
Registro de codigos de verificacion.

| Columna           | Tipo           | Descripcion              |
|-------------------|----------------|--------------------------|
| id                | bigint (PK)    | Identificador            |
| email             | varchar(255)   | Correo electronico       |
| verification_code | varchar(255)   | Codigo de verificacion   |
| status            | enum('ACTIVE','EXPIRED','REPLACED','USED') | Estado |
| request_reason    | varchar(255)   | Razon de la solicitud    |
| created_at        | datetime(6)    | Fecha de creacion        |
| expires_at        | datetime(6)    | Fecha de expiracion      |

---

#### revoked_tokens
Tokens de acceso revocados.

| Columna | Tipo | Descripcion |
|---------|------|-------------|
| (tokens JWT u otros que han sido invalidados) |

---

### Tablas de Auditoria y Actividad

#### audit_entry
Registro de auditoria de acciones en el sistema.

| Columna        | Tipo           | Descripcion                              |
|----------------|----------------|------------------------------------------|
| id             | varchar(36) (PK)| Identificador UUID                      |
| action         | varchar(100)   | Accion realizada                         |
| resource_type  | varchar(100)   | Tipo de recurso afectado                 |
| resource_id    | varchar(255)   | ID del recurso afectado                  |
| principal      | varchar(255)   | Identificador del actor                  |
| principal_name | varchar(255)   | Nombre del actor                         |
| outcome        | varchar(50)    | Resultado de la accion                   |
| http_status    | int            | Codigo HTTP de la respuesta              |
| client_ip      | varchar(100)   | IP del cliente                           |
| user_agent     | varchar(512)   | Agente de usuario                        |
| details        | text           | Detalles adicionales                     |
| created_at     | datetime(6)    | Fecha y hora del evento                  |

---

#### user_activity_log
Log de actividad de usuarios.

| Columna | Tipo | Descripcion |
|---------|------|-------------|
| (registro de actividades de los usuarios en el sistema) |

---

## Relaciones Clave

```
products (id_product)
    <- inventory_stock (id_product)
    <- label_requests (id_product)
    <- labels (id_product)
    <- labels_cancelled (id_product)

warehouse (id_warehouse)
    <- inventory_stock (id_warehouse)
    <- label_requests (id_warehouse)
    <- labels (id_warehouse)
    <- label_generation_batches (id_warehouse)
    <- label_prints (id_warehouse)

period (id_period)
    <- inventory_stock (id_period)
    <- label_requests (id_period)
    <- labels (id_period)
    <- label_folio_sequence (id_period)

users (user_id)
    <- personal_information (user_id)
    <- password_reset_attempts (user_id)
    <- user_warehouses
    <- user_warehouse_assignments
```

---

## Consulta de Ejemplo: Productos con Almacenes Relacionados

La siguiente consulta muestra todos los productos junto con sus almacenes relacionados a traves del stock de inventario:

```sql
SELECT
    p.id_product,
    p.cve_art       AS clave_articulo,
    p.descr         AS descripcion,
    p.lin_prod      AS linea_producto,
    p.uni_med       AS unidad_medida,
    p.status        AS estado_producto,
    w.id_warehouse,
    w.warehouse_key AS clave_almacen,
    w.name_warehouse AS nombre_almacen,
    ist.id_period,
    ist.exist_qty   AS existencia,
    ist.status      AS estado_stock
FROM sigmav2_2.products p
INNER JOIN sigmav2_2.inventory_stock ist
    ON p.id_product = ist.id_product
INNER JOIN sigmav2_2.warehouse w
    ON ist.id_warehouse = w.id_warehouse
WHERE w.deleted_at IS NULL
ORDER BY p.cve_art, w.warehouse_key;
```

---

## Notas

- Todos los almacenes usan eliminacion logica mediante el campo `deleted_at`.
- Los periodos controlan el ciclo de vida del inventario con estados: DRAFT, OPEN, LOCKED, CLOSED.
- El conteo fisico se gestiona mediante folios numericos secuenciales por periodo.
- Los roles de usuario disponibles son: ADMINISTRADOR, ALMACENISTA, AUXILIAR, AUXILIAR_DE_CONTEO.

