const express = require("express");
const router = express.Router();

router.post("/", function (req, res) {
  handleRequest(req, res);
});

function handleRequest(req, res) {
  res.status(200).json({});
}

module.exports = {
  router,
  handleRequest,
};
