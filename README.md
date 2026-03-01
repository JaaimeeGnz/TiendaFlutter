# JGMarket Flutter - Migración desde Astro

##  Descripción

Este es el proyecto **JGMarket** migrado de **Astro** a **Flutter**, manteniendo exactamente la misma base de datos Supabase, las mismas APIs externas y la misma lógica de negocio.

##  Características Implementadas

-  Autenticación con Supabase (Login/Registro)
-  Catálogo de productos
-  Búsqueda de productos
-  Detalle de producto
-  Carrito de compras (persistente)
-  Gestión de cantidades y tallas
-  Productos destacados y en oferta
-  Categorías de productos
-  Integración con Cloudinary (imágenes)
-  Tema JD Sports (colores y estilos)
-  Navegación completa
-  Pasarela de pago Stripe (configurada, pendiente backend)
-  Panel administrativo (pendiente)

##  Tecnologías Utilizadas

### Backend & Base de Datos
- **Supabase**: PostgreSQL + Auth + Storage
- **Cloudinary**: Gestión de imágenes
- **Stripe**: Pagos (configurado)
- **Brevo**: Emails (configurado)

### Frontend (Flutter)
- **Provider**: Gestión de estado
- **Supabase Flutter**: Cliente para Supabase
- **Flutter Stripe**: Integración de pagos
- **Cloudinary Public**: Subida de imágenes
- **Shared Preferences**: Almacenamiento local
- **Cached Network Image**: Caché de imágenes
- **Intl**: Formateo de números y fechas

##  Estructura del Proyecto

```
lib/
 core/
    constants/
       app_config.dart           # Configuración de APIs
    theme/
       app_theme.dart            # Tema JD Sports
    utils/
        format_utils.dart         # Utilidades de formato

 models/
    product.dart                  # Modelo de producto
    category.dart                 # Modelo de categoría
    cart_item.dart                # Modelo de item del carrito
    address.dart                  # Modelo de dirección
    order.dart                    # Modelo de pedido
    user_model.dart               # Modelo de usuario

 services/
    supabase_service.dart         # Servicio de Supabase
    product_service.dart          # Servicio de productos
    category_service.dart         # Servicio de categorías
    order_service.dart            # Servicio de pedidos y direcciones
    cloudinary_service.dart       # Servicio de Cloudinary
    stripe_service.dart           # Servicio de Stripe

 providers/
    auth_provider.dart            # Provider de autenticación
    cart_provider.dart            # Provider del carrito
    product_provider.dart         # Provider de productos

 screens/
    home/
       home_screen.dart          # Pantalla principal
    auth/
       login_screen.dart         # Login/Registro
    products/
       product_list_screen.dart  # Lista de productos
       product_detail_screen.dart # Detalle de producto
    cart/
       cart_screen.dart          # Carrito de compras
    account/
        account_screen.dart       # Cuenta del usuario

 widgets/
    product_card.dart             # Tarjeta de producto
    app_drawer.dart               # Menú lateral

 main.dart                         # Punto de entrada
```

##  Instalación y Ejecución

### Requisitos Previos

- Flutter SDK (>=3.0.0)
- Dart SDK (>=3.0.0)
- Android Studio / VS Code
- Emulador o dispositivo físico

### Pasos de Instalación

1. **Clonar o ubicar el proyecto**
   ```bash
   cd C:\Users\jaime\Desktop\jgmarket_flutter
   ```

2. **Instalar dependencias**
   ```bash
   flutter pub get
   ```

3. **Verificar el archivo .env**
   - El archivo `.env` ya está configurado con las credenciales correctas
   -  **IMPORTANTE**: Este archivo contiene las credenciales reales de producción

4. **Ejecutar el proyecto**
   
   **Para Android:**
   ```bash
   flutter run
   ```

   **Para Windows:**
   ```bash
   flutter run -d windows
   ```

   **Para Chrome (Web):**
   ```bash
   flutter run -d chrome
   ```

