require('dotenv').config(); // Load environment variables from .env

const {server} = require('./app'); // Import the server from server.js

const PORT = process.env.PORT || 3000;

server.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
