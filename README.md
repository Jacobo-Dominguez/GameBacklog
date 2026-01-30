# 🎮 Game Backlog

Una aplicación multiplataforma desarrollada en Flutter para gestionar tu backlog de videojuegos. Funciona en **Android** y **Windows** desde un único código base.

![Flutter](https://img.shields.io/badge/Flutter-3.38.7-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?logo=dart)
![SQLite](https://img.shields.io/badge/SQLite-Local-003B57?logo=sqlite)

---

## 📋 Descripción del Proyecto

**Game Backlog** es una aplicación tipo Backloggd que permite a los usuarios:
- 📚 Gestionar su colección de videojuegos
- 🎯 Hacer seguimiento del progreso (jugando, completado, pendiente, etc.)
- ⏱️ Registrar horas jugadas
- ⭐ Calificar juegos
- 📝 Agregar notas personales
- 📊 Ver estadísticas de su backlog

---

## 🏗️ Arquitectura

El proyecto sigue los principios de **Clean Architecture** con separación clara de responsabilidades:

```
game_backlog/
├── lib/
│   ├── core/                    # Código compartido entre capas
│   │   ├── constants/           # Constantes globales
│   │   ├── errors/              # Manejo de errores
│   │   ├── theme/               # Tema y estilos
│   │   ├── utils/               # Utilidades y helpers
│   │   └── widgets/             # Widgets reutilizables
│   │
│   ├── data/                    # Capa de datos
│   │   ├── datasources/         # Fuentes de datos (local/remoto)
│   │   ├── models/              # Modelos de datos (DTOs)
│   │   └── repositories/        # Implementación de repositorios
│   │
│   ├── domain/                  # Lógica de negocio
│   │   ├── entities/            # Entidades del dominio
│   │   ├── repositories/        # Interfaces de repositorios
│   │   └── usecases/            # Casos de uso
│   │
│   ├── 📂 presentation/      # Capa de Presentación
│   │   ├── screens/          # Pantallas de la app
│   │   ├── widgets/          # Widgets de UI
│   │   └── providers/        # Gestión de estado (Provider)
│   │
│   └── 📂 routes/            # Configuración de navegación
│
└── 📂 assets/                # Recursos estáticos
```

### Capas de la Arquitectura

#### 🔵 **Domain (Dominio)**
- **Entidades**: Objetos puros del negocio (`User`, `Game`, `GameBacklogEntry`)
- **Repositorios**: Interfaces que definen contratos de datos
- **Casos de Uso**: Lógica de negocio específica

#### 🟢 **Data (Datos)**
- **Models**: Extensión de entidades con serialización JSON
- **DataSources**: Implementaciones concretas (SQLite)
- **Repositories**: Implementación de interfaces del dominio

#### 🔴 **Presentation (Presentación)**
- **Screens**: Pantallas completas de la aplicación
- **Widgets**: Componentes de UI reutilizables
- **Providers**: Gestión de estado con Provider

---

## 🗄️ Base de Datos

### Esquema SQLite

La aplicación utiliza **SQLite** para almacenamiento local persistente.

#### Tabla `users`
```sql
CREATE TABLE users (
  id TEXT PRIMARY KEY,
  username TEXT NOT NULL UNIQUE,
  email TEXT NOT NULL UNIQUE,
  password_hash TEXT NOT NULL,
  avatar_url TEXT,
  created_at TEXT NOT NULL
)
```

#### Tabla `games`
```sql
CREATE TABLE games (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  cover_url TEXT,
  description TEXT,
  platform TEXT,
  genre TEXT,
  release_year INTEGER,
  created_at TEXT NOT NULL
)
```

#### Tabla `game_backlog`
```sql
CREATE TABLE game_backlog (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  game_id TEXT NOT NULL,
  status TEXT CHECK(status IN ('playing', 'completed', 'pending', 'dropped', 'on_hold')),
  hours_played INTEGER DEFAULT 0,
  rating INTEGER CHECK(rating >= 0 AND rating <= 10),
  notes TEXT,
  added_date TEXT NOT NULL,
  completed_date TEXT,
  last_updated TEXT NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (game_id) REFERENCES games(id) ON DELETE CASCADE,
  UNIQUE(user_id, game_id)
)
```

### Operaciones CRUD Implementadas

✅ **Usuarios**: Crear, leer, actualizar, eliminar  
✅ **Juegos**: CRUD completo + búsqueda por título  
✅ **Backlog**: CRUD + filtrado por estado + estadísticas  

---

## 📦 Dependencias Principales

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Gestión de estado
  provider: ^6.1.1
  
  # Base de datos local
  sqflite: ^2.3.0
  sqflite_common_ffi: ^2.3.0  # Soporte para Windows/Linux
  path_provider: ^2.1.1
  path: ^1.8.3
  
  # Navegación
  go_router: ^13.0.0
  
  # UI
  google_fonts: ^6.1.0
  
  # Utilidades
  uuid: ^4.2.1
  intl: ^0.18.1
  
  # Autenticación
  crypto: ^3.0.3              # Encriptación de contraseñas
  shared_preferences: ^2.2.2  # Persistencia de sesión

  # Red e Imágenes
  http: ^1.1.0                # Peticiones API
  cached_network_image: ^3.3.0 # Caché de imágenes
```

---

## 🚀 Instalación y Configuración

### Requisitos Previos

- **Flutter SDK** 3.0 o superior
- **Dart** 3.0 o superior
- **Android Studio** (para desarrollo móvil)
- **Visual Studio** con C++ (para desarrollo Windows)
- **VS Code** con extensiones de Flutter y Dart

### Pasos de Instalación

1. **Clonar el repositorio**
   ```bash
   git clone <repository-url>
   cd gamebacklog
   ```

2. **Instalar dependencias**
   ```bash
   flutter pub get
   ```

3. **Verificar configuración**
   ```bash
   flutter doctor -v
   ```

4. **Habilitar plataforma Windows** (si no está habilitada)
   ```bash
   flutter config --enable-windows-desktop
   ```

5. **Activar Modo de Desarrollador en Windows**
   - Abre **Configuración de Windows**
   - Ve a **Privacidad y seguridad > Para desarrolladores**
   - Activa **Modo de desarrollador**

---

## 🧪 Probar la Aplicación

### Probar Autenticación (Fase 4)

La aplicación ahora incluye un sistema completo de autenticación:

```bash
flutter run -d windows
```

**Funcionalidades disponibles:**
1. **Registro de usuarios**
   - Crea una cuenta con username, email y contraseña
   - Validación de formularios
   - Contraseñas encriptadas con SHA-256

2. **Login**
   - Inicia sesión con email y contraseña
   - Sesión persistente entre reinicios

3. **Logout**
   - Cierra sesión desde el botón en la barra superior

**Prueba el flujo completo:**
- Registra un usuario nuevo
- Cierra la app y vuelve a abrirla (debería mantener la sesión)
- Cierra sesión
- Inicia sesión con las mismas credenciales

---

## 📱 Ejecutar la Aplicación

### En Windows
```bash
flutter run -d windows
```

### En Android (con emulador iniciado)
```bash
flutter run -d <nombre-emulador>
```

### Listar dispositivos disponibles
```bash
flutter devices
```

---

## 🎯 Estado del Proyecto

### ✅ Fases Completadas

#### **Fase 1: Preparación del Entorno**
- ✅ Instalación de Flutter SDK
- ✅ Configuración de Android Studio
- ✅ Configuración de Visual Studio para Windows
- ✅ Configuración de VS Code
- ✅ Verificación con `flutter doctor`

#### **Fase 2: Estructura del Proyecto**
- ✅ Creación del proyecto Flutter
- ✅ Estructura de carpetas con Clean Architecture
- ✅ Configuración de dependencias
- ✅ Organización de assets

#### **Fase 3: Base de Datos Local**
- ✅ Diseño del esquema de base de datos
- ✅ Implementación de DatabaseHelper
- ✅ Creación de entidades del dominio
- ✅ Modelos de datos con serialización JSON
- ✅ Data sources con CRUD completo
- ✅ Script de pruebas funcional
- ✅ Soporte para Windows con sqflite_common_ffi

#### **Fase 4: Autenticación** 
- ✅ Pantalla de login con validación
- ✅ Pantalla de registro con validación
- ✅ Encriptación de contraseñas (SHA-256)
- ✅ Gestión de sesión con SharedPreferences
- ✅ Persistencia de sesión entre reinicios
- ✅ Provider para gestión de estado
- ✅ Manejo de errores y estados de carga
- ✅ Validación de formularios

#### **Fase 5: Navegación y UI**
- ✅ Configuración de GoRouter con rutas protegidas
- ✅ Pantalla de perfil de usuario
- ✅ Diseño adaptativo móvil/escritorio (NavigationRail/BottomNavigationBar)
- ✅ Implementación de tabs y stack de navegación

#### **Fase 6: Gestión del Backlog**
- ✅ CRUD completo en la interfaz principal
- ✅ Tarjetas de juego interactivas con menús contextuales
- ✅ Lógica de negocio (BacklogProvider)

#### **Fase 7: Funcionalidades Avanzadas**
- ✅ Filtros por estado (Jugando, Completado, etc.)
- ✅ Búsqueda local en el backlog
- ✅ Estadísticas y conteo de horas

#### **Fase 8: Refactorización y Pruebas**
- ✅ Tests unitarios para Providers y Modelos
- ✅ Tests de widgets
- ✅ Limpieza de código y mejores prácticas

#### **Fase 9: Pulido Final (MVP)**
- ✅ Iconos y assets personalizados
- ✅ Verificación de flujos completos
- ✅ Modo release

#### **Fase 10: Integración API RAWG** 
- ✅ Búsqueda online de videojuegos
- ✅ Visualización de portadas artísticas
- ✅ Sincronización de metadatos (fechas, plataformas)
- ✅ Experiencia de usuario híbrida (Offline/Online)

### ⏳ Próximas Fases
- [ ] Sistema de amigos y social
- [ ] Reseñas y comentarios detallados
- [ ] Integración con tiendas (Steam, Epic)

---

## 📚 Documentación Adicional

Para guías detalladas de cada fase, consulta:

- [Fase 1: Preparación del Entorno](docs/01_preparacion_entorno.md)
- [Fase 2: Estructura del Proyecto](docs/02_estructura_proyecto.md)
- [Fase 3: Base de Datos](docs/03_base_datos.md)
- [Fase 4: Autenticación](docs/04_autenticacion.md)
- [Fase 5: Navegación y UI](docs/05_navegacion_ui.md)

---

## 🛠️ Tecnologías Utilizadas

- **Flutter** - Framework multiplataforma
- **Dart** - Lenguaje de programación
- **SQLite** - Base de datos local
- **Provider** - Gestión de estado
- **GoRouter** - Navegación declarativa
- **Clean Architecture** - Patrón arquitectónico

---

## 👨‍💻 Desarrollo

### Estructura de Commits

Seguimos el formato de commits convencionales:

```
feat: nueva funcionalidad
fix: corrección de bug
docs: cambios en documentación
refactor: refactorización de código
test: agregar o modificar tests
```

### Testing

```bash
# Tests unitarios
flutter test

# Tests de widgets
flutter test test/widget/

# Tests de integración
flutter test test/integration/
```

---

## 📄 Licencia

Este proyecto es de código abierto y está disponible bajo la licencia MIT.

---

## 🤝 Contribuciones

Las contribuciones son bienvenidas. Por favor:

1. Fork el proyecto
2. Crea una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'feat: Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

---

## 📞 Contacto

Para preguntas o sugerencias, abre un issue en el repositorio.

---

**Desarrollado con ❤️ usando Flutter**