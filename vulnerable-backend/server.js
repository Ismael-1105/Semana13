const express = require("express");
const mongoose = require("mongoose");
const cors = require("cors");
const http = require("http");
const socketIo = require("socket.io");

const app = express();

// ❌ CORS completamente abierto
app.use(cors());

// ❌ Sin rate limiting
// ❌ Sin helmet
// ❌ Sin validación

app.use(express.json());

// ❌ Conexión Mongo sin autenticación
mongoose.connect("mongodb://localhost:27017/vulnerableDB")
  .then(() => console.log("MongoDB conectado"))
  .catch(err => console.log("Error MongoDB:", err));

// ❌ Password en texto plano
const UserSchema = new mongoose.Schema({
  email: String,
  password: String,
  role: String
});

const User = mongoose.model("User", UserSchema);

// ✅ Nuevo modelo para almacenar contactos básicos
const ContactSchema = new mongoose.Schema({
  displayName: String,
  phones: [String],
  emails: [String],
  // opcional: referencia al usuario que importó (si es necesario)
  owner: { type: mongoose.Schema.Types.ObjectId, ref: 'User' }
});

const Contact = mongoose.model("Contact", ContactSchema);

// ❌ Registro sin hash
app.post("/register", async (req, res) => {
  try {
    const user = new User(req.body);
    await user.save();
    res.json({ message: "Usuario creado", user });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ❌ Login inseguro
app.post("/login", async (req, res) => {
  const { email, password } = req.body;

  const user = await User.findOne({ email, password });

  if (!user) {
    return res.status(401).json({ message: "Credenciales incorrectas" });
  }

  // ❌ Token falso sin firma
  res.json({
    message: "Login exitoso",
    token: "fake-jwt-token-" + user._id,
    user: {
      _id: user._id,
      email: user.email,
      role: user.role
    }
  });
});

// ❌ Endpoint sin autenticación
app.get("/users", async (req, res) => {
  const users = await User.find();
  res.json(users);
});

// ❌ Endpoint admin sin protección
app.get("/admin", (req, res) => {
  res.json({ secret: "Datos administrativos sensibles", adminPanel: true });
});

// ❌ Endpoint de datos sensibles expuesto
app.get("/data", async (req, res) => {
  const users = await User.find();
  res.json({
    totalUsers: users.length,
    users: users,
    databaseInfo: "MongoDB sin autenticación",
    apiVersion: "1.0.0 (sin versionado seguro)"
  });
});

// ---------------------------------------------------------------------
// Nuevos endpoints para contactos (sin autenticación/validación)
// ---------------------------------------------------------------------

// almacena un objeto de contacto
app.post("/contacts", async (req, res) => {
  try {
    const contact = new Contact(req.body);
    await contact.save();
    res.json({ message: "Contacto guardado", contact });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// devuelve todos los contactos
app.get("/contacts", async (req, res) => {
  try {
    const contacts = await Contact.find();
    res.json(contacts);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// opcional: borrar todos los contactos (para pruebas)
app.delete("/contacts", async (req, res) => {
  try {
    await Contact.deleteMany({});
    res.json({ message: "Todos los contactos eliminados" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ❌ Conexión WebSocket persistente insegura
const server = http.createServer(app);
const io = socketIo(server, {
  cors: { origin: "*" }
});

io.on("connection", (socket) => {
  console.log("Cliente conectado:", socket.id);

  socket.on("pingServer", () => {
    socket.emit("pongServer", {
      message: "Conexión persistente activa",
      timestamp: new Date().toISOString()
    });
  });

  socket.on("getUserData", async (userId) => {
    // ❌ Sin autenticación ni autorización
    const user = await User.findById(userId);
    socket.emit("userData", user);
  });

  socket.on("disconnect", () => {
    console.log("Cliente desconectado:", socket.id);
  });
});

// ❌ Endpoint para listar información del servidor
app.get("/info", (req, res) => {
  res.json({
    serverVersion: "1.0.0",
    mongoVersion: "Latest",
    environment: "production",
    uptime: process.uptime(),
    timestamp: new Date().toISOString()
  });
});

server.listen(3000, "0.0.0.0", () => {
  console.log("Servidor vulnerable corriendo en puerto 3000");
  console.log("⚠️ ADVERTENCIA: Este servidor está INTENCIONALMENTE configurado de forma insegura");
});
