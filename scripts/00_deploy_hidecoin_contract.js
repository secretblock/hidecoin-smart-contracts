const hre = require("hardhat");

async function main() {
  const HideCoin = await hre.ethers.getContractFactory("HideCoin");
  const hidecoin = await HideCoin.deploy("InitialOwner_Address");

  await hidecoin.deployed();

  console.log("HideCoin deployed to:", hidecoin.address);

  await hre.run("verify:verify", {
    address: hidecoin.address,
    constructorArguments: ["InitialOwner_Address"],
    contract: "contracts/HideCoin.sol:HideCoin",
  });
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  }); // Calling the function to deploy the contract
