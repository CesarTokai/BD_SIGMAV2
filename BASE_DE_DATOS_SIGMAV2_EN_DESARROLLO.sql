USE SIGMAV2;


SET FOREIGN_KEY_CHECKS = 0;

ALTER TABLE personal_information DROP FOREIGN KEY fk_personal_info_user;

ALTER TABLE personal_information
    ADD CONSTRAINT fk_pi_user
        FOREIGN KEY (user_id) REFERENCES users(user_id)
            ON DELETE CASCADE;

SET FOREIGN_KEY_CHECKS = 1;


/* =====================================================================
   SIGMAV2 - Esquema de Inventarios y Marbetes
   Requisitos: MySQL 8+, InnoDB, utf8mb4
   Notas:
   - Todas las FK referencian claves surrogate (IDs) para consistencia.
   - Los reportes se implementan como VISTAS para mantener datos al día.
   - period (DATE) usa convención del primer día del mes (YYYY-MM-01).
   - Este script incluye mejoras de integridad, rendimiento e
     (opcional) sincronización automática de conteos.
   ===================================================================== */

-- Recomendable para desarrollo (no usar en prod sin evaluación de riesgos)
-- SET FOREIGN_KEY_CHECKS = 0;

-- =========================
-- Creación de Base de Datos
-- =========================
CREATE DATABASE IF NOT EXISTS SIGMAV2
    DEFAULT CHARACTER SET utf8mb4
    DEFAULT COLLATE utf8mb4_0900_ai_ci;
USE SIGMAV2;

-- ===============================
-- 1) Seguridad y cuentas (usuarios)
-- ===============================
/*
  Tabla: users
  Propósito: autenticación, roles y estado de la cuenta.
  Mejoras:
  - email único.
  - password_hash (no guardar texto plano).
  - status e is_verified como booleanos (TINYINT(1)).
*/
CREATE TABLE IF NOT EXISTS users (
                                     user_id           BIGINT PRIMARY KEY AUTO_INCREMENT,
                                     email             VARCHAR(255) NOT NULL,
                                     password_hash     VARCHAR(255) NOT NULL,
                                     role              ENUM('ADMINISTRADOR','ALMACENISTA','AUXILIAR','AUXILIAR_DE_CONTEO') NOT NULL,
                                     status            TINYINT(1) NOT NULL DEFAULT 1,         -- 1=activo, 0=inactivo
                                     is_verified       TINYINT(1) NOT NULL DEFAULT 0,
                                     attempts          INT NOT NULL DEFAULT 0,
                                     last_try_at       DATETIME NULL,
                                     verification_code VARCHAR(50) NULL,
                                     created_at        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                     updated_at        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                                     UNIQUE KEY uk_users_email (email)
) ENGINE=InnoDB;

/*
  Tabla: personal_information
  Propósito: datos personales 1:1 con users.
  ON DELETE CASCADE: elimina PI al borrar usuario.
*/
CREATE TABLE IF NOT EXISTS personal_information (
                                                    personal_information_id BIGINT PRIMARY KEY AUTO_INCREMENT,
                                                    user_id          BIGINT NOT NULL,
                                                    first_last_name  VARCHAR(255) NULL,
                                                    second_last_name VARCHAR(255) NULL,
                                                    phone_number     VARCHAR(50)  NULL,
                                                    image            LONGBLOB NULL,
                                                    CONSTRAINT fk_pi_user
                                                        FOREIGN KEY (user_id) REFERENCES users(user_id)
                                                            ON DELETE CASCADE,
                                                    UNIQUE KEY uk_pi_user (user_id)
) ENGINE=InnoDB;

/*
  Tabla: password_recovery_requests
  Propósito: flujo de recuperación de contraseña.
  Mejoras:
  - token único.
  - marcas de tiempo (solicitud y resolución).
*/
CREATE TABLE IF NOT EXISTS password_recovery_requests (
                                                          request_id   BIGINT PRIMARY KEY AUTO_INCREMENT,
                                                          user_id      BIGINT NOT NULL,
                                                          token        VARCHAR(100) NOT NULL,
                                                          status       ENUM('ACCEPTED','PENDING','REJECTED') NOT NULL DEFAULT 'PENDING',
                                                          requested_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                                          resolved_at  DATETIME NULL,
                                                          CONSTRAINT fk_prr_user
                                                              FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
                                                          UNIQUE KEY uk_prr_token (token)
) ENGINE=InnoDB;

