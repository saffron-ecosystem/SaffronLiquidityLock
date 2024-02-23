const {ethers,upgrades} = require("hardhat");

async function main() {
    const HelloWorld_NEW = await ethers.getContractFactory("SaffronLock_V1");
    console.log(" SaffronLock_V1 is upgrading");

    await upgrades.upgradeProxy("0xd51c6873A29d6dd7a7BBcccf293db6B6aC334ecd",HelloWorld_NEW)
    console.log("SaffronLock_V1 upgraded Success");
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
  