const { expect } = require("chai");
const { ethers } = require("hardhat");
const { time } = require("@nomicfoundation/hardhat-network-helpers");

describe("AutoCompoundingVault", function () {
  let vault;
  let islandToken;
  let honeyToken;
  let oberoToken;
  let plugin;
  let gauge;
  let owner;
  let alice;
  let bob;
  let carol;

  // Constants
  const ISLAND_TOKEN = "0x63b0EdC427664D4330F72eEc890A86b3F98ce225";
  const HONEY_TOKEN = "0x0E4aaF1351de4c0264C5c7056Ef3777b41BD8e03";
  const OBERO_TOKEN = "0x7629668774f918c00Eb4b03AdF5C4e2E53d45f0b";
  const PLUGIN = "0x398A242f9F9452C1fF0308D4b4bf7ae6F6323868";
  const GAUGE = "0x996c24146cDF5756aFA42fa78447818A9a304851";

  beforeEach(async function () {
    // Get signers
    [owner, alice, bob, carol] = await ethers.getSigners();

    // Deploy vault
    const Vault = await ethers.getContractFactory("AutoCompoundingVault");
    vault = await Vault.deploy();
            await vault.deployed();

    // Get contract interfaces
    islandToken = await ethers.getContractAt("IERC20", ISLAND_TOKEN);
    honeyToken = await ethers.getContractAt("IERC20", HONEY_TOKEN);
    oberoToken = await ethers.getContractAt("IERC20", OBERO_TOKEN);
    plugin = await ethers.getContractAt("IPlugin", PLUGIN);
    gauge = await ethers.getContractAt("IGauge", GAUGE);

    // Fund test accounts with tokens (using hardhat_setBalance for test tokens)
    await network.provider.send("hardhat_setBalance", [
      alice.address,
      "0x" + (1000n * 10n ** 18n).toString(16),
    ]);

    // Approve vault for all test accounts
    const approvalAmount = ethers.parseEther("1000000");
    await islandToken.connect(alice).approve(vault.address, approvalAmount);
    await islandToken.connect(bob).approve(vault.address, approvalAmount);
    await islandToken.connect(carol).approve(vault.address, approvalAmount);
  });

  describe("Deployment", function () {
    it("Should set the right owner", async function () {
      expect(await vault.owner()).to.equal(owner.address);
    });

    it("Should have correct token addresses", async function () {
      expect(await vault.asset()).to.equal(ISLAND_TOKEN);
    });

    it("Should have correct initial settings", async function () {
      expect(await vault.harvestDelay()).to.equal(86400); // 1 day in seconds
      expect(await vault.slippageTolerance()).to.equal(200); // 2%
    });
  });

  describe("Deposits", function () {
    const depositAmount = ethers.utils.parseEther("100");

    it("Should accept deposits and mint correct shares", async function () {
      const preBal = await islandToken.balanceOf(alice.address);
      await vault.connect(alice).deposit(depositAmount, alice.address);
      
      expect(await vault.balanceOf(alice.address)).to.equal(depositAmount);
      expect(await islandToken.balanceOf(alice.address)).to.equal(preBal.sub(depositAmount));
    });

    it("Should stake LP tokens in Beradrome after deposit", async function () {
      await vault.connect(alice).deposit(depositAmount, alice.address);
      
      // Verify plugin balance increased
      const pluginBalance = await plugin.balanceOf(vault.address);
      expect(pluginBalance).to.be.gt(0);
    });

    it("Should fail deposit when paused", async function () {
      await vault.pause();
      await expect(
        vault.connect(alice).deposit(depositAmount, alice.address)
      ).to.be.revertedWith("Pausable: paused");
    });

    it("Should handle multiple deposits from different users", async function () {
      await vault.connect(alice).deposit(depositAmount, alice.address);
      await vault.connect(bob).deposit(depositAmount.mul(2), bob.address);
      
      expect(await vault.balanceOf(alice.address)).to.equal(depositAmount);
      expect(await vault.balanceOf(bob.address)).to.equal(depositAmount.mul(2));
    });
  });

  describe("Withdrawals", function () {
    const depositAmount = ethers.utils.parseEther("100");
    
    beforeEach(async function () {
      await vault.connect(alice).deposit(depositAmount, alice.address);
    });

    it("Should allow full withdrawal", async function () {
      const preBalance = await islandToken.balanceOf(alice.address);
      await vault.connect(alice).withdraw(depositAmount, alice.address, alice.address);
      
      expect(await vault.balanceOf(alice.address)).to.equal(0);
      expect(await islandToken.balanceOf(alice.address)).to.equal(preBalance.add(depositAmount));
    });

    it("Should allow partial withdrawal", async function () {
      const withdrawAmount = depositAmount.div(2);
      await vault.connect(alice).withdraw(withdrawAmount, alice.address, alice.address);
      
      expect(await vault.balanceOf(alice.address)).to.equal(withdrawAmount);
    });

    it("Should fail withdrawal when paused", async function () {
      await vault.pause();
      await expect(
        vault.connect(alice).withdraw(depositAmount, alice.address, alice.address)
      ).to.be.revertedWith("Pausable: paused");
    });
  });

  describe("Harvesting", function () {
    const depositAmount = ethers.utils.parseEther("100");

    beforeEach(async function () {
      await vault.connect(alice).deposit(depositAmount, alice.address);
    });

    it("Should harvest rewards and compound", async function () {
      // Move forward in time to accumulate rewards
      await time.increase(86400);

      const preBalance = await islandToken.balanceOf(vault.address);
      await vault.harvest();
      const postBalance = await islandToken.balanceOf(vault.address);

      expect(postBalance).to.be.gt(preBalance);
    });

    it("Should fail harvesting before delay period", async function () {
      await expect(vault.harvest()).to.be.revertedWith("Too soon to harvest");
    });

    it("Should emit Harvested event with correct values", async function () {
      await time.increase(86400);
      
      await expect(vault.harvest())
        .to.emit(vault, "Harvested")
        .withArgs(expect.any(Number), expect.any(Number));
    });
  });

  describe("Admin Functions", function () {
    it("Should allow owner to set harvest delay", async function () {
      const newDelay = 43200; // 12 hours
      await vault.setHarvestDelay(newDelay);
      expect(await vault.harvestDelay()).to.equal(newDelay);
    });

    it("Should allow owner to set slippage tolerance", async function () {
      const newTolerance = 300; // 3%
      await vault.setSlippageTolerance(newTolerance);
      expect(await vault.slippageTolerance()).to.equal(newTolerance);
    });

    it("Should fail when non-owner tries to set parameters", async function () {
      await expect(
        vault.connect(alice).setHarvestDelay(43200)
      ).to.be.revertedWith("Ownable: caller is not the owner");
      
      await expect(
        vault.connect(alice).setSlippageTolerance(300)
      ).to.be.revertedWith("Ownable: caller is not the owner");
    });

    it("Should allow owner to pause/unpause", async function () {
      await vault.pause();
      expect(await vault.paused()).to.be.true;
      
      await vault.unpause();
      expect(await vault.paused()).to.be.false;
    });

    it("Should allow emergency token rescue", async function () {
      const amount = ethers.utils.parseEther("1");
      await honeyToken.transfer(vault.address, amount);
      
      await vault.rescueTokens(HONEY_TOKEN, amount);
      expect(await honeyToken.balanceOf(owner.address)).to.equal(amount);
    });
  });

  describe("Edge Cases", function () {
    it("Should handle zero deposits", async function () {
      await expect(
        vault.connect(alice).deposit(0, alice.address)
      ).to.be.revertedWith("Zero amount");
    });

    it("Should handle max uint256 approvals", async function () {
      await islandToken.connect(alice).approve(vault.address, ethers.constants.MaxUint256);
      const depositAmount = ethers.utils.parseEther("100");
      await vault.connect(alice).deposit(depositAmount, alice.address);
      expect(await vault.balanceOf(alice.address)).to.equal(depositAmount);
    });

    it("Should prevent harvesting with no rewards", async function () {
      // Move time forward but with no deposits
      await time.increase(86400);
      await expect(vault.harvest()).to.be.revertedWith("No rewards to harvest");
    });
  });
});