import { describe, expect, test } from "vitest";
import request from "supertest";

import app from "../../app.js";

describe("GET / should", () => {
  test("return a 200 and expected response", () => {
    return request(app)
      .get("/")
      .expect(200)
      .then((response) => {
        expect(response.body).toStrictEqual({ hello: "world" });
      });
  });

  test("return a 404 if invalid path is requested", () => {
    return request(app).get("/does-not-exist").expect(404);
  });
});
