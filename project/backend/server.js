const express = require('express');
const cors = require('cors');
const mysql = require('mysql2/promise');

const app = express();
const port = process.env.PORT || 4000;

app.use(cors());
app.use(express.json());

const dbConfig = {
  host: process.env.MYSQL_HOST || 'db',
  user: process.env.MYSQL_USER || 'appuser',
  password: process.env.MYSQL_PASSWORD || 'apppassword',
  database: process.env.MYSQL_DATABASE || 'appdb',
};

let pool;

async function initDb() {
  try {
    pool = mysql.createPool({
      ...dbConfig,
      waitForConnections: true,
      connectionLimit: 10,
      queueLimit: 0,
    });

    const createTableSql = `
      CREATE TABLE IF NOT EXISTS messages (
        id INT AUTO_INCREMENT PRIMARY KEY,
        content VARCHAR(255) NOT NULL
      ) ENGINE=InnoDB;
    `;

    await pool.query(createTableSql);

    const [rows] = await pool.query('SELECT COUNT(*) AS count FROM messages');
    if (rows[0].count === 0) {
      await pool.query('INSERT INTO messages (content) VALUES (?)', ['Hello from MySQL!']);
    }

    console.log('Database initialized');
  } catch (err) {
    console.error('Error initializing database', err);
  }
}

app.get('/api/message', async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT content FROM messages ORDER BY id DESC LIMIT 1');
    if (rows.length === 0) {
      return res.json({ message: 'No messages yet' });
    }
    res.json({ message: rows[0].content });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Database error' });
  }
});

app.post('/api/message', async (req, res) => {
  try {
    const { content } = req.body;
    if (!content) {
      return res.status(400).json({ error: 'content is required' });
    }
    await pool.query('INSERT INTO messages (content) VALUES (?)', [content]);
    res.status(201).json({ status: 'ok' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Database error' });
  }
});

app.get('/health', async (req, res) => {
  try {
    await pool.query('SELECT 1');
    res.json({ status: 'ok' });
  } catch (err) {
    res.status(500).json({ status: 'error' });
  }
});

app.listen(port, () => {
  console.log(`Backend listening on port ${port}`);
});

initDb();
