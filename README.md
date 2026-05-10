# 📘 Game Backlog - Manual del Proyecto

Bienvenido a la documentación oficial de **Game Backlog**. Esta aplicación está diseñada para ayudar a los jugadores a gestionar su colección, rastrear su progreso, compartir reseñas con la comunidad y mantener un diario de juego detallado.

---

## 🌟 Descripción del Proyecto

**Game Backlog** es una aplicación multiplataforma (Windows & Android) desarrollada en Flutter, respaldada por una robusta arquitectura en la nube mediante **Supabase (PostgreSQL)**. 

### Características Principales
*   **Sincronización en la Nube**: Tus datos están seguros y sincronizados en tiempo real en todos tus dispositivos gracias a Supabase.
*   **Gestión de Backlog**: Organiza tus juegos por estado (Jugando, Pendiente, Completado, Abandonado, En Pausa).
*   **Comunidad y Reseñas**: Explora el feed de la comunidad, lee reseñas de otros usuarios, da "Likes" y marca reseñas con alertas de *spoiler*.
*   **Integración IGDB (Twitch)**: Búsqueda automática de carátulas, fechas, géneros y plataformas con la API oficial de IGDB.
*   **Diario de Juego y Estadísticas**: Registra sesiones diarias, visualiza tu tiempo total de juego y analiza tus hábitos mediante gráficos.
*   **Listas Personalizadas**: Crea colecciones (ej. "Favoritos de PS5", "Juegos de terror") y añade tus juegos.

---

## 🛠️ Tecnologías Utilizadas

El proyecto se construye sobre un stack moderno orientado a la escalabilidad y seguridad:

*   **Frontend**: Flutter (Dart)
*   **Backend as a Service (BaaS)**: Supabase
*   **Base de Datos**: PostgreSQL (con políticas de seguridad RLS - Row Level Security)
*   **Autenticación**: Supabase Auth (Sesiones seguras, JWT)
*   **Arquitectura**: Clean Architecture (Domain, Data, Presentation)
*   **Gestión de Estado**: Provider
*   **Navegación**: GoRouter
*   **Red**: HTTP & flutter_dotenv (Consumo seguro de APIs)

### Estructura del Proyecto

A continuación se detalla la estructura principal del código fuente (`lib/`) y la configuración de entorno:

```text
.env.example                    # Plantilla con las variables de entorno necesarias
lib/
├── core/                       # Núcleo y configuración global de la aplicación
│   ├── config/                 # Variables de entorno y configuración inicial
│   ├── constants/              # Cadenas de texto estáticas y valores predefinidos
│   ├── errors/                 # Clases personalizadas para manejo de excepciones
│   ├── theme/                  # Sistema de diseño: Colores, tipografías y temas
│   ├── utils/                  # Funciones de ayuda (formateo de fechas, validadores de texto)
│   └── widgets/                # Componentes visuales genéricos y reutilizables (Botones, Inputs)
│
├── data/                       # Capa de Datos: Conexión con el exterior (Supabase e IGDB)
│   ├── datasources/            # Orígenes de datos
│   │   ├── local/              # (Legacy) Implementaciones antiguas de SQLite
│   │   └── supabase/           # Implementaciones de consultas a PostgreSQL vía Supabase
│   ├── models/                 # Modelos de datos (Clases DTO con métodos fromJson/toJson)
│   ├── repositories/           # Implementación real de los repositorios definidos en Dominio
│   └── services/               # Servicios externos (Ej: `igdb_service.dart` para consumir la API de Twitch)
│
├── domain/                     # Capa de Dominio: Reglas de negocio puras (Agnóstica de Flutter)
│   ├── entities/               # Objetos principales (User, Game, Review, Session)
│   ├── repositories/           # Contratos/Interfaces abstractas que la capa `data` debe cumplir
│   └── usecases/               # Lógica de las acciones principales de la app
│
├── presentation/               # Capa de Presentación: UI y gestión de estado
│   ├── providers/              # Controladores de estado (ChangeNotifier) que alimentan la UI
│   ├── screens/                # Pantallas principales agrupadas por funcionalidad
│   │   ├── api_test/           # Pantalla de pruebas interna
│   │   ├── auth/               # Flujos de Login, Registro y pantalla Splash
│   │   ├── backlog/            # Tu lista de juegos y filtros por estado
│   │   ├── community/          # Feed global con reseñas de todos los usuarios
│   │   ├── game_detail/        # Ficha completa del juego y edición de progreso
│   │   ├── journal/            # Registro de sesiones de juego y diario
│   │   ├── profile/            # Perfil de usuario y estadísticas avanzadas
│   │   └── search/             # Búsqueda de juegos consumiendo la API de IGDB
│   └── widgets/                # Componentes visuales específicos (Ej: Tarjetas de juego, Avatares)
│
└── routes/                     # Enrutador principal de la app usando GoRouter
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
    git clone https://github.com/Jacobo-Dominguez/GameBacklog.git
    cd gamebacklog
    ```

