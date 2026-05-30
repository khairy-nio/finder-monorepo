console.log("STEP 1");

const express = require("express");
const app = express();

console.log("STEP 2");

app.get("/", (req, res) => {
    res.send("OK");
});

app.listen(3501, () => {
    console.log("SERVER RUNNING 3501");
});