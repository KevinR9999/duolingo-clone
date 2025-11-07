import bcrypt from "bcryptjs";
import cors from "cors";
import express from "express";
import pkg from "pg";

const { Pool } = pkg;

const app = express();
app.use(express.json());
app.use(cors());

// 🟢 Configuración de conexión a PostgreSQL
const pool = new Pool({
  user: "postgres",
  host: "localhost",
  database: "ingles", // <-- cambia si tu base tiene otro nombre
  password: "123456", // <-- cambia por tu contraseña real
  port: 5433,
});

// ========================================================
// 🔹 REGISTRO DE USUARIO
// ========================================================
app.post("/api/register", async (req, res) => {
  const { display_name, email, password } = req.body;

  if (!display_name || !email || !password) {
    return res.status(400).json({ error: "Todos los campos son obligatorios" });
  }

  try {
    // Verificar si el usuario ya existe
    const existingUser = await pool.query("SELECT * FROM users WHERE email = $1", [email]);
    if (existingUser.rows.length > 0) {
      return res.status(400).json({ error: "El usuario ya existe" });
    }

    // Encriptar contraseña
    const hashedPassword = await bcrypt.hash(password, 10);

    // Insertar usuario en la tabla `users`
    const result = await pool.query(
      `INSERT INTO users (email, display_name, password, level)
       VALUES ($1, $2, $3, 'A1')
       RETURNING uid, email, display_name, level, total_xp, current_streak, max_streak`,
      [email, display_name, hashedPassword]
    );

    const newUser = result.rows[0];

    res.status(201).json({
      message: "Usuario registrado exitosamente",
      user: newUser,
    });
  } catch (err) {
    console.error("❌ Error al registrar usuario:", err);
    res.status(500).json({ error: "Error interno del servidor" });
  }
});

// ========================================================
// 🔹 LOGIN DE USUARIO
// ========================================================
app.post("/api/login", async (req, res) => {
  const { email, password } = req.body;

  if (!email || !password) {
    return res.status(400).json({ error: "Faltan datos para iniciar sesión" });
  }

  try {
    const result = await pool.query("SELECT * FROM users WHERE email = $1", [email]);
    if (result.rows.length === 0) {
      return res.status(404).json({ error: "Usuario no encontrado" });
    }

    const user = result.rows[0];
    const validPassword = await bcrypt.compare(password, user.password);

    if (!validPassword) {
      return res.status(401).json({ error: "Contraseña incorrecta" });
    }

    res.json({
      message: "Inicio de sesión exitoso",
      user: {
        uid: user.uid,
        display_name: user.display_name,
        email: user.email,
        level: user.level,
        total_xp: user.total_xp,
        current_streak: user.current_streak,
        max_streak: user.max_streak,
      },
    });
  } catch (err) {
    console.error("❌ Error al iniciar sesión:", err);
    res.status(500).json({ error: "Error del servidor" });
  }
});

// ========================================================
// 🔹 SERVIDOR
// ========================================================
app.listen(5000, () => {
  console.log("🚀 Servidor corriendo en http://localhost:5000");
});