-- ===========================
-- 2) Catálogos maestros (core)
-- ===========================
/*
  Tabla: warehouse
  Propósito: catálogo de almacenes.
  Mejoras: claves lógicas únicas, índices para búsquedas.
*/
CREATE TABLE IF NOT EXISTS warehouse (
                                         id_warehouse   BIGINT PRIMARY KEY AUTO_INCREMENT,
                                         warehouse_key  VARCHAR(50)  NOT NULL,
                                         name_warehouse VARCHAR(255) NOT NULL,
                                         observations   VARCHAR(255) NULL,
                                         UNIQUE KEY uk_wh_key (warehouse_key),
                                         UNIQUE KEY uk_wh_name (name_warehouse)
) ENGINE=InnoDB;

/*
  Tabla: periods
  Propósito: catálogo de periodos (mes-año).
  Convención: usar día 1 del mes (YYYY-MM-01).
*/
CREATE TABLE IF NOT EXISTS periods (
                                       id_period   BIGINT PRIMARY KEY AUTO_INCREMENT,
                                       period      DATE NOT NULL,         -- ej. 2025-08-01 = Agosto 2025
                                       comments    VARCHAR(255) NOT NULL DEFAULT '',
                                       UNIQUE KEY uk_period (period)
) ENGINE=InnoDB;

/*
  Tabla: products
  Propósito: catálogo de productos.
  Mejoras:
  - cve_art único.
  - status (‘A’/’B’).
*/
CREATE TABLE IF NOT EXISTS products (
                                        id_product BIGINT PRIMARY KEY AUTO_INCREMENT,
                                        cve_art    VARCHAR(64)  NOT NULL,
                                        descr      VARCHAR(255) NOT NULL,
                                        uni_med    VARCHAR(50)  NOT NULL,
                                        status     ENUM('A','B') NOT NULL DEFAULT 'A',
                                        created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                        UNIQUE KEY uk_products_cve (cve_art),
                                        KEY idx_products_descr (descr)
) ENGINE=InnoDB;

/*
  Tabla: inventory_stock
  Propósito: existencias actuales por producto+almacén.
  Mejoras:
  - DECIMAL para cantidades.
  - índice único por (producto, almacén).
  - CHECK: existencias no negativas.
*/
CREATE TABLE IF NOT EXISTS inventory_stock (
                                               id_stock      BIGINT PRIMARY KEY AUTO_INCREMENT,
                                               id_product    BIGINT NOT NULL,
                                               id_warehouse  BIGINT NOT NULL,
                                               exist_qty     DECIMAL(18,2) NOT NULL DEFAULT 0,
                                               status        ENUM('A','B') NOT NULL DEFAULT 'A',
                                               updated_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                                               CONSTRAINT fk_stock_product   FOREIGN KEY (id_product)   REFERENCES products(id_product),
                                               CONSTRAINT fk_stock_warehouse FOREIGN KEY (id_warehouse) REFERENCES warehouse(id_warehouse),
                                               UNIQUE KEY uk_stock_product_warehouse (id_product, id_warehouse),
                                               KEY idx_stock_wh (id_warehouse),
                                               KEY idx_stock_prod (id_product),
                                               CONSTRAINT chk_stock_non_negative CHECK (exist_qty >= 0)
) ENGINE=InnoDB;

-- (Opcional futuro) snapshots inmutables por periodo para auditoría/cierres.
-- CREATE TABLE inventory_snapshot (
--   id_snapshot   BIGINT PRIMARY KEY AUTO_INCREMENT,
--   id_product    BIGINT NOT NULL,
--   id_warehouse  BIGINT NOT NULL,
--   id_period     BIGINT NOT NULL,
--   exist_qty     DECIMAL(18,2) NOT NULL DEFAULT 0,
--   created_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
--   CONSTRAINT fk_snap_product   FOREIGN KEY (id_product)   REFERENCES products(id_product),
--   CONSTRAINT fk_snap_warehouse FOREIGN KEY (id_warehouse) REFERENCES warehouse(id_warehouse),
--   CONSTRAINT fk_snap_period    FOREIGN KEY (id_period)    REFERENCES periods(id_period),
--   UNIQUE KEY uk_snapshot (id_product, id_warehouse, id_period)
-- ) ENGINE=InnoDB;

