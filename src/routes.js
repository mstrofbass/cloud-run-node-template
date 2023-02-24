import express from "express";

export const router = express.Router();

router.get("/", function (req, res) {
  handleRequest(req, res);
});

export function handleRequest(req, res) {
  res.status(200).json({ hello: "world" });
}
