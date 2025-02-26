//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IERC721 {
    function transferFrom(address _from, address _to, uint256 _id) external;
}

contract Escrow {
    address public nftAddress;
    address payable public seller;
    address public inspecter;
    address public lender;

    modifier onlySeller() {
        require(msg.sender == seller, "Only seller can call this function");
        _;
    }

    modifier onlyBuyer(uint256 _nftID) {
        require(
            msg.sender == buyer[_nftID],
            "Only buyer can call this function"
        );
        _;
    }

    modifier onlyInspector() {
        require(
            msg.sender == inspecter,
            "Only inspector can call this function"
        );

        _;
    }

    mapping(uint256 => bool) public isListed;
    mapping(uint256 => uint256) public purchasePrice;
    mapping(uint256 => uint256) public escrowAmount;
    mapping(uint256 => address) public buyer;
    mapping(uint256 => bool) public inspectionPassed;
    mapping(uint256 => mapping(address => bool)) public approval;

    constructor(
        address _nftAddress,
        address payable _seller,
        address _inspecter,
        address _lender
    ) {
        nftAddress = _nftAddress;
        seller = _seller;
        inspecter = _inspecter;
        lender = _lender;
    }

    function list(
        uint256 _nftID,
        address _buyer,
        uint256 _purchessPrice,
        uint256 _escrowAmount
    ) public {
        IERC721(nftAddress).transferFrom(msg.sender, address(this), _nftID);
        isListed[_nftID] = true;
        purchasePrice[_nftID] = _purchessPrice;
        buyer[_nftID] = _buyer;
        escrowAmount[_nftID] = _escrowAmount;
    }

    function depositeEarnest(uint256 _nftID) public payable onlyBuyer(_nftID) {
        require(msg.value >= escrowAmount[_nftID], "Invalid amount");
    }

    function updateInspectionStatus(
        uint256 _nftID,
        bool _passed
    ) public onlyInspector {
        inspectionPassed[_nftID] = _passed;
    }

    function approveSale(uint256 _nftID) public onlyBuyer(_nftID) {
        approval[_nftID][msg.sender] = true;
    }

    receive() external payable {}

    function getBalence() public view returns (uint256) {
        return address(this).balance;
    }

    function finalizeSale(uint256 _nftID) public {
        require(inspectionPassed[_nftID], "Inspection not passed");
        require(approval[_nftID][buyer[_nftID]], "Buyer has not approved");
        require(approval[_nftID][seller], "Seller has not approved");
        require(approval[_nftID][lender], "Inspector has not approved");

        require(address(this).balance >= purchasePrice[_nftID]);

        isListed[_nftID] = false;
        (bool success, ) = payable(seller).call{value: address(this).balance}(
            ""
        );
        require(success, "Failed to transfer funds");
        IERC721(nftAddress).transferFrom(address(this), buyer[_nftID], _nftID);
    }
    function cancelSale(uint256 _nftID) public {
        if (inspectionPassed[_nftID] == false) {
            payable(buyer[_nftID]).transfer(address(this).balance);
        } else {
            payable(seller).transfer(address(this).balance);
        }
    }
}