-- ============================
-- 3) Lógica de MARBETES (core)
-- ============================
/*
  Tabla: label_requests
  Propósito: solicitudes de marbetes (folios) por producto+almacén+periodo.
  Mejoras:
  - clave única para evitar duplicados por periodo.
  - CHECK: requested_labels > 0.
  - Índices por periodo/almacén/producto para reportes.
*/
CREATE TABLE IF NOT EXISTS label_requests (
                                              id_label_request BIGINT PRIMARY KEY AUTO_INCREMENT,
                                              id_product       BIGINT NOT NULL,
                                              id_warehouse     BIGINT NOT NULL,
                                              id_period        BIGINT NOT NULL,
                                              requested_labels INT    NOT NULL,
                                              created_by       BIGINT NOT NULL,  -- user_id que solicita
                                              created_at       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                              CONSTRAINT fk_lr_product   FOREIGN KEY (id_product)   REFERENCES products(id_product),
                                              CONSTRAINT fk_lr_warehouse FOREIGN KEY (id_warehouse) REFERENCES warehouse(id_warehouse),
                                              CONSTRAINT fk_lr_period    FOREIGN KEY (id_period)    REFERENCES periods(id_period),
                                              CONSTRAINT fk_lr_user      FOREIGN KEY (created_by)   REFERENCES users(user_id),
                                              CONSTRAINT chk_lr_requested CHECK (requested_labels > 0),
                                              UNIQUE KEY uk_lr_unica (id_product, id_warehouse, id_period),
                                              KEY idx_lr_period (id_period),
                                              KEY idx_lr_warehouse (id_warehouse),
                                              KEY idx_lr_product (id_product)
) ENGINE=InnoDB;

/*
  Tabla: label_prints
  Propósito: registro de impresiones de marbetes por solicitud.
  Mejoras:
  - CHECK: printed_labels > 0.
  - Índice por solicitud.
*/
CREATE TABLE IF NOT EXISTS label_prints (
                                            id_label_print    BIGINT PRIMARY KEY AUTO_INCREMENT,
                                            id_label_request  BIGINT NOT NULL,
                                            printed_labels    INT    NOT NULL,
                                            status_impression ENUM('S','N') NOT NULL DEFAULT 'N',
                                            printed_at        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                            CONSTRAINT fk_lp_request FOREIGN KEY (id_label_request) REFERENCES label_requests(id_label_request) ON DELETE CASCADE,
                                            CONSTRAINT chk_prints_qty CHECK (printed_labels > 0),
                                            KEY idx_lp_request (id_label_request)
) ENGINE=InnoDB;

/*
  Tabla: label_count_events (historial)
  Propósito: historial de conteos realizados (n entradas por marbete).
  Mejoras:
  - UNIQ (id_label_request, count_number) evita dos “primer conteo”, etc.
  - CHECK: counted_value >= 0.
*/
CREATE TABLE IF NOT EXISTS label_count_events (
                                                  id_count_event    BIGINT PRIMARY KEY AUTO_INCREMENT,
                                                  id_label_request  BIGINT NOT NULL,      -- Folio/marbete
                                                  user_id           BIGINT NOT NULL,      -- Quién contó
                                                  count_number      INT NOT NULL,         -- 1=1er, 2=2do, 3=n re-conteo...
                                                  counted_value     INT NOT NULL,         -- Cantidad contada
                                                  role_at_time      ENUM('AUXILIAR','AUXILIAR_DE_CONTEO','SUPERVISOR','ALMACENISTA') NOT NULL,
                                                  is_final          BOOLEAN NOT NULL DEFAULT FALSE,  -- Si este valor se considera final
                                                  created_at        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                                  CONSTRAINT fk_count_event_label FOREIGN KEY (id_label_request)
                                                      REFERENCES label_requests(id_label_request) ON DELETE CASCADE,
                                                  CONSTRAINT fk_count_event_user FOREIGN KEY (user_id)
                                                      REFERENCES users(user_id),
                                                  CONSTRAINT chk_count_events_non_negative CHECK (counted_value >= 0),
                                                  UNIQUE KEY uk_count_event_unique (id_label_request, count_number),
                                                  KEY idx_count_event_label (id_label_request)
) ENGINE=InnoDB;

