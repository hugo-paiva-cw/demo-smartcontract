async function main() {
    const LiquidityPool = await ethers.getContractFactory("LiquidityPool");
 
    // Start deployment, returning a promise that resolves to a contract object
    const liq_pool = await LiquidityPool.deploy('0xC6d1eFd908ef6B69dA0749600F553923C465c812');
    console.log("Contract deployed to address:", liq_pool.address);}
 
 main()
   .then(() => process.exit(0))
   .catch(error => {
     console.error(error);
     process.exit(1);
   });