const Vote = artifacts.require("Vote");

module.exports = function (deployer) {
  deployer.deploy(Vote, ["Gary", "Bob", "Alice"], ["https://jf-staeulalia.pt/img/other/14/collection-letter.jpg", "https://upload.wikimedia.org/wikipedia/commons/thumb/a/a3/Paris_RER_B_icon.svg/768px-Paris_RER_B_icon.svg.png", "https://upload.wikimedia.org/wikipedia/commons/thumb/5/57/Capital_C.svg/900px-Capital_C.svg.png"], ["good", "smart", "beautiful"], ["a123456789@gmail.com", "b123456789@gmail.com", "c123456789@gmail.com"]);
};