/*
  Tabla: label_counts (resumen operativo)
  Propósito: estado “oficial” (rápido) de 1er y 2do conteo.
  Mejoras:
  - diff_count calculada (C2 - C1).
  - UNIQ por id_label_request (un resumen por marbete).
  - CHECK: valores no negativos; si status='C' entonces al menos un conteo > 0 (validación básica).
*/
CREATE TABLE IF NOT EXISTS label_counts (
                                            id_label_count   BIGINT PRIMARY KEY AUTO_INCREMENT,
                                            id_label_request BIGINT NOT NULL,        -- Relación con la solicitud de marbete
                                            one_count        INT NOT NULL DEFAULT 0, -- Conteo 1 oficial
                                            second_count     INT NOT NULL DEFAULT 0, -- Conteo 2 oficial
                                            diff_count       INT AS (second_count - one_count) STORED, -- Diferencia entre conteos
                                            status           ENUM('C','A') NOT NULL DEFAULT 'A',  -- C=cerrado, A=abierto
                                            counted_at       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                            CONSTRAINT fk_lc_request FOREIGN KEY (id_label_request)
                                                REFERENCES label_requests(id_label_request) ON DELETE CASCADE,
                                            CONSTRAINT chk_lc_non_negative CHECK (one_count >= 0 AND second_count >= 0),
                                            UNIQUE KEY uk_lc_request (id_label_request),
                                            KEY idx_lc_request (id_label_request),
                                            KEY idx_lc_status (status)
) ENGINE=InnoDB;

/*
  Tabla: label_cancellations
  Propósito: soporte para marbetes cancelados (motivo y fecha).
*/
CREATE TABLE IF NOT EXISTS label_cancellations (
                                                   id_cancel           BIGINT PRIMARY KEY AUTO_INCREMENT,
                                                   id_label_request    BIGINT NOT NULL,
                                                   reason              VARCHAR(255) NOT NULL,
                                                   cancelled_by        BIGINT NOT NULL,
                                                   cancelled_at        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                                   CONSTRAINT fk_lcancel_req  FOREIGN KEY (id_label_request) REFERENCES label_requests(id_label_request) ON DELETE CASCADE,
                                                   CONSTRAINT fk_lcancel_user FOREIGN KEY (cancelled_by)     REFERENCES users(user_id),
                                                   KEY idx_lcancel_req (id_label_request)
) ENGINE=InnoDB;

-- ===========================
-- 4) Reportes (como VISTAS)
-- ===========================
/*
  Vista: distribution_label_report
  Propósito: distribución por usuario/almacén/período con totales impresos.
  Rendimiento: filtra SIEMPRE por period/warehouse/producto desde el backend.
*/
CREATE OR REPLACE VIEW distribution_label_report AS
SELECT
    lr.id_label_request,
    u.email                  AS username,
    w.warehouse_key,
    w.name_warehouse,
    p.period,
    pr.cve_art,
    pr.descr,
    lr.requested_labels,
    COALESCE(SUM(lp.printed_labels),0) AS total_printed_labels
FROM label_requests lr
         JOIN users u     ON u.user_id = lr.created_by
         JOIN warehouse w ON w.id_warehouse = lr.id_warehouse
         JOIN periods  p  ON p.id_period    = lr.id_period
         JOIN products pr ON pr.id_product  = lr.id_product
         LEFT JOIN label_prints lp ON lp.id_label_request = lr.id_label_request
GROUP BY
    lr.id_label_request, u.email, w.warehouse_key, w.name_warehouse, p.period, pr.cve_art, pr.descr, lr.requested_labels;

