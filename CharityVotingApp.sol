//SPDX-License-Identifier: MIT

/*This project not only promotes charitable causes,
but it also demonstrates the power of blockchain 
technology in ensuring transparency and security in voting and fund allocation.
*/
pragma solidity ^0.8.10;

import "/hardhat/console.sol";

contract CharityVotingApp{

    address public propowner;
    uint private totalofCampaings = 0;
    uint private totalofUsers= 0;
    
    // Creating user account
  struct Register {
      string userName;
      string userDescruption;
      address  wallet_address;
    }

   Register [] Registers;

// creating new account 

    function createAccount(uint _ID,string memory _userName,string memory _userDescription,address _wallet_address) public returns (bool Succed){
        if(_ID >= Registers.length){
            Registers.push(Register("","",address(0)));
        }
        Register storage user = Registers[_ID];
        user.userName = _userName;
        user.userDescruption = _userDescription;
        user.wallet_address = _wallet_address;
        
        totalofUsers++ ;
            
        return (true);

    }
   
   
    // creating a charity campaign
    
    struct campaign {
        string campaignName;
        string campaignDescription;
         uint amount;
         string purposeOfAmount;
        uint duration ;
        address CampaignAddress;
        address [] votes;
        uint [] totalAmounts;
        uint totalVotes;
        mapping (address => bool) AlreadyVoted;
    }

    

    mapping (uint => campaign) public campaigns;
    
    //define the owner 
    constructor () {
        propowner = msg.sender;
    }

//Creating function for new proposal
        event CharityCampaign_Created(uint indexed _ID, string indexed _campaignName, address indexed _campaignAccount);
   
   
    function createProposal(uint _ID,address _campaignAccount,string memory _campaignName,string memory _campaignDes,string memory _purposeOfFunds,uint _amount,uint _duration )private {
        campaign storage Campaign = campaigns[_ID];
         require(msg.sender == propowner,"Only the registered owner can create a campaign");
        Campaign.campaignName = _campaignName;
        Campaign.campaignDescription = _campaignDes;
        Campaign.amount = _amount;
        Campaign.CampaignAddress = _campaignAccount;
        Campaign.duration = _duration;
        Campaign.purposeOfAmount = _purposeOfFunds;
        
        
        totalofCampaings ++;

        emit CharityCampaign_Created(_ID , _campaignName,_campaignAccount);

    }

//Voting Function 

    modifier OnlyInActiveDuration(uint _ID) {
        campaign storage Campaign = campaigns[_ID] ;
        require(block.timestamp < Campaign.duration, "The campaign has been endeed !");
        _;
    }

            event YouHaveVoted (address indexed campaigns , Register);
            
    function vote(uint _ID) public OnlyInActiveDuration(_ID){
        Register storage user = Registers[_ID];
        require(!campaigns[_ID].AlreadyVoted[msg.sender]," You already Voted to this campaign!" );
        
        campaigns[_ID].votes.push(msg.sender);
        campaigns[_ID].AlreadyVoted[msg.sender] = true;
            
        campaigns[_ID].totalVotes ++ ;

        emit YouHaveVoted(campaigns[_ID].CampaignAddress, user );

    }

// Donation

            modifier OnlyAfterVote (uint _ID) {
                campaign storage Campaign = campaigns[_ID] ;
                require(Campaign.AlreadyVoted[msg.sender],"You must already voted to this charity campaign");
                _;
            }


            event DonatedTo (address indexed CampaignAddress, uint _amount);

    function Donation (uint _amount,uint _ID) public payable  OnlyAfterVote(_ID) returns(uint){
        campaign storage Campaign = campaigns[_ID] ;
            require (_amount > 0.1 ether,"You must donate at least 0.1 ETH");
            campaigns[_ID].totalAmounts.push(_amount);

            
            emit DonatedTo(msg.sender, msg.value);

            return _amount;
    }


    function withdraw () public payable {
        campaign storage Campaign = campaigns[totalofCampaings-1];
        require(propowner == msg.sender);
        require(block.timestamp == Campaign.duration);
        require (Campaign.totalVotes >= totalofUsers/2 , " The Votes are less than 50% The Charity Campaign Failed " );
        
        //check which campaign received the most votes
        uint mostVotes= 0 ;
        address mostVotesCampaign = address(0);
        for (uint i = 0 ;  i < totalofCampaings; i ++){
            if(campaigns[i].totalVotes > mostVotes){
                mostVotes = campaigns[i].totalVotes;
                mostVotesCampaign = campaigns[i].CampaignAddress;
            }
        }

        // Transfer the funds to the campaign with the most votes

        payable(mostVotesCampaign).transfer(Campaign.amount);

        
    }






    

}