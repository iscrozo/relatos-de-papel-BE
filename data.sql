-- ============================================
-- Base de datos: Relatos de Papel
-- Sistema de microservicios para gestión de libros
-- Basado en diagram.pdf
-- ============================================

-- Eliminar tablas en orden correcto (por dependencias)
DROP TABLE IF EXISTS metodos_pago_usuarios;
DROP TABLE IF EXISTS lista_deseo;
DROP TABLE IF EXISTS libro_pedido;
DROP TABLE IF EXISTS pedidos;
DROP TABLE IF EXISTS carrito_libros;
DROP TABLE IF EXISTS carrito;
DROP TABLE IF EXISTS libros_autores;
DROP TABLE IF EXISTS payments;
DROP TABLE IF EXISTS books;
DROP TABLE IF EXISTS libros;
DROP TABLE IF EXISTS autores;
DROP TABLE IF EXISTS rol_x_usuarios;
DROP TABLE IF EXISTS usuarios;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS roles;
DROP TABLE IF EXISTS metodos_pago;

-- ============================================
-- TABLA: roles
-- Roles de usuario del sistema
-- ============================================
CREATE TABLE roles (
    id INT AUTO_INCREMENT PRIMARY KEY,
    descripcion_rol VARCHAR(50) NOT NULL UNIQUE
);

INSERT INTO roles (descripcion_rol) VALUES
('ADMIN'),
('USER'),
('MODERATOR'),
('GUEST');

-- ============================================
-- TABLA: usuarios
-- Usuarios completos del sistema
-- ============================================
CREATE TABLE usuarios (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre_completo VARCHAR(255) NOT NULL,
    nombre_usuario VARCHAR(100) NOT NULL UNIQUE,
    email VARCHAR(255) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    direccion VARCHAR(500),
    fecha_nacimiento DATE,
    numero_telefono VARCHAR(20),
    id_rol INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_usuarios_rol FOREIGN KEY (id_rol) REFERENCES roles(id)
);

CREATE INDEX idx_usuarios_email ON usuarios(email);
CREATE INDEX idx_usuarios_nombre_usuario ON usuarios(nombre_usuario);

INSERT INTO usuarios (nombre_completo, nombre_usuario, email, password, direccion, fecha_nacimiento, numero_telefono, id_rol) VALUES
('Juan Pérez García', 'juanperez', 'juan.perez@email.com', '$2a$10$hashedpassword1', 'Calle Principal 123, Madrid', '1990-05-15', '+34612345678', 2),
('María García López', 'mariagarcia', 'maria.garcia@email.com', '$2a$10$hashedpassword2', 'Avenida Central 456, Barcelona', '1985-08-22', '+34623456789', 2),
('Carlos López Martínez', 'carloslopez', 'carlos.lopez@email.com', '$2a$10$hashedpassword3', 'Plaza Mayor 789, Valencia', '1992-03-10', '+34634567890', 2),
('Ana Martínez Ruiz', 'anamartinez', 'ana.martinez@email.com', '$2a$10$hashedpassword4', 'Calle Secundaria 321, Sevilla', '1988-11-28', '+34645678901', 2),
('Admin Sistema', 'admin', 'admin@relatosdepapel.com', '$2a$10$hashedpassword5', 'Oficina Central', '1980-01-01', '+34600000000', 1);

-- ============================================
-- TABLA: users (versión simplificada)
-- Usuarios simplificados para autenticación
-- ============================================
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    role_id INT,
    active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_users_role FOREIGN KEY (role_id) REFERENCES roles(id)
);

INSERT INTO users (email, password, role_id, active) VALUES
('juan.perez@email.com', '$2a$10$hashedpassword1', 2, true),
('maria.garcia@email.com', '$2a$10$hashedpassword2', 2, true),
('admin@relatosdepapel.com', '$2a$10$hashedpassword5', 1, true);

-- ============================================
-- TABLA: rol_x_usuarios (relación N:M)
-- Relación muchos a muchos entre roles y usuarios
-- ============================================
CREATE TABLE rol_x_usuarios (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_rol INT NOT NULL,
    id_usuario INT NOT NULL,
    fecha_asignacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_rol_x_usuarios_rol FOREIGN KEY (id_rol) REFERENCES roles(id),
    CONSTRAINT fk_rol_x_usuarios_usuario FOREIGN KEY (id_usuario) REFERENCES usuarios(id),
    CONSTRAINT uk_rol_usuario UNIQUE (id_rol, id_usuario)
);

