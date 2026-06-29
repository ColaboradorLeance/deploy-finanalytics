/** @type {import('drizzle-kit').Config} */
module.exports = {
  out: "./migrations",
  dialect: "postgresql",
  dbCredentials: {
    url: process.env.DATABASE_URL,
  },
};
