const express = require("express");
const bodyParser = require("body-parser");
const mysql = require("mysql2");
const cors = require("cors");

const app = express();
const port = 3000;

app.use(bodyParser.json());
app.use(cors());

const pool = mysql.createPool({
  host: "localhost",
  user: "root",
  password: "",
  database: "farmprecise",
  connectionLimit: 10,
});

app.get("/community", (req, res) => {
  // Define your SELECT query
  const selectQuery = `SELECT USERNAME, TITLE, CONTENT, DATE_FORMAT(ADDDATE(NOW(), INTERVAL -FLOOR(RAND() * 365) DAY), '%Y-%m-%d') AS DATE FROM community`;

  // Execute the SELECT query
  pool.query(selectQuery, (err, results) => {
    if (err) {
      console.error("Error executing query:", err);
      res.status(500).json({ message: "Internal server error" });
      return;
    }
    res.json(results);
  });
});

app.post("/login", (req, res) => {
  const { USERNAME, PASSWORD } = req.body;

  pool.query(
    "SELECT * FROM user WHERE USERNAME = ? AND PASSWORD = ?",
    [USERNAME, PASSWORD],
    (err, results) => {
      if (err) {
        console.error("Error executing query:", err);
        res.status(500).json({ message: "Internal server error" });
        return;
      }

      if (results.length === 0) {
        res.status(401).json({ message: "Invalid credentials" });
        return;
      }

      // If login is successful, return user data
      const user = {
        USERNAME: results[0].USERNAME,
      };
      res.json(user);
    }
  );
});
app.post("/signup", (req, res) => {
  const { USERNAME, EMAIL, PASSWORD } = req.body;

  pool.query(
    "INSERT INTO user (USERNAME, EMAIL, PASSWORD) VALUES (?, ?, ?)",
    [USERNAME, EMAIL, PASSWORD],
    (err, results) => {
      if (err) {
        console.error("Error executing query:", err);
        res.status(500).json({ message: "Internal server error" });
        return;
      }

      // Signup successful
      res.status(201).json({ message: "Signup successful" });
    }
  );
});
app.post("/farmsetup", (req, res) => {
  const {
    FARMERNAME,
    LOCALITY,
    ACRES,
    SOILTYPE,
    WATERSOURCE,
    CURRENTCROP,
    PASTCROP,
  } = req.body;

  pool.query(
    "INSERT INTO farm (FARMERNAME, LOCALITY, ACRES, SOILTYPE, WATERSOURCE, CURRENTCROP, PASTCROP) VALUES (?, ?, ?, ?, ?, ?, ?)",
    [FARMERNAME, LOCALITY, ACRES, SOILTYPE, WATERSOURCE, CURRENTCROP, PASTCROP],
    (err, results) => {
      if (err) {
        console.error("Error executing query:", err);
        res.status(500).json({ message: "Internal server error" });
        return;
      }

      // Farm setup successful
      res.status(201).json({ message: "Farm setup successful" });
    }
  );
});
app.get("/community", (req, res) => {
  const selectQuery = "SELECT USERNAME, TITLE, CONTENT, DATE FROM community";

  pool.query(selectQuery, (err, results) => {
    if (err) {
      console.error("Error executing query:", err);
      res.status(500).json({ message: "Internal server error" });
      return;
    }
    res.json(results);
  });
});

// Add a new community post
app.post("/community", (req, res) => {
  const { USERNAME, TITLE, CONTENT, DATE } = req.body;

  const insertQuery =
    "INSERT INTO community (USERNAME, TITLE, CONTENT, DATE) VALUES (?, ?, ?, ?)";

  pool.query(insertQuery, [USERNAME, TITLE, CONTENT, DATE], (err, results) => {
    if (err) {
      console.error("Error executing query:", err);
      res.status(500).json({ message: "Internal server error" });
      return;
    }
    res.status(201).json({ message: "Post added successfully" });
  });
});

app.get("/croprecommendation", (req, res) => {
  const selectQuery =
    "SELECT Location, Temperature, Humidity, Recommended_Crop ,Days_Required,Water_Needed,Crop_Image FROM crop_recommendation WHERE Location = 'Sathyamangalam'";

  pool.query(selectQuery, (err, results) => {
    if (err) {
      console.error("Error executing query:", err);
      res.status(500).json({ message: "Internal server error" });
      return;
    }
    res.json(results);
  });
});

app.listen(port, () => {
  console.log(`Server is running on 192.168.247.65:${port}`);
});
