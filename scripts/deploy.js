async function main() {
    const LiquidityPool = await ethers.getContractFactory("LiquidityPool");
 
    // Start deployment, returning a promise that resolves to a contract object
    const liq_pool = await LiquidityPool.deploy();
    console.log("Contract deployed to address:", liq_pool.address);}
 
 main()
   .then(() => process.exit(0))
   .catch(error => {
     console.error(error);
     process.exit(1);
   });