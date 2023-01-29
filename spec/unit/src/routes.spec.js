const {
  handleRequest,
  validateRequest,
  RequestIdMissing,
  RequestNumberMissing,
} = require("../../../src/routes");

const mockResponse = () => {
  const res = {};
  res.status = jest.fn().mockReturnValue(res);
  res.json = jest.fn().mockReturnValue(res);
  return res;
};

const mockQuoteRequest = {
  id: "fake-quote-request",
  requestNumber: "fake-request-num",
};

describe("handleRequest should", () => {
  test("return 200 and empty object", () => {
    const resp = mockResponse();
    const req = {
      body: mockQuoteRequest,
    };
    handleRequest(req, resp);

    expect(resp.status).toHaveBeenCalledWith(200);
    expect(resp.json).toHaveBeenCalledWith(mockQuoteRequest);
  });

  test("return 400 and empty object", () => {
    const mockQuoteRequest1 = {
      id: "fake-quote-request",
    };

    const resp = mockResponse();
    const req = {
      body: mockQuoteRequest1,
    };
    handleRequest(req, resp);

    expect(resp.status).toHaveBeenCalledWith(400);
  });
});

describe("validateRequest should", () => {
  test("pass when quote request is valid", () => {
    const mockQuoteRequest = {
      id: "fake-quote-request",
      requestNumber: "fake-request-num",
    };

    validateRequest(mockQuoteRequest);
  });

  test("fail if request id is missing", () => {
    const mockQuoteRequest = {
      requestNumber: "fake-request-num",
    };

    expect(() => validateRequest(mockQuoteRequest)).toThrow(RequestIdMissing);
  });

  test("fail if request number is missing", () => {
    const mockQuoteRequest = {
      id: "fake-quote-request",
    };

    expect(() => validateRequest(mockQuoteRequest)).toThrow(
      RequestNumberMissing
    );
  });
});
