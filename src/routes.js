const express = require("express");
const router = express.Router();

router.get("/", function (req, res) {
  handleRequest(req, res);
});

function handleRequest(req, res) {
  res.status(200).json({"hello": "world"});
}

module.exports = {
  router,
  handleRequest,
};
