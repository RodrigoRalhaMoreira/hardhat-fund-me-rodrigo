// Get funds from users
// Withdraw funds
// Set a minimum funding value in USD

// SPDX-License-Identifier: MIT
// Pragma
pragma solidity ^0.8.8;

// Imports
import "./PriceConverter.sol";

// tricks to recude gas fees
// constant, immutable

// Error Codes
//this instead of requires saves gas
error FundMe_NotOwner();

// Interfaces, Libraries, Contracts

/** @title A contract for crowd funding
 *  @author Rodrigo Moreira
 *  @notice This contract is to demo a sample funding contract
 *  @dev This implements price feed as our library
 */
contract FundMe {
    // Type Declarations
    using PriceConverter for uint256;

    // State Variables
    //changed this to constant and saved gas
    uint256 public constant MINIMUM_USD = 50 * 1e18;

    address[] private s_funders;
    mapping(address => uint256) private s_addressToAmountFunded;

    // does not change and initialized in constructor put immutable save gas
    address private immutable i_owner;

    AggregatorV3Interface private s_priceFeed;

    modifier onlyOwner() {
        //require(msg.sender == i_owner, "Sender is not owner");
        if (msg.sender != i_owner) {
            revert FundMe_NotOwner();
        }
        _;
        //if underscore is before it executes functions and then the require
        //otherwise it only executes functions after the require has passed
    }

    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    // What happens if someone sends this contract ETH without calling the fund function?

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    /**
     *  @notice This functions funds this contract
     *  @dev This implements price feed as our library
     */
    function fund() public payable {
        // set minimum fund amount in USD
        // 1. How do we send ETH to this contract? with payable
        require(
            msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD,
            "Didn't send enough"
        ); // 1e18 = 1*10**18. This value is in Wei
        s_funders.push(msg.sender);
        s_addressToAmountFunded[msg.sender] += msg.value;
        // this above reverts if the condition does not pass.
        // this means undo action before, and send remaining gas back, but still costs gas.
    }

    function withdraw() public onlyOwner {
        //only the owner can call this function with the require
        //code smell if we need at every function
        //so insteaf of line down we use a modifier
        //require(msg.sender == owner, "Sender is not owner");
        for (uint256 i = 0; i < s_funders.length; i++) {
            address funder = s_funders[i];
            s_addressToAmountFunded[funder] = 0;
        }
        // reset the array
        s_funders = new address[](0); // 0 elements to start the array
        // withdraw the funds

        //transfer
        //payable(msg.sender).transfer(address(this).balance); // fail returns error
        //send
        //bool send = payable(msg.sender).send(address(this).balance); // fail returns boolean
        //require(send, "Send failed");
        //call
        (bool call, ) = i_owner.call{value: address(this).balance}("");
        require(call, "Call failed");
    }

    function cheaperWithdraw() public payable onlyOwner {
        address[] memory funders = s_funders;
        // mappings can't be in memory
        for (uint256 i = 0; i < funders.length; i++) {
            address funder = funders[i];
            s_addressToAmountFunded[funder] = 0;
        }

        s_funders = new address[](0); // 0 elements to start the array

        (bool call_sucess, ) = i_owner.call{value: address(this).balance}("");
        require(call_sucess, "Call failed");
    }

    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getFunder(uint256 index) public view returns (address) {
        return s_funders[index];
    }

    function getAddressToAmountFunded(address funder)
        public
        view
        returns (uint256)
    {
        return s_addressToAmountFunded[funder];
    }

    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return s_priceFeed;
    }
}
