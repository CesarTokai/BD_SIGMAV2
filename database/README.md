# Database / Base de Datos

Esta carpeta contiene los archivos principales de la base de datos del proyecto SIGMAV2.

## Contenido

Aquí deberías almacenar:

- **Esquemas de base de datos**: Definición completa de la estructura
- **Archivos .sql**: Scripts de creación de tablas y estructura
- **Dumps**: Respaldos completos de la base de datos
- **Definiciones DDL**: Data Definition Language statements

## Nomenclatura Recomendada

```
schema_v1.0.sql
schema_v1.1_add_users_table.sql
schema_YYYYMMDD.sql
sigmav2_structure.sql
```

## Versionamiento

Mantén un control de versiones claro:
- Usa números de versión semántica (v1.0, v1.1, v2.0)
- Incluye fechas para snapshots: schema_20260216.sql
- Documenta cambios importantes en comentarios SQL

## Ejemplo de Archivo

```sql
-- SIGMAV2 Database Schema v1.0
-- Date: 2026-02-16
-- Description: Initial database structure

CREATE TABLE users (
    id INT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```
