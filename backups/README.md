# Backups / Respaldos

Esta carpeta contiene los respaldos de la base de datos SIGMAV2.

## Contenido

Aquí deberías almacenar:

- **Backups automáticos**: Respaldos programados
- **Snapshots**: Capturas de versiones importantes
- **Backups pre-migración**: Antes de cambios importantes
- **Backups de recuperación**: Para restauración de desastres

## ⚠️ Importante

**NOTA DE SEGURIDAD**: Los archivos de backup pueden contener datos sensibles. 

Consideraciones:
- No subir backups con datos de producción a repositorios públicos
- Usar `.gitignore` para excluir backups grandes
- Encriptar backups que contengan información sensible
- Usar servicios de almacenamiento seguro para producción

## Nomenclatura Recomendada

```
backup_YYYYMMDD_HHMMSS.sql
backup_20260216_143000.sql
backup_pre_migration_v1_to_v2.sql
snapshot_production_20260216.dump
```

## Comandos Útiles

### Crear Backup (MySQL)
```bash
mysqldump -u username -p sigmav2 > backup_20260216.sql
```

### Restaurar Backup
```bash
mysql -u username -p sigmav2 < backup_20260216.sql
```

### Backup Comprimido
```bash
mysqldump -u username -p sigmav2 | gzip > backup_20260216.sql.gz
```

## Ejemplo de .gitignore

Agrega esto al `.gitignore` del repositorio para evitar subir backups grandes:

```
# Ignorar backups grandes
backups/*.sql
backups/*.dump
backups/*.gz
backups/*.zip

# Mantener solo archivos .gitkeep y README
!backups/.gitkeep
!backups/README.md
```