/*
  Vista: label_list_report
  Propósito: listado por solicitud con impresos y últimos conteos cerrados.
  Nota: MAX sobre conteos cerrados para obtener último cierre.
*/
CREATE OR REPLACE VIEW label_list_report AS
SELECT
    lr.id_label_request,
    p.period,
    w.warehouse_key,
    w.name_warehouse,
    pr.cve_art,
    pr.descr,
    lr.requested_labels,
    COALESCE(SUM(lp.printed_labels),0) AS printed_labels,
    COALESCE(MAX(CASE WHEN lc.status='C' THEN lc.one_count END),0)    AS last_one_count_closed,
    COALESCE(MAX(CASE WHEN lc.status='C' THEN lc.second_count END),0) AS last_second_count_closed,
    COALESCE(MAX(CASE WHEN lc.status='C' THEN lc.diff_count END),0)   AS last_diff_closed
FROM label_requests lr
         JOIN periods  p  ON p.id_period    = lr.id_period
         JOIN warehouse w ON w.id_warehouse = lr.id_warehouse
         JOIN products pr ON pr.id_product  = lr.id_product
         LEFT JOIN label_prints lp ON lp.id_label_request = lr.id_label_request
         LEFT JOIN label_counts lc ON lc.id_label_request = lr.id_label_request
GROUP BY
    lr.id_label_request, p.period, w.warehouse_key, w.name_warehouse, pr.cve_art, pr.descr, lr.requested_labels;

/*
  Vista: v_report_marbetes_pendientes  (RF-37/RF-47)
  Propósito: marbetes sin C1 y sin C2 (pendientes).
*/
CREATE OR REPLACE VIEW v_report_marbetes_pendientes AS
SELECT
    lr.id_label_request             AS folio,
    pr.cve_art,
    pr.descr,
    pr.uni_med,
    w.warehouse_key,
    p.period,
    0 AS conteo_1,
    0 AS conteo_2,
    'PENDIENTE' AS estado
FROM label_requests lr
         JOIN products  pr ON pr.id_product  = lr.id_product
         JOIN warehouse w  ON w.id_warehouse = lr.id_warehouse
         JOIN periods   p  ON p.id_period    = lr.id_period
         LEFT JOIN label_counts lc ON lc.id_label_request = lr.id_label_request
WHERE COALESCE(lc.one_count, 0) = 0
  AND COALESCE(lc.second_count, 0) = 0;

/*
  Vista: v_report_marbetes_diferencias (RF-38/RF-48)
  Propósito: marbetes donde C2 ≠ C1 (diferencia con signo).
*/
CREATE OR REPLACE VIEW v_report_marbetes_diferencias AS
SELECT
    lr.id_label_request AS folio,
    pr.cve_art,
    pr.descr,
    pr.uni_med,
    w.warehouse_key,
    p.period,
    COALESCE(lc.one_count,0)    AS conteo_1,
    COALESCE(lc.second_count,0) AS conteo_2,
    (COALESCE(lc.second_count,0) - COALESCE(lc.one_count,0)) AS diferencia
FROM label_requests lr
         JOIN products  pr ON pr.id_product  = lr.id_product
         JOIN warehouse w  ON w.id_warehouse = lr.id_warehouse
         JOIN periods   p  ON p.id_period    = lr.id_period
         JOIN label_counts lc ON lc.id_label_request = lr.id_label_request
WHERE (COALESCE(lc.second_count,0) - COALESCE(lc.one_count,0)) <> 0;

/*
  Vista: v_report_marbetes_cancelados (RF-39/RF-49)
  Propósito: marbetes cancelados con motivo y fecha de cancelación.
*/
CREATE OR REPLACE VIEW v_report_marbetes_cancelados AS
SELECT
    lr.id_label_request AS folio,
    pr.cve_art,
    pr.descr,
    pr.uni_med,
    w.warehouse_key,
    p.period,
    lcanc.cancelled_at  AS fecha_cancelacion,
    lcanc.reason        AS motivo
