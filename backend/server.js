require('dotenv').config();
const express = require('express');
const cors = require('cors');

const app = express();
app.use(cors());
app.use(express.json());

const PORT = process.env.PORT || 5001;

// Simple API route
app.get('/', (req, res) => {
    res.send('Backend is running...');
});

// Dummy API route
app.get('/api/data', (req, res) => {
    res.json({ message: 'Connected from the backend' });
});

app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
});
