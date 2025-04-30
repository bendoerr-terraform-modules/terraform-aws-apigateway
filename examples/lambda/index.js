exports.handler = async (event) => {
  console.log("Event received:", JSON.stringify(event));

  // Prepare response
  const response = {
    statusCode: 200,
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      message: "Hello from Lambda!",
      timestamp: new Date().toISOString(),
      requestDetails: {
        path: event.path,
        httpMethod: event.httpMethod,
        requestId: event.requestContext?.requestId || "unknown",
      },
    }),
  };

  return response;
};
