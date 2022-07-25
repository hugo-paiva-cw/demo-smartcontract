async function main() {
    const TokenizedVault = await ethers.getContractFactory("TokenizedVault");
 
    // Start deployment, returning a promise that resolves to a contract object
    const underlyingAssetLINK = '0x01BE23585060835E02B77ef475b0Cc51aA1e0709';
    const underlyingAssetBRLC = '0xC6d1eFd908ef6B69dA0749600F553923C465c812';
    const name = 'cloudwalkStableCoin';
    const symbol = 'BRLC';
    const liq_pool = await TokenizedVault.deploy(underlyingAssetBRLC, name, symbol);
    console.log("Contract deployed to address:", liq_pool.address);}
 
 main()
   .then(() => process.exit(0))
   .catch(error => {
     console.error(error);
     process.exit(1);
   });