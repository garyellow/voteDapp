const Vote = artifacts.require("Vote");

module.exports = function (deployer) {
  deployer.deploy(Vote, ["Mario", "Luigi", "Koopa"], ["https://mario-family.weebly.com/uploads/2/7/4/1/27417881/8806728_orig.png", "https://mario-family.weebly.com/uploads/2/7/4/1/27417881/3293406_orig.png", "https://mario-family.weebly.com/uploads/2/7/4/1/27417881/8375348_orig.png"], ["red", "green", "yellow"], ["None", "None", "None"]);
};
