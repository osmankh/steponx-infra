const crypto = require("crypto");

exports.handler = async (event) => {
  const secret = process.env.CUSTOM_AUTH_SECRET;
  const nonce = crypto.randomBytes(32).toString("hex");
  const expectedAnswer = crypto
    .createHmac("sha256", secret)
    .update(nonce)
    .digest("hex");

  event.response.publicChallengeParameters = { nonce };
  event.response.privateChallengeParameters = { answer: expectedAnswer };

  return event;
};
