const {
  handleRequest,
} = require("../../../src/routes");

const mockResponse = () => {
  const res = {};
  res.status = jest.fn().mockReturnValue(res);
  res.json = jest.fn().mockReturnValue(res);
  return res;
};

describe("handleRequest should", () => {
  test("return 200 and empty object", () => {
    const resp = mockResponse();
    const req = {
      body: {},
    };
    handleRequest(req, resp);

    expect(resp.status).toHaveBeenCalledWith(200);
    expect(resp.json).toHaveBeenCalledWith({});
  });
});