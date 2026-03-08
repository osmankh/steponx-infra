const crypto = require("crypto");

exports.handler = async (event) => {
  const secret = process.env.CUSTOM_AUTH_SECRET;
  const nonce = event.request.privateChallengeParameters.nonce ||
    event.request.challengeAnswer; // fallback
  const userAnswer = event.request.challengeAnswer;

  // Recompute HMAC from the nonce in publicChallengeParameters
  const publicNonce = event.request.publicChallengeParameters.nonce;
  const expectedAnswer = crypto
    .createHmac("sha256", secret)
    .update(publicNonce)
    .digest("hex");

  event.response.answerCorrect = userAnswer === expectedAnswer;

  return event;
};
