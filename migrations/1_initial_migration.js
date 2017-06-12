var Migrations = artifacts.require("./Migrations.sol"); //es6的requrie and module.export

module.exports = function(deployer) {
  deployer.deploy(Migrations);
};
