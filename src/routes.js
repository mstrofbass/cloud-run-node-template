var express = require("express");
var router = express.Router();

const { calculateQuote } = require("./quote-calculator");

router.post("/", function (req, res) {
  handleRequest(req, res);
});

function handleRequest(req, res) {
  const quoteRequest = req.body;

  try {
    validateRequest(quoteRequest);
  } catch (err) {
    return res.status(400).json({});
  }

  calculateQuote(quoteRequest);

  res.status(200).json(quoteRequest);
}

function validateRequest(quoteRequest) {
  if (!quoteRequest.id) throw new RequestIdMissing("quote id missing");
  if (!quoteRequest.requestNumber)
    throw new RequestNumberMissing("quote request number missing");
}

class RequestIdMissing extends Error {}
class RequestNumberMissing extends Error {}

module.exports = {
  router,
  handleRequest,
  validateRequest,
  RequestIdMissing,
  RequestNumberMissing,
};