2.  **Configurar Variables de Entorno (.env)**:
    El proyecto utiliza variables de entorno para proteger las credenciales de la base de datos y la API. Debes renombrar el archivo `.env.example` que viene en el proyecto a `.env` y rellenar los datos:
    ```env
    SUPABASE_URL=tu_url_de_supabase
    SUPABASE_ANON_KEY=tu_anon_key_de_supabase
    IGDB_CLIENT_ID=tu_client_id_de_twitch
    IGDB_CLIENT_SECRET=tu_client_secret_de_twitch
    ```

3.  **Instalar dependencias**:
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
        1. Instala Android Studio y configura un emulador o conecta tu móvil con depuración USB.
        2. Ejecuta el siguiente comando:
        ```bash
        flutter run -d <id-dispositivo>
        ```
    *   **Web (Navegador)**:
        No requiere instalación adicional, solo tener Chrome o Edge.
        **IMPORTANTE para Web**: Para que la búsqueda de IGDB funcione, debes activar el proxy de CORS visitando [cors-anywhere.herokuapp.com/corsdemo](https://cors-anywhere.herokuapp.com/corsdemo) y pulsando el botón "Request temporary access".
        ```bash
        flutter run -d chrome
        # O para Edge
        flutter run -d edge
        ```

> 🎁 **Nota para evaluación**: En la entrega del proyecto se proporciona un archivo `.exe` precompilado. Este ejecutable ya lleva empaquetadas las credenciales del `.env`, permitiendo probar la aplicación inmediatamente en cualquier PC con Windows sin necesidad de instalar ni configurar Flutter.

---

## 🗄️ Base de Datos (Supabase / PostgreSQL)

La aplicación ha migrado de una base de datos local a una arquitectura en la nube (BaaS) utilizando **Supabase**, lo cual nos proporciona una base de datos **PostgreSQL** robusta y accesible desde cualquier dispositivo.

### Esquema y Sentencias SQL

A diferencia de un esquema local, en Supabase la seguridad y relaciones se manejan a nivel de servidor. La tabla `profiles` está enlazada mediante un *Trigger* automático al sistema de Autenticación (`auth.users`) de Supabase.

A continuación se detalla el script SQL completo que conforma la base de datos de la aplicación:

```sql
-- 1. Tabla de perfiles (extiende auth.users de Supabase)
CREATE TABLE profiles (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  username TEXT UNIQUE NOT NULL,
  avatar_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Tabla de juegos (compartida entre todos los usuarios)
CREATE TABLE games (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  platform TEXT,
  genre TEXT,
  release_date TIMESTAMPTZ,
  cover_url TEXT,
  description TEXT,
  remote_id INTEGER,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  user_id UUID REFERENCES auth.users(id)
);

-- 3. Backlog de cada usuario
CREATE TABLE game_backlog (
  id TEXT PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  game_id TEXT REFERENCES games(id) ON DELETE CASCADE NOT NULL,
  status TEXT CHECK(status IN ('playing','completed','pending','dropped','on_hold')) NOT NULL,
  hours_played INTEGER DEFAULT 0,
  rating INTEGER CHECK(rating >= 0 AND rating <= 10),
  notes TEXT,
  is_favorite BOOLEAN DEFAULT FALSE,
  review_title TEXT,
  is_spoiler BOOLEAN DEFAULT FALSE,
  start_date TIMESTAMPTZ,
  end_date TIMESTAMPTZ,
  added_date TIMESTAMPTZ NOT NULL,
  completed_date TIMESTAMPTZ,
  last_updated TIMESTAMPTZ NOT NULL,
  UNIQUE(user_id, game_id)
);

-- 4. Sesiones de juego (Diario)
CREATE TABLE game_sessions (
  id TEXT PRIMARY KEY,
  game_id TEXT REFERENCES games(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  session_date TIMESTAMPTZ NOT NULL,
  duration_minutes INTEGER NOT NULL,
  description TEXT
);

-- 5. Listas personalizadas
CREATE TABLE game_lists (
  id TEXT PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  name TEXT NOT NULL,
  description TEXT,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL
);

-- 6. Items de listas personalizadas
CREATE TABLE game_list_items (
  id TEXT PRIMARY KEY,
  list_id TEXT REFERENCES game_lists(id) ON DELETE CASCADE NOT NULL,
  game_id TEXT REFERENCES games(id) ON DELETE CASCADE NOT NULL,
  added_at TIMESTAMPTZ NOT NULL,
  UNIQUE(list_id, game_id)
);

-- 7. Reseñas de usuario (Comunidad)
CREATE TABLE user_reviews (
  id TEXT PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  game_id TEXT REFERENCES games(id) ON DELETE CASCADE NOT NULL,
  title TEXT,
  content TEXT,
  rating INTEGER,
  is_spoiler BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 8. Likes de reseñas (Comunidad)
CREATE TABLE review_likes (
  id TEXT PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  review_id TEXT REFERENCES user_reviews(id) ON DELETE CASCADE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, review_id)
);
```

---

**Autor**: Jacobo Luis Dominguez Morales