# Weather App - Diseño de Arquitectura

## Diseño de Arquitectura

**Service Layer + Component-Based Architecture**

```
┌─────────────────────────────────────────┐
│           LiveView Principal            │
│        (Coordinación y Estado)          │
└─────────────┬───────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────┐
│          WeatherService                 │
│      (Lógica de Negocio Pura)           │
└─────────────┬───────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────┐
│       Módulos Especializados            │
│  • TemperatureConverter                 │
│  • Controllers (FindCities, etc.)       │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│          LiveComponents                 │
│  • CitySearchComponent                  │
│  • WeatherDisplayComponent              │
│  • FavoriteCitiesComponent              │
│  • TemperatureFormatComponent           │
└─────────────────────────────────────────┘
```

### Principios Aplicados

1. **Single Responsibility Principle**: Cada módulo tiene una única razón para cambiar
2. **Dependency Inversion**: LiveView depende de abstracciones (Service), no de implementaciones
3. **Open/Closed Principle**: Fácil agregar nuevos componentes sin modificar existentes
4. **Composition over Inheritance**: Componentes combinables y reutilizables

### Componentes de la Arquitectura

#### 1. **LiveView Principal** (`weather_live.ex`)
- **Responsabilidad**: Coordinación y manejo del estado global
- **Funciones**: Routing de eventos, composición de componentes

#### 2. **WeatherService** (`weather_service.ex`)
- **Responsabilidad**: Lógica de negocio pura
- **Funciones**: Operaciones CRUD, validaciones, transformaciones
- **Ventaja**: Completamente testeable, sin dependencias de Phoenix

#### 3. **LiveComponents Especializados**
- **CitySearchComponent**: UI y eventos de búsqueda
- **WeatherDisplayComponent**: Presentación de datos climáticos  
- **FavoriteCitiesComponent**: Gestión de ciudades favoritas
- **TemperatureFormatComponent**: Selector de formato de temperatura

#### 4. **Módulos Utilitarios**
- **TemperatureConverter**: Conversiones matemáticas puras
- **Reutilizable**: Puede usarse fuera del contexto web

## Trade-offs de la Implementación

### ✅ Ventajas

1. **Mantenibilidad Extrema**
   - Cambios aislados por funcionalidad
   - Debugging simplificado

2. **Testabilidad Completa**
   - Service layer sin dependencias Phoenix
   - Componentes testeables individualmente
   - Funciones puras fáciles de validar

3. **Escalabilidad**
   - Agregar funcionalidades no afecta código existente
   - Reutilización real de componentes

4. **Performance**
   - Re-renderizado granular por componente
   - Estado optimizado sin re-cálculos innecesarios

### ⚠️ Desventajas

1. **Complejidad Inicial**
   - Más archivos para mantener
   - Setup inicial más elaborado

2. **Overhead de Comunicación**
   - Mensajes entre componentes y LiveView
   - Indirección en el flujo de datos

3. **Coordinación de Estado**
   - Estado distribuido entre componentes
   - Sincronización manual requerida
   - Posibles inconsistencias si no se maneja bien

## Mejoras con Más Tiempo

1. **Error Handling Robusto**
2. **Cache**
3. **Telemetría**
4. **Loggers Estructurados**

## Conclusión

Esta arquitectura establece una base **modular y escalable** para la aplicación, siguiendo principios SOLID y patrones probados de Phoenix LiveView. Aunque introduce una complejidad inicial, los beneficios a largo plazo en mantenibilidad, testabilidad y escalabilidad justifican ampliamente la inversión.

La arquitectura está preparada para soportar el crecimiento futuro y facilita el desarrollo colaborativo manteniendo alta calidad de código.

## Instalación y Ejecución con Docker Compose

Para levantar la aplicación usando Docker Compose, sigue estos pasos:

1.  **Clonar el Repositorio:**
    ```bash
    git clone https://github.com/maudelv/weather_app
    cd weather_app
    ```

2.  **Configurar Variables de Entorno:**
    Copia el archivo de ejemplo y edita las variables necesarias (ej. claves de API):
    ```bash
    cp .env.template .env
    ```

3.  **Levantar Servicios con Docker Compose:**
    ```bash
    docker-compose up --build
    ```
    Esto construirá las imágenes de Docker y levantará los contenedores de la aplicación y la base de datos.

4.  **Acceder a la Aplicación:**
    Una vez que los servicios estén levantados, la aplicación estará disponible en [`localhost:4000`](http://localhost:4000).

5.  **Ejecutar Migraciones de Base de Datos (si es necesario):**
    Si hay nuevas migraciones de base de datos, puedes ejecutarlas dentro del contenedor de la aplicación:
    ```bash
    docker-compose exec app mix ecto.migrate
    ```

## Para Detener y Limpiar

Para detener los servicios y remover los contenedores, redes y volúmenes creados por `docker-compose`:
```bash
docker-compose down
