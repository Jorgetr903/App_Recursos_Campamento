const express = require("express");
const connectDB = require("./config/db");
const cors = require("cors");
const path = require("path");

const app = express();
connectDB();

app.use(cors());
app.use(express.json());

// Servir archivos estáticos (upload.html y otros)
app.use(express.static(path.join(__dirname)));

// Carpeta de uploads
app.use("/uploads", express.static(path.join(__dirname, "public/uploads")));

// Rutas de la API
app.use("/api/recursos", require("./routes/recursos"));

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => console.log(`Servidor corriendo en puerto ${PORT}`));