FROM label_requests lr
         JOIN products  pr   ON pr.id_product   = lr.id_product
         JOIN warehouse w    ON w.id_warehouse  = lr.id_warehouse
         JOIN periods   p    ON p.id_period     = lr.id_period
         JOIN label_cancellations lcanc ON lcanc.id_label_request = lr.id_label_request;

/*
  Vista: v_report_comparativo_existencias (RF-40/RF-50)
  Propósito: comparar existencias físicas (pref. C2, si no C1) vs teóricas (stock).
*/
CREATE OR REPLACE VIEW v_report_comparativo_existencias AS
WITH fisicas AS (
    SELECT
        lr.id_label_request,
        lr.id_product,
        lr.id_warehouse,
        lr.id_period,
        CASE
            WHEN lc.second_count IS NOT NULL THEN lc.second_count
            WHEN lc.one_count    IS NOT NULL THEN lc.one_count
            ELSE 0
            END AS exist_fisica
    FROM label_requests lr
             LEFT JOIN label_counts lc ON lc.id_label_request = lr.id_label_request
)
SELECT
    w.warehouse_key,
    pr.cve_art,
    pr.descr,
    p.period,
    ROUND(COALESCE(f.exist_fisica,0), 4)        AS existencias_fisicas,
    ROUND(COALESCE(isx.exist_qty,0), 4)         AS existencias_teoricas,
    ROUND(COALESCE(f.exist_fisica,0) - COALESCE(isx.exist_qty,0), 4) AS diferencia
FROM fisicas f
         JOIN products  pr ON pr.id_product  = f.id_product
         JOIN warehouse w  ON w.id_warehouse = f.id_warehouse
         JOIN periods   p  ON p.id_period    = f.id_period
         LEFT JOIN inventory_stock isx
                   ON isx.id_product = f.id_product AND isx.id_warehouse = f.id_warehouse;

/*
  Vista: v_report_almacen_detalle (RF-51)
  Propósito: detalle por almacén, mostrando estado de avance y existencias físicas.
*/
CREATE OR REPLACE VIEW v_report_almacen_detalle AS
SELECT
    w.warehouse_key,
    pr.cve_art,
    pr.descr,
    pr.uni_med,
    lr.id_label_request AS folio,
    COALESCE(lc.second_count, lc.one_count, 0) AS existencias_fisicas,
    CASE
        WHEN lc.id_label_count IS NULL THEN 'GENERADO'
        WHEN lc.id_label_count IS NOT NULL AND (lc.second_count IS NULL AND lc.one_count IS NOT NULL) THEN 'CONTEO_1'
        WHEN lc.second_count IS NOT NULL THEN 'CONTEO_2'
        ELSE 'IMPRESO'
        END AS estado,
    p.period
FROM label_requests lr
         JOIN warehouse w  ON w.id_warehouse = lr.id_warehouse
         JOIN products  pr ON pr.id_product  = lr.id_product
         JOIN periods   p  ON p.id_period    = lr.id_period
         LEFT JOIN label_counts lc ON lc.id_label_request = lr.id_label_request;

/*
  Vista: v_report_producto_detalle (RF-52)
  Propósito: detalle por producto con total del periodo.
*/
CREATE OR REPLACE VIEW v_report_producto_detalle AS
SELECT
    pr.cve_art,
    pr.descr,
    pr.uni_med,
    w.warehouse_key,
    lr.id_label_request AS folio,
    COALESCE(lc.second_count, lc.one_count, 0) AS existencias,
    SUM(COALESCE(lc.second_count, lc.one_count, 0))
        OVER (PARTITION BY pr.id_product, p.id_period) AS total_producto_periodo,
    p.period
FROM label_requests lr
         JOIN products  pr ON pr.id_product  = lr.id_product
         JOIN warehouse w  ON w.id_warehouse = lr.id_warehouse
         JOIN periods   p  ON p.id_period    = lr.id_period
         LEFT JOIN label_counts lc ON lc.id_label_request = lr.id_label_request;

/*
  Vista: v_export_inventario_txt (RF-53)
  Propósito: base para exportar archivo plano "<CVE>|<DESC>|<EXISTENCIA>" por periodo.
*/
CREATE OR REPLACE VIEW v_export_inventario_txt AS
SELECT
    pr.cve_art,
    pr.descr,
    p.period,
    ROUND(SUM(COALESCE(lc.second_count, lc.one_count, 0)), 4) AS existencia_fisica_total
