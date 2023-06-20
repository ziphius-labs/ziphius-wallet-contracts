import { ethers } from "hardhat";

export interface WalletFixtureReturn {
  walletFactory: any
}

export async function WalletFixture(): Promise<WalletFixtureReturn> {
  const WalletFactoryContract = await ethers.getContractFactory("WalletFactory");
  const EntryPointContract = await ethers.getContractFactory("EntryPoint")
}
