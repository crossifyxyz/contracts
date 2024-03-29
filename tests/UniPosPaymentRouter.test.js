const { expect } = require("chai");
const { ethers } = require("hardhat");

let deployer, receiver, payeer;
let testTokenContract;
let routerContract;
let AVAX = "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE";

describe("Router", async function () {
    before(async function () {
        [deployer, receiver, payeer, feeBeneficiary] = await ethers.getSigners();

        this.TestToken = await ethers.getContractFactory("TestToken");
        testTokenContract = await this.TestToken.deploy();
        await testTokenContract.deployed();

        await testTokenContract.mint(deployer.address, ethers.utils.parseEther("1000000"));
        await testTokenContract.mint(payeer.address, ethers.utils.parseEther("1000000"));
    })

    beforeEach(async function () {
        this.Router = await ethers.getContractFactory("UniPosPaymentRouter");

        routerContract = await this.Router.deploy(feeBeneficiary.address);
        await routerContract.deployed();
    })

    describe("deploy", async function () {

    })

    describe("payment", async function () {
        it("should be able to pay by native coin", async function () {
            let beforeReceiver = await ethers.provider.getBalance(receiver.address);
            let beforeFee = await ethers.provider.getBalance(feeBeneficiary.address);

            await expect(routerContract
                .connect(payeer)
                .receiveNative(100, 1, receiver.address, { value: 101 }))
                .to.emit(routerContract, "PaymentReceived")
                .withArgs(payeer.address, receiver.address, AVAX, 100, 1);

            let afterReceiver = await ethers.provider.getBalance(receiver.address);
            let afterFee = await ethers.provider.getBalance(feeBeneficiary.address);

            expect(afterReceiver.sub(beforeReceiver)).to.equal(100);
            expect(afterFee.sub(beforeFee)).to.equal(1);
        });

        it("should be able to pay by token", async function () {
            let beforeReceiver = await testTokenContract.balanceOf(receiver.address);
            let beforeFee = await testTokenContract.balanceOf(feeBeneficiary.address);

            await testTokenContract.connect(payeer).approve(routerContract.address, 101);
            await expect(routerContract
                .connect(payeer)
                .receiveToken(testTokenContract.address, 100, 1, receiver.address))
                .to.emit(routerContract, "PaymentReceived")
                .withArgs(payeer.address, receiver.address, testTokenContract.address, 100, 1);

            let afterReceiver = await testTokenContract.balanceOf(receiver.address);
            let afterFee = await testTokenContract.balanceOf(feeBeneficiary.address);

            expect(afterReceiver.sub(beforeReceiver)).to.equal(100);
            expect(afterFee.sub(beforeFee)).to.equal(1);
        });
    });

    describe("maintainance", async function () {
        it("should be able to change fee beneficiary", async function () {
            await expect(routerContract
                .connect(deployer)
                .setFeeBeneficiary(payeer.address))
                .to.emit(routerContract, "FeeBeneficiaryChanged")
                .withArgs(feeBeneficiary.address, payeer.address);

            expect(await routerContract.feeBeneficiary()).to.equal(payeer.address);
        });

        it("only owner can change fee beneficiary", async function () {
            await expect(routerContract
                .connect(payeer)
                .setFeeBeneficiary(payeer.address))
                .to.be.revertedWith("Ownable: caller is not the owner");
        });
    });
})