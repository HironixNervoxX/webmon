const { Pool } = require('pg');
const pool = new Pool({
  host: process.env.DB_HOST || 'webmon-postgres',
  port: process.env.DB_PORT || 5432,
  user: process.env.DB_USER || 'webmon',
  password: process.env.DB_PASSWORD || 'webmon_pwd',
  database: process.env.DB_NAME || 'webmon'
});
async function initDb() {
  // Retry until Postgres is ready
  for (let i = 0; i < 20; i++) {
    try {
      await pool.query('SELECT 1');
      break;
    } catch (e) {
      console.log(`Waiting for DB... (${i + 1}/20)`);
      await new Promise(r => setTimeout(r, 2000));
    }
  }
  await pool.query(`
    CREATE TABLE IF NOT EXISTS tasks (
      id SERIAL PRIMARY KEY,
      title TEXT NOT NULL,
      done BOOLEAN DEFAULT FALSE,
      created_at TIMESTAMP DEFAULT NOW()
    );
  `);
}
const getTasks    = async () => (await pool.query('SELECT * FROM tasks ORDER BY id DESC')).rows;
const createTask  = async (title) => (await pool.query('INSERT INTO tasks(title) VALUES($1) RETURNING *', [title])).rows[0];
const updateTask  = async (id, done) => (await pool.query('UPDATE tasks SET done=$1 WHERE id=$2 RETURNING *', [done, id])).rows[0];
const deleteTask  = async (id) => (await pool.query('DELETE FROM tasks WHERE id=$1 RETURNING *', [id])).rows[0];
module.exports = { initDb, getTasks, createTask, updateTask, deleteTask };