FROM label_requests lr
         JOIN products pr  ON pr.id_product  = lr.id_product
         JOIN periods  p   ON p.id_period    = lr.id_period
         LEFT JOIN label_counts lc ON lc.id_label_request = lr.id_label_request
GROUP BY pr.cve_art, pr.descr, p.period;

-- ================================
-- 5) Sincronización automática (OPCIONAL, RECOMENDADA)
--    Mantiene label_counts en línea con label_count_events
-- ================================
/*
  Procedimiento: sp_refresh_label_counts(p_id_label_request)
  Lógica:
  - Toma el “mejor” 1er conteo = MIN(count_number)=1 si existe, o el primero disponible.
  - Toma el “mejor” 2do conteo = MAX(count_number) marcado is_final=TRUE; si no hay final,
    usa el mayor count_number disponible.
  - Si no hay eventos, deja 0/0 y estado 'A'.
*/

DELIMITER $$
CREATE PROCEDURE sp_refresh_label_counts(IN p_id_label_request BIGINT)
BEGIN
    DECLARE v_one INT DEFAULT 0;
    DECLARE v_two INT DEFAULT 0;
    DECLARE v_has_any INT DEFAULT 0;
    DECLARE v_has_final INT DEFAULT 0;

    SELECT COUNT(*) INTO v_has_any
    FROM label_count_events
    WHERE id_label_request = p_id_label_request;

    IF v_has_any > 0 THEN
        -- 1er conteo preferente (count_number=1)
        SELECT COALESCE((
                            SELECT counted_value
                            FROM label_count_events
                            WHERE id_label_request = p_id_label_request AND count_number = 1
                            ORDER BY created_at ASC
                            LIMIT 1
                        ), (
                            SELECT counted_value
                            FROM label_count_events
                            WHERE id_label_request = p_id_label_request
                            ORDER BY count_number ASC, created_at ASC
                            LIMIT 1
                        ), 0) INTO v_one;

        -- 2do conteo preferente (final más reciente si existe; si no, el mayor count_number)
        SELECT COUNT(*) INTO v_has_final
        FROM label_count_events
        WHERE id_label_request = p_id_label_request AND is_final = TRUE;

        IF v_has_final > 0 THEN
            SELECT counted_value INTO v_two
            FROM label_count_events
            WHERE id_label_request = p_id_label_request AND is_final = TRUE
            ORDER BY created_at DESC
            LIMIT 1;
        ELSE
            SELECT counted_value INTO v_two
            FROM label_count_events
            WHERE id_label_request = p_id_label_request
            ORDER BY count_number DESC, created_at DESC
            LIMIT 1;
        END IF;
    END IF;

    -- Upsert al resumen
    INSERT INTO label_counts (id_label_request, one_count, second_count, status, counted_at)
    VALUES (p_id_label_request, COALESCE(v_one,0), COALESCE(v_two,0),
            CASE WHEN v_has_any > 0 THEN 'C' ELSE 'A' END, NOW())
    ON DUPLICATE KEY UPDATE
                         one_count   = VALUES(one_count),
                         second_count= VALUES(second_count),
                         counted_at  = VALUES(counted_at),
                         status      = VALUES(status);
END$$
DELIMITER ;

-- Triggers para refrescar el resumen cuando cambia el historial
DELIMITER $$
CREATE TRIGGER trg_lce_ai AFTER INSERT ON label_count_events
    FOR EACH ROW BEGIN
    CALL sp_refresh_label_counts(NEW.id_label_request);
END$$

CREATE TRIGGER trg_lce_au AFTER UPDATE ON label_count_events
    FOR EACH ROW BEGIN
    CALL sp_refresh_label_counts(NEW.id_label_request);
END$$

CREATE TRIGGER trg_lce_ad AFTER DELETE ON label_count_events
    FOR EACH ROW BEGIN
    CALL sp_refresh_label_counts(OLD.id_label_request);
END$$
DELIMITER ;

-- SET FOREIGN_KEY_CHECKS = 1;
