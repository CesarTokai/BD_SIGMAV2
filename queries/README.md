# Queries / Consultas SQL

Esta carpeta contiene las consultas SQL reutilizables del proyecto SIGMAV2.

## Contenido

Aquí deberías almacenar:

- **Consultas SELECT**: Para reportes y análisis
- **Procedimientos almacenados**: Stored procedures
- **Funciones**: User-defined functions
- **Vistas**: View definitions
- **Queries complejas**: Consultas de análisis y reportes

## Organización

Puedes organizar por:
- Funcionalidad: `usuarios/`, `ventas/`, `reportes/`
- Tipo: `procedures/`, `functions/`, `views/`
- Módulo: `modulo_auth/`, `modulo_ventas/`

## Nomenclatura Recomendada

```
reporte_ventas_mensuales.sql
consulta_usuarios_activos.sql
proc_actualizar_inventario.sql
view_dashboard_principal.sql
```

## Ejemplo de Archivo

```sql
-- Consulta: Usuarios Activos en los últimos 30 días
-- Fecha: 2026-02-16
-- Autor: [Tu nombre]

SELECT 
    u.id,
    u.username,
    u.email,
    COUNT(a.id) as total_acciones
FROM users u
LEFT JOIN user_actions a ON u.id = a.user_id
WHERE a.created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)
GROUP BY u.id, u.username, u.email
ORDER BY total_acciones DESC;
```