INSERT INTO rol_x_usuarios (id_rol, id_usuario) VALUES
(2, 1), (2, 2), (2, 3), (2, 4), (1, 5), (2, 5);

-- ============================================
-- TABLA: autores
-- Autores de libros
-- ============================================
CREATE TABLE autores (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre_completo VARCHAR(255) NOT NULL,
    nacionalidad VARCHAR(100),
    edad_epoca VARCHAR(100),
    corrientes_literarias VARCHAR(255),
    estilo_personal TEXT,
    formacion VARCHAR(255),
    popularidad VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

INSERT INTO autores (nombre_completo, nacionalidad, edad_epoca, corrientes_literarias, estilo_personal, formacion, popularidad) VALUES
('Gabriel García Márquez', 'Colombiano', 'Siglo XX', 'Realismo mágico', 'Narrativa envolvente con elementos fantásticos integrados en lo cotidiano', 'Periodismo y Derecho', 'Muy Alta'),
('Miguel de Cervantes', 'Español', 'Siglo de Oro', 'Renacimiento', 'Prosa innovadora, mezcla de géneros, ironía y humanismo', 'Autodidacta', 'Muy Alta'),
('George Orwell', 'Británico', 'Siglo XX', 'Distopía, Realismo social', 'Claridad, crítica social directa', 'Eton College', 'Muy Alta'),
('Carlos Ruiz Zafón', 'Español', 'Contemporáneo', 'Novela gótica, Misterio', 'Atmósferas envolventes, Barcelona como escenario', 'Publicidad', 'Alta'),
('Julio Cortázar', 'Argentino', 'Siglo XX', 'Boom latinoamericano', 'Experimental, juegos narrativos', 'Letras', 'Alta'),
('Antoine de Saint-Exupéry', 'Francés', 'Siglo XX', 'Literatura infantil, Filosofía', 'Poético, filosófico, ilustrado', 'Aviación', 'Muy Alta'),
('Isabel Allende', 'Chilena', 'Contemporáneo', 'Realismo mágico', 'Narrativa familiar, feminismo', 'Periodismo', 'Alta'),
('Ernesto Sabato', 'Argentino', 'Siglo XX', 'Existencialismo', 'Psicológico, introspectivo', 'Física', 'Alta'),
('Jorge Luis Borges', 'Argentino', 'Siglo XX', 'Fantástico, Metaficción', 'Laberintos, infinito, biblioteca', 'Autodidacta', 'Muy Alta'),
('Juan Rulfo', 'Mexicano', 'Siglo XX', 'Realismo mágico', 'Prosa poética, voces de muertos', 'Contabilidad', 'Alta'),
('Roberto Bolaño', 'Chileno', 'Contemporáneo', 'Postmodernismo', 'Fragmentario, autorreferencial', 'Autodidacta', 'Alta'),
('Mario Vargas Llosa', 'Peruano', 'Contemporáneo', 'Boom latinoamericano', 'Estructuras complejas, social', 'Letras y Derecho', 'Muy Alta'),
('J.R.R. Tolkien', 'Británico', 'Siglo XX', 'Fantasía épica', 'Worldbuilding, mitología', 'Filología', 'Muy Alta');

-- ============================================
-- TABLA: libros
-- Catálogo de libros (versión completa del diagrama)
-- ============================================
CREATE TABLE libros (
    id INT AUTO_INCREMENT PRIMARY KEY,
    titulo VARCHAR(255) NOT NULL,
    isbn VARCHAR(20) UNIQUE,
    precio DECIMAL(10, 2) NOT NULL,
    cantidad_stock INT NOT NULL DEFAULT 0,
    anio_publicacion INT,
    editorial VARCHAR(255),
    edicion VARCHAR(100),
    formato VARCHAR(50),
    tamano VARCHAR(50),
    genero VARCHAR(100),
    tema VARCHAR(255),
    estilo VARCHAR(100),
    lenguaje VARCHAR(50) DEFAULT 'Español',
    popularidad VARCHAR(50),
    notas_vendedor TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE INDEX idx_libros_isbn ON libros(isbn);
CREATE INDEX idx_libros_genero ON libros(genero);
CREATE INDEX idx_libros_titulo ON libros(titulo);

INSERT INTO libros (titulo, isbn, precio, cantidad_stock, anio_publicacion, editorial, edicion, formato, tamano, genero, tema, estilo, lenguaje, popularidad, notas_vendedor) VALUES
('Cien años de soledad', '978-0307474728', 29.99, 50, 1967, 'Editorial Sudamericana', 'Edición conmemorativa', 'Tapa dura', 'Mediano', 'Ficción', 'Familia, tiempo, destino', 'Realismo mágico', 'Español', 'Muy Alta', 'Obra maestra del realismo mágico'),
('Don Quijote de la Mancha', '978-8424116378', 35.50, 30, 1605, 'Real Academia Española', 'Edición RAE', 'Tapa dura', 'Grande', 'Clásicos', 'Aventura, locura, idealismo', 'Novela caballeresca paródica', 'Español', 'Muy Alta', 'La primera novela moderna'),
('1984', '978-0451524935', 24.99, 45, 1949, 'Secker & Warburg', 'Edición aniversario', 'Tapa blanda', 'Mediano', 'Distopía', 'Totalitarismo, vigilancia', 'Distópico', 'Español', 'Muy Alta', 'Clásico de la ciencia ficción'),
('El amor en los tiempos del cólera', '978-0307389732', 28.75, 25, 1985, 'Editorial Oveja Negra', 'Primera edición', 'Tapa blanda', 'Mediano', 'Ficción', 'Amor, vejez, persistencia', 'Realismo mágico', 'Español', 'Alta', 'Historia de amor épica'),
('La sombra del viento', '978-8408163220', 32.00, 40, 2001, 'Editorial Planeta', 'Edición especial', 'Tapa dura', 'Mediano', 'Misterio', 'Misterio, libros, Barcelona', 'Gótico', 'Español', 'Alta', 'Bestseller internacional'),
('Rayuela', '978-8420471396', 26.50, 20, 1963, 'Editorial Sudamericana', 'Edición definitiva', 'Tapa blanda', 'Mediano', 'Ficción', 'Amor, búsqueda, existencia', 'Experimental', 'Español', 'Alta', 'Novela interactiva'),
('El Principito', '978-0156012195', 18.99, 100, 1943, 'Reynal & Hitchcock', 'Edición ilustrada', 'Tapa dura', 'Pequeño', 'Infantil', 'Amistad, amor, humanidad', 'Fábula filosófica', 'Español', 'Muy Alta', 'El libro más traducido'),
('Crónica de una muerte anunciada', '978-0307475343', 27.25, 35, 1981, 'Editorial La Oveja Negra', 'Primera edición', 'Tapa blanda', 'Pequeño', 'Ficción', 'Honor, muerte, fatalidad', 'Periodismo literario', 'Español', 'Alta', 'Novela corta magistral'),
('La casa de los espíritus', '978-1501117015', 30.00, 28, 1982, 'Editorial Sudamericana', 'Edición aniversario', 'Tapa blanda', 'Grande', 'Ficción', 'Familia, política, espiritismo', 'Realismo mágico', 'Español', 'Alta', 'Primera novela de Allende'),
('El túnel', '978-8432217258', 22.99, 15, 1948, 'Editorial Sur', 'Edición clásica', 'Tapa blanda', 'Pequeño', 'Ficción', 'Obsesión, soledad, arte', 'Existencialista', 'Español', 'Alta', 'Obra maestra existencialista'),
('Ficciones', '978-0802130303', 31.50, 22, 1944, 'Editorial Sur', 'Edición completa', 'Tapa blanda', 'Mediano', 'Cuentos', 'Infinito, laberintos, tiempo', 'Fantástico', 'Español', 'Alta', 'Cuentos filosóficos'),
('Pedro Páramo', '978-0802133908', 29.00, 18, 1955, 'Fondo de Cultura Económica', 'Edición conmemorativa', 'Tapa blanda', 'Pequeño', 'Ficción', 'Muerte, memoria, padre', 'Realismo mágico', 'Español', 'Alta', 'Precursor del realismo mágico'),
('Los detectives salvajes', '978-0312427481', 34.99, 12, 1998, 'Editorial Anagrama', 'Primera edición', 'Tapa blanda', 'Grande', 'Ficción', 'Poesía, juventud, búsqueda', 'Postmoderno', 'Español', 'Alta', 'Premio Herralde y Rómulo Gallegos'),
('La ciudad y los perros', '978-8420411255', 28.50, 20, 1963, 'Seix Barral', 'Edición 50 aniversario', 'Tapa blanda', 'Mediano', 'Ficción', 'Violencia, adolescencia, militarismo', 'Realista', 'Español', 'Alta', 'Primera novela de Vargas Llosa'),
('El señor de los anillos', '978-0544003415', 45.99, 60, 1954, 'George Allen & Unwin', 'Edición completa', 'Tapa dura', 'Grande', 'Fantasía', 'Bien vs mal, amistad, poder', 'Fantasía épica', 'Español', 'Muy Alta', 'La trilogía completa');

-- ============================================
-- TABLA: libros_autores (relación N:M)
-- Relación muchos a muchos entre libros y autores
-- ============================================
CREATE TABLE libros_autores (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_autor INT NOT NULL,
    id_libro INT NOT NULL,
    rol VARCHAR(50) DEFAULT 'Autor principal',
    CONSTRAINT fk_libros_autores_autor FOREIGN KEY (id_autor) REFERENCES autores(id),
    CONSTRAINT fk_libros_autores_libro FOREIGN KEY (id_libro) REFERENCES libros(id),
    CONSTRAINT uk_libro_autor UNIQUE (id_autor, id_libro)
);

INSERT INTO libros_autores (id_autor, id_libro, rol) VALUES
(1, 1, 'Autor principal'),   -- García Márquez - Cien años de soledad
(2, 2, 'Autor principal'),   -- Cervantes - Don Quijote
(3, 3, 'Autor principal'),   -- Orwell - 1984
(1, 4, 'Autor principal'),   -- García Márquez - El amor en los tiempos del cólera
(4, 5, 'Autor principal'),   -- Ruiz Zafón - La sombra del viento
(5, 6, 'Autor principal'),   -- Cortázar - Rayuela
(6, 7, 'Autor principal'),   -- Saint-Exupéry - El Principito
(1, 8, 'Autor principal'),   -- García Márquez - Crónica de una muerte anunciada
(7, 9, 'Autor principal'),   -- Allende - La casa de los espíritus
(8, 10, 'Autor principal'),  -- Sabato - El túnel
(9, 11, 'Autor principal'),  -- Borges - Ficciones
(10, 12, 'Autor principal'), -- Rulfo - Pedro Páramo
(11, 13, 'Autor principal'), -- Bolaño - Los detectives salvajes
(12, 14, 'Autor principal'), -- Vargas Llosa - La ciudad y los perros
(13, 15, 'Autor principal'); -- Tolkien - El señor de los anillos

-- ============================================
-- TABLA: metodos_pago
-- Catálogo de métodos de pago disponibles
-- ============================================
CREATE TABLE metodos_pago (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre_metodo_pago VARCHAR(50) NOT NULL UNIQUE,
    descripcion VARCHAR(255),
    activo BOOLEAN DEFAULT TRUE,
    icono VARCHAR(100)
);

INSERT INTO metodos_pago (nombre_metodo_pago, descripcion, activo, icono) VALUES
('CREDIT_CARD', 'Tarjeta de crédito (Visa, Mastercard, Amex)', true, 'credit-card'),
('DEBIT_CARD', 'Tarjeta de débito', true, 'debit-card'),
('PAYPAL', 'PayPal', true, 'paypal'),
('BANK_TRANSFER', 'Transferencia bancaria', true, 'bank'),
('CASH', 'Efectivo (contra entrega)', true, 'cash'),
('BIZUM', 'Bizum', true, 'bizum'),
('APPLE_PAY', 'Apple Pay', true, 'apple'),
('GOOGLE_PAY', 'Google Pay', true, 'google');

-- ============================================
-- TABLA: metodos_pago_usuarios
-- Métodos de pago guardados por usuario
-- ============================================
CREATE TABLE metodos_pago_usuarios (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_usuario INT NOT NULL,
    id_tipo_metodo INT NOT NULL,
    descripcion VARCHAR(255),
    token_pago VARCHAR(255),
    ultimos_digitos VARCHAR(4),
    fecha_expiracion VARCHAR(7),
    es_predeterminado BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_metodos_pago_usuarios_usuario FOREIGN KEY (id_usuario) REFERENCES usuarios(id),
    CONSTRAINT fk_metodos_pago_usuarios_metodo FOREIGN KEY (id_tipo_metodo) REFERENCES metodos_pago(id)
);

INSERT INTO metodos_pago_usuarios (id_usuario, id_tipo_metodo, descripcion, ultimos_digitos, fecha_expiracion, es_predeterminado) VALUES
(1, 1, 'Visa Personal', '4532', '12/2027', true),
(1, 3, 'PayPal juan.perez@email.com', NULL, NULL, false),
(2, 1, 'Mastercard', '8721', '06/2026', true),
(3, 2, 'Débito BBVA', '1234', '03/2028', true),
(4, 3, 'PayPal ana.martinez@email.com', NULL, NULL, true);

-- ============================================
-- TABLA: carrito
-- Carritos de compra de usuarios
-- ============================================
CREATE TABLE carrito (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_usuario INT NOT NULL UNIQUE,
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    monto_total DECIMAL(10, 2) DEFAULT 0.00,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_carrito_usuario FOREIGN KEY (id_usuario) REFERENCES usuarios(id)
);

INSERT INTO carrito (id_usuario, monto_total) VALUES
(1, 59.98),
(2, 32.00),
(3, 0.00),
(4, 45.99);

-- ============================================
-- TABLA: carrito_libros
-- Items en el carrito de compra
-- ============================================
CREATE TABLE carrito_libros (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_carrito INT NOT NULL,
    id_libro INT NOT NULL,
    cantidad INT NOT NULL DEFAULT 1,
    precio DECIMAL(10, 2) NOT NULL,
    monto_total DECIMAL(10, 2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_carrito_libros_carrito FOREIGN KEY (id_carrito) REFERENCES carrito(id),
    CONSTRAINT fk_carrito_libros_libro FOREIGN KEY (id_libro) REFERENCES libros(id),
    CONSTRAINT uk_carrito_libro UNIQUE (id_carrito, id_libro)
);

INSERT INTO carrito_libros (id_carrito, id_libro, cantidad, precio, monto_total) VALUES
(1, 1, 2, 29.99, 59.98),
(2, 5, 1, 32.00, 32.00),
(4, 15, 1, 45.99, 45.99);

-- ============================================
-- TABLA: pedidos
-- Pedidos de compra
-- ============================================
CREATE TABLE pedidos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_usuario INT NOT NULL,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    monto_total DECIMAL(10, 2) NOT NULL,
    estado_pedido VARCHAR(50) NOT NULL DEFAULT 'PENDIENTE',
    estado_pago VARCHAR(50) NOT NULL DEFAULT 'PENDIENTE',
    estado_envio VARCHAR(50) DEFAULT 'NO_ENVIADO',
    direccion_entrega VARCHAR(500) NOT NULL,
    metodo_pago VARCHAR(50) NOT NULL,
    metodo_envio VARCHAR(50) DEFAULT 'ESTANDAR',
    codigo_rastreo VARCHAR(100),
    descuentos_aplicados DECIMAL(10, 2) DEFAULT 0.00,
    moneda VARCHAR(10) DEFAULT 'EUR',
    prioridad VARCHAR(20) DEFAULT 'NORMAL',
    comentarios_cliente TEXT,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_pedidos_usuario FOREIGN KEY (id_usuario) REFERENCES usuarios(id)
);

CREATE INDEX idx_pedidos_usuario ON pedidos(id_usuario);
CREATE INDEX idx_pedidos_estado ON pedidos(estado_pedido);
CREATE INDEX idx_pedidos_fecha ON pedidos(fecha_creacion);

INSERT INTO pedidos (id_usuario, monto_total, estado_pedido, estado_pago, estado_envio, direccion_entrega, metodo_pago, metodo_envio, codigo_rastreo, descuentos_aplicados, prioridad, comentarios_cliente) VALUES
(1, 59.98, 'ENTREGADO', 'COMPLETADO', 'ENTREGADO', 'Calle Principal 123, Madrid', 'CREDIT_CARD', 'EXPRESS', 'TRK-20250110-001', 0.00, 'ALTA', 'Por favor, entregar antes de las 18:00'),
(2, 35.50, 'ENTREGADO', 'COMPLETADO', 'ENTREGADO', 'Avenida Central 456, Barcelona', 'PAYPAL', 'ESTANDAR', 'TRK-20250112-002', 5.00, 'NORMAL', NULL),
(3, 74.97, 'ENVIADO', 'COMPLETADO', 'EN_TRANSITO', 'Plaza Mayor 789, Valencia', 'CREDIT_CARD', 'EXPRESS', 'TRK-20250125-003', 0.00, 'ALTA', 'Pedido urgente'),
(1, 28.75, 'PROCESANDO', 'COMPLETADO', 'PREPARANDO', 'Calle Principal 123, Madrid', 'DEBIT_CARD', 'ESTANDAR', NULL, 0.00, 'NORMAL', NULL),
(4, 64.00, 'PENDIENTE', 'PENDIENTE', 'NO_ENVIADO', 'Calle Secundaria 321, Sevilla', 'BANK_TRANSFER', 'ESTANDAR', NULL, 10.00, 'NORMAL', 'Esperando confirmación de pago'),
(2, 26.50, 'ENTREGADO', 'COMPLETADO', 'ENTREGADO', 'Avenida Central 456, Barcelona', 'PAYPAL', 'ESTANDAR', 'TRK-20250118-006', 0.00, 'NORMAL', NULL),
(3, 94.95, 'PROCESANDO', 'COMPLETADO', 'PREPARANDO', 'Plaza Mayor 789, Valencia', 'CREDIT_CARD', 'EXPRESS', NULL, 0.00, 'ALTA', 'Compra para colegio'),
(1, 27.25, 'CANCELADO', 'REEMBOLSADO', 'NO_ENVIADO', 'Calle Principal 123, Madrid', 'CREDIT_CARD', 'ESTANDAR', NULL, 0.00, 'NORMAL', 'Cliente solicitó cancelación');

-- ============================================
-- TABLA: libro_pedido
-- Items de cada pedido
-- ============================================
CREATE TABLE libro_pedido (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_pedido INT NOT NULL,
    id_libro INT NOT NULL,
    cantidad INT NOT NULL DEFAULT 1,
    precio DECIMAL(10, 2) NOT NULL,
    monto_total DECIMAL(10, 2) NOT NULL,
    CONSTRAINT fk_libro_pedido_pedido FOREIGN KEY (id_pedido) REFERENCES pedidos(id),
    CONSTRAINT fk_libro_pedido_libro FOREIGN KEY (id_libro) REFERENCES libros(id)
);

INSERT INTO libro_pedido (id_pedido, id_libro, cantidad, precio, monto_total) VALUES
(1, 1, 2, 29.99, 59.98),
(2, 2, 1, 35.50, 35.50),
(3, 3, 3, 24.99, 74.97),
(4, 4, 1, 28.75, 28.75),
(5, 5, 2, 32.00, 64.00),
(6, 6, 1, 26.50, 26.50),
(7, 7, 5, 18.99, 94.95),
(8, 8, 1, 27.25, 27.25);

-- ============================================
-- TABLA: lista_deseo (wishlist)
-- Lista de deseos de los usuarios
-- ============================================
CREATE TABLE lista_deseo (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_usuario INT NOT NULL,
    id_libro INT NOT NULL,
    cantidad INT DEFAULT 1,
    precio DECIMAL(10, 2),
    prioridad VARCHAR(20) DEFAULT 'MEDIA',
    notas TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_lista_deseo_usuario FOREIGN KEY (id_usuario) REFERENCES usuarios(id),
    CONSTRAINT fk_lista_deseo_libro FOREIGN KEY (id_libro) REFERENCES libros(id),
    CONSTRAINT uk_usuario_libro_deseo UNIQUE (id_usuario, id_libro)
);

INSERT INTO lista_deseo (id_usuario, id_libro, cantidad, precio, prioridad, notas) VALUES
(1, 11, 1, 31.50, 'ALTA', 'Para mi cumpleaños'),
(1, 13, 1, 34.99, 'MEDIA', NULL),
(2, 9, 1, 30.00, 'ALTA', 'Recomendación de amigo'),
(2, 12, 1, 29.00, 'BAJA', NULL),
(3, 15, 1, 45.99, 'ALTA', 'Edición especial'),
(4, 1, 1, 29.99, 'MEDIA', 'Clásico que quiero leer'),
(4, 3, 1, 24.99, 'ALTA', NULL);

-- ============================================
-- TABLA: books (Microservicio ms-books-catalogue)
-- Debe coincidir con la entidad Book (title, author, isbn, price, stock, category, publication_date, rating, visible)
-- ============================================
CREATE TABLE books (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    author VARCHAR(255) NOT NULL,
    isbn VARCHAR(20) UNIQUE,
    price DECIMAL(10, 2) NOT NULL,
    stock INT NOT NULL DEFAULT 0,
    category VARCHAR(100),
    publication_date DATE,
    rating INT,
    visible TINYINT(1) DEFAULT 1,
    description TEXT,
    publisher VARCHAR(255),
    publication_year INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

INSERT INTO books (title, author, isbn, price, stock, category, publication_date, rating, visible, description, publisher, publication_year) VALUES
('Cien años de soledad', 'Gabriel García Márquez', '978-0307474728-EN', 29.99, 50, 'Ficción', '1967-05-30', 5, 1, 'La obra maestra del realismo mágico.', 'Editorial Sudamericana', 1967),
('Don Quijote de la Mancha', 'Miguel de Cervantes', '978-8424116378-EN', 35.50, 30, 'Clásicos', '1605-01-01', 5, 1, 'La primera novela moderna.', 'Real Academia Española', 1605),
('1984', 'George Orwell', '978-0451524935-EN', 24.99, 45, 'Distopía', '1949-06-08', 5, 1, 'Novela distópica clásica.', 'Secker & Warburg', 1949),
('El amor en los tiempos del cólera', 'Gabriel García Márquez', '978-0307389732-EN', 28.75, 25, 'Ficción', '1985-01-01', 5, 1, 'Historia de amor épica.', 'Editorial Oveja Negra', 1985),
('La sombra del viento', 'Carlos Ruiz Zafón', '978-8408163220-EN', 32.00, 40, 'Misterio', '2001-01-01', 5, 1, 'Misterio en la Barcelona de posguerra.', 'Editorial Planeta', 2001);

-- ============================================
-- TABLA: payments (Microservicio ms-books-payments)
-- ============================================
CREATE TABLE payments (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    book_id BIGINT NOT NULL,
    book_title VARCHAR(255) NOT NULL,
    quantity INT NOT NULL DEFAULT 1,
    unit_price DECIMAL(10, 2) NOT NULL,
    total_amount DECIMAL(10, 2) NOT NULL,
    customer_name VARCHAR(255) NOT NULL,
    customer_email VARCHAR(255) NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'PENDING',
    payment_method VARCHAR(50) NOT NULL,
    transaction_id VARCHAR(100) UNIQUE,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_payments_book FOREIGN KEY (book_id) REFERENCES books(id)
);

CREATE INDEX idx_payments_book_id ON payments(book_id);
CREATE INDEX idx_payments_customer_email ON payments(customer_email);
CREATE INDEX idx_payments_status ON payments(status);
CREATE INDEX idx_payments_transaction_id ON payments(transaction_id);

INSERT INTO payments (book_id, book_title, quantity, unit_price, total_amount, customer_name, customer_email, status, payment_method, transaction_id, notes) VALUES
(1, 'Cien años de soledad', 2, 29.99, 59.98, 'Juan Pérez', 'juan.perez@email.com', 'COMPLETED', 'CREDIT_CARD', 'TXN-20250115-001', 'Compra para regalo'),
(2, 'Don Quijote de la Mancha', 1, 35.50, 35.50, 'María García', 'maria.garcia@email.com', 'COMPLETED', 'PAYPAL', 'TXN-20250116-002', NULL),
(3, '1984', 3, 24.99, 74.97, 'Carlos López', 'carlos.lopez@email.com', 'COMPLETED', 'CREDIT_CARD', 'TXN-20250117-003', 'Pedido urgente'),
(4, 'El amor en los tiempos del cólera', 1, 28.75, 28.75, 'Ana Martínez', 'ana.martinez@email.com', 'COMPLETED', 'DEBIT_CARD', 'TXN-20250118-004', NULL),
(5, 'La sombra del viento', 2, 32.00, 64.00, 'Roberto Sánchez', 'roberto.sanchez@email.com', 'PENDING', 'BANK_TRANSFER', 'TXN-20250119-005', 'Esperando confirmación');

-- ============================================
-- Fin del script SQL - Relatos de Papel
-- Total de tablas: 16
-- ============================================