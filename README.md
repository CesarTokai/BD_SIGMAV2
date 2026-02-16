# BD_SIGMAV2 - Base de Datos SIGMA V2

En este repositorio se almacenarán las versiones de las bases de datos y queries desarrollados en el proyecto de SIGMAV2.

## 📁 Estructura del Repositorio

```
BD_SIGMAV2/
├── database/    # Archivos de base de datos (.sql, .dump, esquemas)
├── queries/     # Consultas SQL organizadas por funcionalidad
├── scripts/     # Scripts de migración, configuración y mantenimiento
└── backups/     # Respaldos de la base de datos
```

## 📖 Descripción de Carpetas

### `database/`
Contiene los archivos principales de la base de datos:
- Esquemas de base de datos
- Definiciones de tablas
- Archivos de estructura (.sql)
- Dumps completos de la base de datos

### `queries/`
Almacena las consultas SQL reutilizables:
- Consultas SELECT para reportes
- Procedimientos almacenados
- Funciones y vistas
- Queries de análisis

### `scripts/`
Scripts de automatización y mantenimiento:
- Scripts de migración de versiones
- Scripts de inicialización
- Scripts de limpieza y optimización
- Herramientas de administración

### `backups/`
Respaldos periódicos de la base de datos:
- Backups automáticos
- Snapshots de versiones importantes
- Respaldos antes de migraciones

## 🚀 Uso

1. **Para agregar un nuevo esquema de base de datos:**
   - Coloca el archivo .sql en la carpeta `database/`
   - Nombra el archivo con formato: `schema_YYYYMMDD_descripcion.sql`

2. **Para agregar queries:**
   - Guarda tus consultas en la carpeta `queries/`
   - Usa nombres descriptivos: `reporte_ventas.sql`, `usuarios_activos.sql`

3. **Para scripts de migración:**
   - Coloca los scripts en `scripts/`
   - Usa el formato: `migration_v1_to_v2.sql`

## 📝 Convenciones de Nomenclatura

- Usa nombres descriptivos en minúsculas
- Separa palabras con guiones bajos (snake_case)
- Incluye fechas en formato YYYYMMDD cuando sea relevante
- Versiona los archivos importantes: `schema_v1.0.sql`, `schema_v1.1.sql`

## 🤝 Contribuciones

Al contribuir a este repositorio, asegúrate de:
1. Documentar adecuadamente tus cambios
2. Seguir las convenciones de nomenclatura
3. Probar los scripts antes de subirlos
4. Incluir comentarios en archivos SQL complejos

## 📄 Licencia

Este repositorio es parte del proyecto SIGMAV2.
