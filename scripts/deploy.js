require("dotenv").config()
const { ethers } = require("hardhat");
const hre = require("hardhat");
const fs = require("fs");

async function main() {
  //get the signer that we will use to deploy
  const [deployer] = await ethers.getSigners();
  const { ADMIN, TOKEN } = process.env

  console.log("Deploying contracts with the account:", deployer.address);
  console.log("Account balance:", (await deployer.getBalance()).toString());

  // const C0 = await hre.ethers.getContractFactory("GroovesCoin");
  // const c0 = await C0.deploy();
  // await c0.deployed();
  // console.log("GroovesCoin ", c0.address);

  const C = await hre.ethers.getContractFactory("GroovesNFT");
  const c = await C.deploy();
  await c.deployed();
  console.log("GroovesNFT ", c.address);

  const C1 = await hre.ethers.getContractFactory("GroovesListing");
  const c1 = await C1.deploy(c.address);
  await c1.deployed();
  console.log("GroovesListing ", c1.address);

  const C2 = await hre.ethers.getContractFactory("GroovesGacha");
  const c2 = await C2.deploy(c.address);
  await c2.deployed();
  console.log("GroovesGacha ", c2.address);

  const C3 = await hre.ethers.getContractFactory("GroovesAuction");
  const c3 = await C3.deploy(c.address);
  await c3.deployed();
  console.log("GroovesAuction ", c3.address);

  const C4 = await hre.ethers.getContractFactory("GroovesBurnReward");
  const c4 = await C4.deploy(c.address);
  await c4.deployed();
  console.log("GroovesBurnReward ", c4.address);

  //Pull the address and ABI out while you deploy, since that will be key in interacting with the smart contract later

  let rawdata = fs.readFileSync("./artifacts/contracts/GroovesNFT.sol/GroovesNFT.json");
  let abi = JSON.parse(rawdata);

  let rawdata0 = fs.readFileSync("./scripts/GroovesCoinTestNet.json");
  let abi0 = JSON.parse(rawdata0);

  // let rawdata0 = fs.readFileSync("./artifacts/contracts/GroovesCoin.sol/GroovesCoin.json");
  // let abi0 = JSON.parse(rawdata0);

  let rawdata1 = fs.readFileSync("./artifacts/contracts/GroovesListing.sol/GroovesListing.json");
  let abi1 = JSON.parse(rawdata1);

  let rawdata2 = fs.readFileSync("./artifacts/contracts/GroovesGacha.sol/GroovesGacha.json");
  let abi2 = JSON.parse(rawdata2);

  let rawdata3 = fs.readFileSync("./artifacts/contracts/GroovesAuction.sol/GroovesAuction.json");
  let abi3 = JSON.parse(rawdata3);

  let rawdata4 = fs.readFileSync("./artifacts/contracts/GroovesBurnReward.sol/GroovesBurnReward.json");
  let abi4 = JSON.parse(rawdata4);

  const data = {
    market_address: c.address,
    market_abi: abi.abi,
    token_address: "0x52E087107876cFd8b460160CCA5074956D9AB27e",
    token_abi: abi0.abi,
    listing_address: c1.address,
    listing_abi: abi1.abi,
    gacha_address: c2.address,
    gacha_abi: abi2.abi,
    auction_address: c3.address,
    auction_abi: abi3.abi,
    reward_address: c4.address,
    reward_abi: abi4.abi,
  }

  //This writes the ABI and address to the marketplace.json
  //This data is then used by frontend files to connect with the smart contract
  // fs.writeFileSync('./admin/src/Marketplace.json', JSON.stringify(data))
  fs.writeFileSync('./client/src/Marketplace.json', JSON.stringify(data))
  fs.writeFileSync('./groovesApp/src/Marketplace.json', JSON.stringify(data))
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });