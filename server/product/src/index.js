const express = require('express');
const cors  = require('cors');
const {product} = require('./api/product');
const {PORT} = require('./config/index');

const StartServer = async() => {
    const app = express();

    app.use(express.json());
    app.use(cors());
    app.listen(PORT, () => {
        console.log(`listening to port ${PORT}`);
    })
    .on('error', (err) => {
    console.log(err);
    process.exit();
    })

    await product(app);
};
StartServer();