// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {TokenVesting} from "./TokenVesting.sol";
import {TokenVestingMerkle} from "./TokenVestingMerkle.sol";

/**
 * @title VestingFactory
 * @notice Deploys TokenVesting or TokenVestingMerkle instances for end users.
 *         - Transfers Ownership to the designated owner
 *         - Grants DEFAULT_ADMIN_ROLE & ROLE_CREATE_SCHEDULE to the owner
 *         - Renounces factory roles on the instance
 * Design notes:
 *  - For ERC20 vesting, the instance must hold enough balance before creating schedules.
 *    You can fund at deploy via `fundAmount` (factory pull via transferFrom) or later.
 *  - For native vesting, send native `msg.value` and it will be forwarded to the instance.
 *  - If you want predictable addresses, use the CREATE2 variants with a salt.
 */

contract VestingFactory {
    using SafeERC20 for IERC20Metadata;

    address public immutable vestingImplementation;
    address public immutable vestingMerkleImplementation;

    /// @notice Record of a deployed vesting contract.
    struct Record {
        /// @notice Address of the vesting contract.
        address vesting;
        /// @notice Owner of the vesting contract.
        address owner;
        /// @notice Token being vested.
        address token;
        /// @notice Whether it's a Merkle vesting contract.
        bool isMerkle;
    }

    Record[] public allVestingContracts;
    mapping(address => address[]) public vestingsByOwner;
    mapping(address => bool) public isMerkleVesting;

    // ---- Events ----
    /**
     * @notice Emitted when a TokenVesting contract is deployed.
     * @param vesting The address of the deployed vesting contract.
     * @param owner The owner of the vesting contract.
     * @param token The token being vested.
     */
    event TokenVestingDeployed(
        address indexed vesting,
        address indexed owner,
        address indexed token
    );
    /**
     * @notice Emitted when a TokenVestingMerkle contract is deployed.
     * @param vesting The address of the deployed vesting contract.
     * @param owner The owner of the vesting contract.
     * @param token The token being vested.
     * @param merkleRoot The Merkle root for the vesting contract.
     */
    event TokenVestingMerkleDeployed(
        address indexed vesting,
        address indexed owner,
        address indexed token,
        bytes32 merkleRoot
    );
    /**
     * @notice Emitted when a vesting contract is funded with ERC20 tokens.
     * @param vesting The vesting contract address.
     * @param token The ERC20 token address.
     * @param amount The amount funded.
     */
    event Funded(
        address indexed vesting,
        address indexed token,
        uint256 amount
    );
    /**
     * @notice Emitted when a vesting contract is funded with native currency.
     * @param vesting The vesting contract address.
     * @param amount The amount funded.
     */
    event FundedNative(address indexed vesting, uint256 amount);

    // ---- Errors ----
    error InvalidOwner();
    error ZeroToken();
    error ZeroAmount();
    error NativeAmountMismatch();
    error InvalidAddress();

    constructor(address _vestingImpl, address _vestingMerkleImpl) {
        if (_vestingImpl == address(0)) {
            revert InvalidAddress();
        }
        if (_vestingMerkleImpl == address(0)) {
            revert InvalidAddress();
        }
        vestingImplementation = _vestingImpl;
        vestingMerkleImplementation = _vestingMerkleImpl;
    }

    // ---- Views ----
    /**
     * @notice Returns all deployed vesting contract records.
     * @return An array of Record structs containing all vesting contracts.
     */
    function getAllVestings() external view returns (Record[] memory) {
        return allVestingContracts;
    }

    /**
     * @notice Returns the vesting contracts owned by a specific address.
     * @param owner_ The address of the owner.
     * @return An array of vesting contract addresses owned by the specified owner.
     */
    function getVestingsByOwner(
        address owner_
    ) external view returns (address[] memory) {
        return vestingsByOwner[owner_];
    }

    // ================================================================
    // ============ Standard deployment (CREATE) =======================
    // ================================================================

    /**
     * @notice Deploy a TokenVesting instance and set up ownership/roles.
     * @param token    ERC20 token address to vest (or HYPE native sentinel if your TokenVesting uses it)
     * @param name_    virtual token name (as required by your TokenVesting constructor)
     * @param symbol_  virtual token symbol
     * @param newOwner the end-user who should own/admin this instance
     * @param fundAmount (ERC20 only) amount to pull from msg.sender and forward to the instance (0 = skip)
     * @return vestingAddr The address of the deployed TokenVesting contract.
     */
    function deployTokenVesting(
        IERC20Metadata token,
        string memory name_,
        string memory symbol_,
        address newOwner,
        uint256 fundAmount
    ) external returns (address vestingAddr) {
        if (newOwner == address(0)) revert InvalidOwner();
        if (address(token) == address(0)) revert ZeroToken();

        vestingAddr = Clones.clone(vestingImplementation);
        isMerkleVesting[vestingAddr] = false;

        TokenVesting(payable(vestingAddr)).initialize(
            token,
            name_,
            symbol_,
            newOwner
        );

        if (fundAmount > 0) {
            _fundERC20(token, vestingAddr, fundAmount);
        }
        
        _record(vestingAddr, newOwner, address(token), false);
        emit TokenVestingDeployed(vestingAddr, newOwner, address(token));
    }

    /**
     * @notice Deploy a TokenVesting for native (HYPE) and forward native value to it.
     * @param name_    virtual token name (as required by your TokenVesting constructor)
     * @param symbol_  virtual token symbol
     * @param newOwner the end-user who should own/admin this instance
     * @return vestingAddr The address of the deployed TokenVesting contract.
     */
    function deployTokenVestingNative(
        string memory name_,
        string memory symbol_,
        address newOwner
    ) external payable returns (address vestingAddr) {
        if (newOwner == address(0)) revert InvalidOwner();

        vestingAddr = Clones.clone(vestingImplementation);
        isMerkleVesting[vestingAddr] = false;

        TokenVesting(payable(vestingAddr)).initialize(
            IERC20Metadata(
                TokenVesting(payable(vestingImplementation))
                    .NATIVE_TOKEN_ADDRESS()
            ),
            name_,
            symbol_,
            newOwner
        );

        if (msg.value > 0) {
            (bool ok, ) = vestingAddr.call{value: msg.value}("");
            require(ok, "Forward native failed");
            emit FundedNative(vestingAddr, msg.value);
        }

        _record(
            vestingAddr,
            newOwner,
            TokenVesting(payable(vestingImplementation)).NATIVE_TOKEN_ADDRESS(),
            false
        );
        emit TokenVestingDeployed(
            vestingAddr,
            newOwner,
            TokenVesting(payable(vestingImplementation)).NATIVE_TOKEN_ADDRESS()
        );
    }

    /**
     * @notice Deploy a TokenVestingMerkle instance for ERC20 and fund it.
     * @param token ERC20 token address to vest.
     * @param name_ Virtual token name.
     * @param symbol_ Virtual token symbol.
     * @param merkleRoot The Merkle root for the vesting.
     * @param newOwner The end-user who should own/admin this instance.
     * @param fundAmount Amount to pull from msg.sender and forward to the instance (0 = skip).
     * @return vestingAddr The address of the deployed TokenVestingMerkle contract.
     */
    function deployTokenVestingMerkle(
        IERC20Metadata token,
        string memory name_,
        string memory symbol_,
        bytes32 merkleRoot,
        address newOwner,
        uint256 fundAmount
    ) external returns (address vestingAddr) {
        if (newOwner == address(0)) revert InvalidOwner();
        if (address(token) == address(0)) revert ZeroToken();

        vestingAddr = Clones.clone(vestingMerkleImplementation);
        isMerkleVesting[vestingAddr] = true;

        TokenVestingMerkle(payable(vestingAddr)).initializeMerkle(
            token,
            name_,
            symbol_,
            newOwner,
            merkleRoot
        );

        if (fundAmount > 0) {
            _fundERC20(token, vestingAddr, fundAmount);
        }

        _record(vestingAddr, newOwner, address(token), true);
        emit TokenVestingMerkleDeployed(
            vestingAddr,
            newOwner,
            address(token),
            merkleRoot
        );
    }

    /**
     * @notice Deploy a TokenVestingMerkle instance for native and forward native value.
     * @param name_ Virtual token name.
     * @param symbol_ Virtual token symbol.
     * @param merkleRoot The Merkle root for the vesting.
     * @param newOwner The end-user who should own/admin this instance.
     * @return vestingAddr The address of the deployed TokenVestingMerkle contract.
     */
    function deployTokenVestingMerkleNative(
        string memory name_,
        string memory symbol_,
        bytes32 merkleRoot,
        address newOwner
    ) external payable returns (address vestingAddr) {
        if (newOwner == address(0)) revert InvalidOwner();

        vestingAddr = Clones.clone(vestingMerkleImplementation);
        isMerkleVesting[vestingAddr] = true;
        
        TokenVestingMerkle(payable(vestingAddr)).initializeMerkle(
            IERC20Metadata(
                TokenVesting(payable(vestingImplementation))
                    .NATIVE_TOKEN_ADDRESS()
            ),
            name_,
            symbol_,
            newOwner,
            merkleRoot
        );

        if (msg.value > 0) {
            (bool ok, ) = vestingAddr.call{value: msg.value}("");
            require(ok, "Forward native failed");
            emit FundedNative(vestingAddr, msg.value);
        }

        _record(
            vestingAddr,
            newOwner,
            TokenVesting(payable(vestingImplementation)).NATIVE_TOKEN_ADDRESS(),
            true
        );
        emit TokenVestingMerkleDeployed(
            vestingAddr,
            newOwner,
            TokenVesting(payable(vestingImplementation)).NATIVE_TOKEN_ADDRESS(),
            merkleRoot
        );
    }

    // ================================================================
    // ======================= Funding helpers ========================
    // ================================================================

    /**
     * @notice Fund an existing vesting instance with ERC20 (pull pattern).
     *         Caller must have approved this factory for `amount`.
     * @param vesting The vesting contract address to fund.
     * @param token The ERC20 token to transfer.
     * @param amount The amount to transfer.
     */
    function fundERC20(
        address vesting,
        IERC20Metadata token,
        uint256 amount
    ) external {
        if (amount == 0) revert ZeroAmount();
        token.safeTransferFrom(msg.sender, vesting, amount);
        emit Funded(vesting, address(token), amount);
    }

    /**
     * @notice Fund an existing vesting instance with native.
     * @param vesting The vesting contract address to fund.
     */
    function fundNative(address vesting) external payable {
        if (vesting == address(0)) revert InvalidAddress();
        if (msg.value == 0) revert ZeroAmount();
        (bool ok, ) = vesting.call{value: msg.value}("");
        require(ok, "Forward native failed");
        emit FundedNative(vesting, msg.value);
    }

    // ================================================================
    // ======================= Internal utils =========================
    // ================================================================

    /// @dev Internal function to fund a vesting contract with ERC20 tokens using safe transfer.
    /// @param token The ERC20 token.
    /// @param vesting The vesting contract address.
    /// @param amount The amount to transfer.
    function _fundERC20(
        IERC20Metadata token,
        address vesting,
        uint256 amount
    ) internal {
        token.safeTransferFrom(msg.sender, vesting, amount);
        emit Funded(vesting, address(token), amount);
    }

    /// @dev Records a newly deployed vesting contract in storage.
    /// @param vesting The vesting contract address.
    /// @param owner_ The owner address.
    /// @param token The token address.
    /// @param isMerkle Whether it is a Merkle vesting contract.
    function _record(
        address vesting,
        address owner_,
        address token,
        bool isMerkle
    ) internal {
        allVestingContracts.push(
            Record({
                vesting: vesting,
                owner: owner_,
                token: token,
                isMerkle: isMerkle
            })
        );
        vestingsByOwner[owner_].push(vesting);
    }

    /// @notice Allows the contract to receive native currency.
    receive() external payable {}
}