### Comandos Útiles

```bash
# Ver dispositivos disponibles
flutter devices

# Limpiar build
flutter clean
flutter pub get

# Generar código Hive (si es necesario)
flutter pub run build_runner build --delete-conflicting-outputs

# Analizar código
flutter analyze

# Ver logs
flutter logs
```

##  Variables de Entorno

El archivo `.env` ya está configurado con:

```env
# Supabase
SUPABASE_URL=https://pygrobxheswyltsgyzfd.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

# Cloudinary
CLOUDINARY_CLOUD_NAME=tu_cloud_name
CLOUDINARY_API_KEY=tu_api_key
CLOUDINARY_API_SECRET=tu_api_secret

# Stripe
STRIPE_PUBLIC_KEY=tu_stripe_public_key
STRIPE_SECRET_KEY=tu_stripe_secret_key

# Brevo (Email)
BREVO_API_KEY=tu_brevo_api_key
```

##  Base de Datos

### Tablas de Supabase (Existentes)

1. **categories** - Categorías de productos
2. **products** - Productos de la tienda
3. **addresses** - Direcciones de envío
4. **orders** - Pedidos de los usuarios

 **IMPORTANTE**: La base de datos NO ha sido modificada. Ambos proyectos (Astro y Flutter) usan exactamente la misma base de datos.

##  Tema y Diseño

El diseño mantiene el estilo **JD Sports**:

- **Negro** (#000000) - Principal
- **Rojo** (#DC2626) - Acentos y ofertas
- **Turquesa** (#14B8A6) - Botones y destacados
- **Gris** (#F3F4F6) - Fondo

##  Funcionalidades por Pantalla

### Home Screen
- Banner hero con llamado a la acción
- Grid de categorías
- Productos destacados
- Productos en oferta
- Navegación rápida

### Product List Screen
- Búsqueda en tiempo real
- Grid de productos
- Pull to refresh
- Navegación al detalle

### Product Detail Screen
- Galería de imágenes
- Información completa del producto
- Selector de talla
- Selector de cantidad
- Stock disponible
- Añadir al carrito

### Cart Screen
- Lista de items
- Modificar cantidades
- Eliminar items
- Resumen de compra
- Botón de checkout (pendiente implementación completa)

### Login Screen
- Login con email/password
- Registro de nuevos usuarios
- Continuar como invitado
- Validaciones de formulario

### Account Screen
- Perfil del usuario
- Mis pedidos (pendiente)
- Direcciones (pendiente)
- Favoritos (pendiente)
- Cerrar sesión

##  Funciones Pendientes

1. **Stripe Checkout completo**
   - Requiere endpoint backend para crear PaymentIntent
   - La configuración está lista

2. **Panel Administrativo**
   - Gestión de productos
   - Gestión de pedidos
   - Estadísticas

3. **Gestión de direcciones**
   - CRUD completo de direcciones
   - Selección de dirección en checkout

4. **Historial de pedidos**
   - Ver pedidos anteriores
   - Detalles de cada pedido

5. **Sistema de favoritos**
   - Guardar productos favoritos
   - Ver lista de favoritos

##  Solución de Problemas

### Error: "DotEnv not initialized"
```bash
# Asegúrate de que el archivo .env existe en la raíz del proyecto
# Ejecuta: flutter clean && flutter pub get
```

### Error: "Supabase not initialized"
```bash
# Verifica las credenciales en .env
# Verifica tu conexión a internet
```

### Error de compilación
```bash
flutter clean
flutter pub get
flutter run
```

##  Licencia

Este proyecto es una migración de tienda online con fines educativos y de demostración.

##  Migración

Proyecto original: **Astro + React + Tailwind**  
Migrado a: **Flutter**  
Base de datos: **Supabase (sin modificaciones)**  
Fecha: Enero 2026

---

**¿Necesitas ayuda?** Revisa los logs con `flutter logs` o contacta al equipo de desarrollo.
