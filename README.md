# Aplicación Patrón - Integración Efímera

Esta aplicación ha sido diseñada para estresar y validar una infraestructura de tres máquinas (VM1: Jenkins/CI, VM2: Harbor, VM3: Dev/Prod).

## Características Arquitectónicas
- **Backend**: Node.js 18 + Express + Sequelize.
- **Base de Datos**: PostgreSQL 15.
- **Dockerización**: Imagen ultra-ligera (<150MB) basada en Alpine Linux.
- **Integración Efímera**: Capacidad de "nacer" desde cero en entornos temporales mediante migraciones automáticas.

## Estructura del Proyecto
- `src/`: Código fuente de la aplicación.
  - `config/`: Configuración de DB "ciega a IPs" (vía variables de entorno).
  - `migrations/`: Lógica para recrear la estructura de datos.
  - `models/`: Definición de objetos de negocio.
  - `test/`: Tests de humo para validación en el pipeline.
- `Dockerfile`: Construcción optimizada para bajo consumo de RAM (3GB limit).
- `Jenkinsfile`: Orquestación de 3 niveles (Auditoría -> Integración -> Entrega).

## Variables de Entorno Requeridas
- `DB_HOST`: Host de la base de datos (nombre del contenedor en test).
- `DB_USER`: Usuario de Postgres.
- `DB_PASS`: Contraseña de Postgres.
- `DB_NAME`: Nombre de la base de datos.

## Flujo de Validación (Jenkinsfile)
1. **Auditoría**: Análisis estático con SonarQube.
2. **Integración**: Se levanta una red y una DB Postgres temporal en la VM1. Se corren las migraciones y los tests de humo. Se destruye todo al finalizar.
3. **Entrega**: Si los tests pasan, la imagen se etiqueta y se sube al registro Harbor en la VM2.
