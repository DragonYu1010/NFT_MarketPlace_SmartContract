pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./SafeMath.sol";

contract Mint_new is ERC1155, Ownable{
    
    struct NFT {
        string hash_;
        uint e_price_;
        uint d_price_;
    }
    NFT[] nft_list;

    struct Sell {
        uint nft_id_;
        uint e_price_;
        uint d_price_;
        address payable owner_;
        uint amount_;
    }
    Sell[] sell_list;

    uint[] black_list;
    mapping (uint => bool) isBlacklist;

    constructor() ERC1155("") Ownable() {}
    function Set_nft (string hash_, uint amount_, uint e_price_, uint d_price_) public view {
        _mint(msg.sender, nft_list.length, amount_, "");

        NFT temp = NFT(hash_, e_price_, d_price_);
        nft_list.push(temp);
    }

    function Get_nft (uint id_) public view returns (string, uint, uint) {
        return (
            nft_list[id_].hash_,
            nft_list[id_].e_price_,
            nft_list[id_].d_price_
        );
    }

    function Get_nft_amount () public view returns (uint) {
        return nft_list.length;
    }

    function Get_list_fee (uint price_) public view returns (uint) {
        return (price_/100);
    }
    function Set_sell (uint id_, uint e_price_, uint d_price_, uint amount_) public view returns(uint){
        // require : id_ is avaliable 
        require( id_ < nft_list.length, "ID has to be less than nft list length");
        // require : set at least one of two coins
        require ( (e_price_ > 0) || (d_price_ > 0), "set at least one of two coins");
        // require : 1% fee
        if ( e_price_ == 0 && d_price_ > 0) {
            require(list_fee(d_price_) * amount_ == msg.value, "1% fee");
        } else if ( e_price_ > 0 && d_price_ == 0) {
            require(list_fee(e_price_) * amount_ == msg.value, "1% fee");
        } else if ( e_price_ > 0 && d_price_ > 0) {
            require((list_fee(e_price_) + list_fee(d_price_)) * amount_ == msg.value, "1% fee");
        }
        // require : amount_ has to be available
        require((amount_>0) && ( _balances[id_][msg.sender] >= amount_ ), "amount_ has to be available");
        
        Sell memory sell_temp = Sell(id_, e_price_, d_price_, payable(msg.sender), amount_);
        sell_list.push(sell_temp);
        return (sell_list.length - 1);
    }

    function Update_sell (uint sell_id_, uint e_price_, uint d_price_, uint amount_) public view {
        // require : id_ is avaliable 
        require( id_ < sell_list.length, "ID has to be less than sell list length");
        // require : set at least one of two coins
        require ( (e_price_ > 0) || (d_price_ > 0), "set at least one of two coins");
        // require : amount_ has to be available
        require((amount_>0) && ( _balances[id_][msg.sender] >= amount_ ), "amount_ has to be available");
        sell_list[sell_id_].e_price_ = e_price_;
        sell_list[sell_id_].d_price_ = d_price_;
        sell_list[sell_id_].amount_ = amount_;
    }

    function Remove_selling (uint id_) public onlyOwner view {
        // require : id_ is avaliable 
        require( id_ < sell_list.length, "ID has to be less than sell list length");
        delete sell_list[id_];
    }

    function Get_sell (uint id_) public view returns (uint, uint, address, uint) {
        // require : id_ is avaliable 
        require( id_ < sell_list.length, "ID has to be less than sell list length");
        return (
            sell_list[id_].e_price_,
            sell_list[id_].d_price_,
            sell_list[id_].owner_,
            sell_list[id_].amount_
        );
    }

    function sell_fee (uint price_) public view returns(uint) {
        // require : price_ has to be available
        require( price_ > 0, "price_ has to be available");
        return price_ * 975 / 1000;
    }
    
    function Buying (uint sell_id_, uint amount_, uint token_kind_) public payable {
        // require : sell_id_ has to be less than sell list length
        require( sell_id_ < sell_list.length,  "sell_id_ has to be less than sell list length");
        // require : buying amount has to be avaliable
        require( amount_ <= sell_list[sell_id_].amount_, "amount has to less than capacity" );
        
        safeTransferFrom( msg.sender, sell_list[sell_id_].owner_, sell_list[sell_id_].nft_id_, amount_, "" );
        if (amount_ == sell_list[sell_id_].amount_) {
            Remove_selling(sell_id_);
        } else {
            sell_list[sell_id_].amount_ = sell_list[sell_id_].amount_ - amount_;
        }
        
        if( token_kind_ == 0 ){
            sell_list[sell_id_].owner.transfer(sell_fee(sell_list[sell_id_].e_price_));
        } else {
            sell_list[sell_id_].owner.transfer(sell_fee(sell_list[sell_id_].d_price_));
        }

    }
    
    function Set_blacklist (uint id_) public onlyOwner view {
        // require : id_ has to be less than nft length
        require(id_ < nft_list.length, "id_ has to be less than nft length");
        // require : id_ has not already set in the black list
        require(isBlacklist[id_] == false, "id_ has not already set in the black list");
        black_list.push(id_);
        isBlacklist[id_] = true;
    }

    function check_blacklist (uint id_) public view returns (bool) {
        // require : id_ has to be less than nft length
        require(id_ < nft_list.length, "id_ has to be less than nft length");
        return isBlacklist[id_];
    }
    receive() payable external {}
    function getETH() external onlyOwner {
        msg.sender.transfer(address(this).balance);
    }
}