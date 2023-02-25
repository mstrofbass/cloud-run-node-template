import { describe, expect, test } from "vitest";

import axios from "axios";
import Agent from "agentkeepalive";

const endpointUrl = process.env.E2E_ENDPOINT_URL;

console.log("e2e test endpointUrl is " + endpointUrl);

const keepaliveAgent = new Agent({
  maxSockets: 100,
  maxFreeSockets: 10,
  timeout: 60000, // active socket keepalive for 60 seconds
  freeSocketTimeout: 30000, // free socket keepalive for 30 seconds
});

const client = axios.create({
  baseURL: endpointUrl,
  timeout: 30000,
  headers: {
    "Content-Type": "application/json",
  },
  httpAgent: keepaliveAgent,
});

describe("GET / should", () => {
  test("return expected result", () => {
    return client.get("/").then((res) => {
      const result = res.data;

      expect(res.status).toBe(200);
      expect(result).toEqual({ hello: "world" });
    });
  });
});

describe("GET /nonexistent-path should", () => {
  test("return a 404", () => {
    return client.get("/nonexistent-path").then((res) => {
      expect(res.status).toBe(404);
    });
  });
});
