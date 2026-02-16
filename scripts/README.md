# Scripts / Scripts de Base de Datos

Esta carpeta contiene scripts de automatización y mantenimiento para la base de datos SIGMAV2.

## Contenido

Aquí deberías almacenar:

- **Scripts de migración**: Para actualizar de una versión a otra
- **Scripts de inicialización**: Setup inicial de la base de datos
- **Scripts de mantenimiento**: Limpieza, optimización, índices
- **Scripts de datos**: Carga de datos iniciales (seeds)
- **Herramientas de administración**: Scripts útiles para DBAs

## Nomenclatura Recomendada

```
migration_v1.0_to_v1.1.sql
init_database.sql
seed_initial_data.sql
maintenance_cleanup_logs.sql
optimize_indexes.sql
```

## Tipos de Scripts

### Migraciones
```sql
-- Migration: v1.0 to v1.1
-- Description: Add users table
-- Date: 2026-02-16

ALTER TABLE users ADD COLUMN last_login TIMESTAMP;
CREATE INDEX idx_users_email ON users(email);
```

### Inicialización
```sql
-- Database Initialization Script
-- Run this script to set up the database

CREATE DATABASE IF NOT EXISTS sigmav2;
USE sigmav2;

SOURCE schema_v1.0.sql;
SOURCE seed_initial_data.sql;
```

### Seeds (Datos Iniciales)
```sql
-- Initial Data Seed
-- Roles and basic configuration

INSERT INTO roles (name, description) VALUES
    ('admin', 'Administrator'),
    ('user', 'Regular User'),
    ('guest', 'Guest User');
```
