# 📘 Game Backlog - Manual del Proyecto

Bienvenido a la documentación oficial de **Game Backlog**. Esta aplicación está diseñada para ayudar a los jugadores a gestionar su colección, rastrear su progreso y mantener un diario de juego detallado.

---

## 🌟 Descripción del Proyecto

**Game Backlog** es una aplicación multiplataforma (Android & Windows) desarrollada en Flutter. Su objetivo es reemplazar las hojas de cálculo y notas dispersas con una experiencia unificada y moderna.

### Características Principales
*   **Gestión de Backlog**: Organiza tus juegos por estado (Jugando, Pendiente, Completado, Abandonado).
*   **Integración IGDB**: Búsqueda automática de carátulas, fechas y metadatos de juegos.
*   **Diario de Juego**: Registra sesiones diarias, duración y notas de progreso.
*   **Estadísticas**: Visualiza tu tiempo total de juego y hábitos.
*   **Offline-First**: Tus datos viven en tu dispositivo. No requiere internet para funcionar (excepto búsquedas nuevas).
*   **Modo Oscuro/Claro**: Adaptable a tus preferencias del sistema.

---

## 🛠️ Tecnologías Utilizadas

El proyecto se construye sobre un stack moderno y robusto:

*   **Frontend**: Flutter (Dart)
*   **Arquitectura**: Clean Architecture (Domain, Data, Presentation)
*   **Base de Datos**: SQLite (sqflite / sqflite_common_ffi)
*   **Gestión de Estado**: Provider
*   **Navegación**: GoRouter
*   **Red**: HTTP & Dio (Consumo API IGDB)
*   **UI**: Material Design 3

### Estructura del Proyecto

A continuación se detalla la estructura completa de carpetas del código fuente (`lib/`):

```
lib/
├── core/                       # Núcleo de la aplicación
│   ├── config/                 # Configuraciones globales (env, constantes)
│   ├── constants/              # Textos y valores estáticos
│   ├── errors/                 # Definición de excepciones y fallos
│   ├── theme/                  # Estilos, colores y temas (Claro/Oscuro)
│   ├── utils/                  # Funciones de utilidad (fechas, validadores)
│   └── widgets/                # Widgets genéricos reutilizables (Inputs, Botones)
│
├── data/                       # Capa de Datos (Implementación)
│   ├── datasources/            # Fuentes de datos (SQLite, API remota)
│   ├── models/                 # Modelos de datos (DTOs con parseo JSON)
│   ├── repositories/           # Implementación concreta de los repositorios
│   └── services/               # Servicios externos (IGDB Service)
│
├── domain/                     # Capa de Dominio (Lógica de Negocio Pura)
│   ├── entities/               # Objetos de negocio fundamentales
│   ├── repositories/           # Contratos (Interfaces) de los repositorios
│   └── usecases/               # Casos de uso específicos (p.ej. "Añadir Juego")
│
├── presentation/               # Capa de Presentación (UI)
│   ├── providers/              # Gestión de estado (ChangeNotifier)
│   ├── screens/                # Pantallas principales
│   │   ├── api_test/           # Pantalla de prueba de API
│   │   ├── auth/               # Login, Registro y Splash
│   │   ├── backlog/            # Lista principal y filtros
│   │   ├── game_detail/        # Detalle del juego y edición
│   │   ├── journal/            # Diario y calendario
│   │   ├── profile/            # Perfil de usuario y estadísticas
│   │   └── search/             # Búsqueda online de juegos
│   └── widgets/                # Widgets específicos de dominio
│
└── routes/                     # Configuración de rutas (GoRouter)
```

---

## ⚙️ Instalación y Configuración

### Requisitos Previos
1.  **Flutter SDK**: Versión 3.0+ instalada y en el PATH.
2.  **Editor**: VS Code (recomendado) o Android Studio.
3.  **Para Windows**: Visual Studio 2022 con carga de trabajo "Desarrollo de escritorio con C++".
4.  **Para Android**: Android SDK y un emulador o dispositivo físico.

### Pasos de Instalación

1.  **Clonar el repositorio**:
    ```bash
    git clone https://github.com/tu-usuario/gamebacklog.git
    cd gamebacklog
    ```

2.  **Instalar dependencias**:
    ```bash
    flutter pub get
    ```

3.  **Configurar FFI (Solo Windows/Linux)**:
    La aplicación usa `sqflite_common_ffi`. Asegúrate de estar en un entorno compatible.

4.  **Ejecutar la aplicación**:
    *   **Windows**:
        ```bash
        flutter run -d windows
        ```
    *   **Android**:
        ```bash
        flutter run -d <id-dispositivo>
        ```

---

## 🗄️ Base de Datos

La aplicación utiliza una base de datos relacional local (SQLite).

### Esquema y Sentencias SQL

A continuación se detallan las sentencias `CREATE TABLE` utilizadas para generar la estructura de datos:

#### 1. Usuarios (`users`)
Almacena la información de autenticación local.
```sql
CREATE TABLE users (
  id TEXT PRIMARY KEY,
  username TEXT UNIQUE,
  email TEXT UNIQUE,
  password_hash TEXT,
  avatar_url TEXT,
  created_at TEXT
);
```

#### 2. Juegos (`games`)
Catálogo de juegos (datos estáticos obtenidos de IGDB o creados manualmente).
```sql
CREATE TABLE games (
  id TEXT PRIMARY KEY,
  title TEXT,
  platform TEXT,
  genre TEXT,
  releaseDate TEXT,
  coverUrl TEXT,
  description TEXT,
  remoteId INTEGER,
  createdAt TEXT,
  updatedAt TEXT,
  userId TEXT
);
```

#### 3. Backlog (`game_backlog`)
Relación principal que vincula un usuario con un juego y su estado.
```sql
CREATE TABLE game_backlog (
  id TEXT PRIMARY KEY,
  user_id TEXT,
  game_id TEXT,
  status TEXT CHECK(status IN ('playing', 'completed', 'pending', 'dropped', 'on_hold')),
  hours_played INTEGER DEFAULT 0,
  rating INTEGER CHECK(rating >= 0 AND rating <= 10),
  notes TEXT,
  is_favorite INTEGER DEFAULT 0,
  review_title TEXT,
  is_spoiler INTEGER DEFAULT 0,
  start_date TEXT,
  end_date TEXT,
  added_date TEXT,
  completed_date TEXT,
  last_updated TEXT,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (game_id) REFERENCES games(id) ON DELETE CASCADE,
  UNIQUE(user_id, game_id)
);
```

#### 4. Sesiones de Juego (`game_sessions`)
Registro detallado del diario de juego (Fase 13).
```sql
CREATE TABLE game_sessions (
  id TEXT PRIMARY KEY,
  game_id TEXT,
  user_id TEXT,
  session_date TEXT,
  duration_minutes INTEGER,
  description TEXT,
  FOREIGN KEY (game_id) REFERENCES games(id) ON DELETE CASCADE,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
```

---

**Autor**: Jacobo Luis Dominguez Morales