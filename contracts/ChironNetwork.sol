pragma solidity 0.5.16;
pragma experimental ABIEncoderV2;

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

}

contract ChironNetwork {

    using SafeMath for uint256;

    struct Task {
        uint256 taskID;
        uint256 currentRound;
        uint256 totalRounds;
        uint256 cost;
        string[] modelHashes;
    }
    
    address owner;
    address coordinatorAddress = address(0xBeb71662FF9c08aFeF3866f85A6591D4aeBE6e4E);

    uint256 nextTaskID = 1;
    mapping (uint256 => Task) public SentinelTasks;
    mapping (address => uint256[]) public UserTaskIDs;

    event newTaskCreated(uint256 indexed taskID, address indexed _user, string _modelHash, uint256 _amt, uint256 _time);
    event modelUpdated(uint256 indexed taskID, string _modelHash, uint256 _time);
    
    constructor() public {
        owner = msg.sender;
    }
    
    function updateOwner(address _newOwner) public {
        require(msg.sender == owner, "Only Owner");
        owner = _newOwner;
    }

    function createTask(string memory _modelHash, uint256 _rounds) public payable {
        require(_rounds < 10, "Number of Rounds should be less than 10");
        uint256 taskCost = msg.value;

        Task memory newTask;
        newTask = Task({
            taskID: nextTaskID,
            currentRound: 1,
            totalRounds: _rounds,
            cost: taskCost,
            modelHashes: new string[](_rounds)
        });
        newTask.modelHashes[0] = _modelHash;
        SentinelTasks[nextTaskID] = newTask;
        UserTaskIDs[msg.sender].push(nextTaskID);
        emit newTaskCreated(nextTaskID, msg.sender, _modelHash, taskCost, now);

        nextTaskID = nextTaskID.add(1);
    }

    function updateModelForTask(uint256 _taskID,  string memory _modelHash, address payable computer) public {
        require(msg.sender == coordinatorAddress, "You are not the coordinator !");
        require(_taskID <= nextTaskID, "Invalid Task ID");
        uint256 newRound = SentinelTasks[_taskID].currentRound.add(1);
        require(newRound <= SentinelTasks[_taskID].totalRounds, "All Rounds Completed");
        

        SentinelTasks[_taskID].currentRound = newRound;
        SentinelTasks[_taskID].modelHashes[newRound.sub(1)] = _modelHash;
        address(computer).transfer(SentinelTasks[_taskID].cost.div(SentinelTasks[_taskID].totalRounds));
        emit modelUpdated(_taskID, _modelHash, now);

    }

    function getTaskHashes(uint256 _taskID) public view returns (string[] memory) {
        return (SentinelTasks[_taskID].modelHashes);
    }

    function getTaskCount() public view returns (uint256) {
        return nextTaskID.sub(1);
    }
    function getTasksOfUser() public view returns (uint256[] memory) {
        return UserTaskIDs[msg.sender];
    }
    
    struct Fund {
        uint256 orgID;
        string orgName;
        string fundName;
        address payable fundAddress;
        uint256 donationAmount;
        uint256 donationCnt;
    }
    
    uint256 public fundCnt = 0;
    uint256 public totalDonationAmount = 0;
    uint256 public totalDonationCnt = 0;
    mapping (uint256 => Fund) public Funds;
    
    function createFund(string memory _orgName,string memory _fundName, address payable _orgAdress) public {
        Fund memory newfund;
        newfund = Fund({
            orgID: fundCnt,
            orgName: _orgName,
            fundName: _fundName,
            fundAddress: _orgAdress,
            donationAmount:0,
            donationCnt:0
        });
        
        Funds[fundCnt] = newfund;
        fundCnt = fundCnt.add(1);
    }
    
    function donateToFund(uint256 _fundID) public payable{
        require(_fundID <= fundCnt, "Invalid Fund ID");
        
        Funds[_fundID].donationAmount = Funds[_fundID].donationAmount.add(msg.value);
        Funds[_fundID].donationCnt = Funds[_fundID].donationCnt.add(1);
        
        totalDonationAmount = totalDonationAmount.add(msg.value);
        totalDonationCnt = totalDonationCnt.add(1);
        
        Funds[_fundID].fundAddress.transfer(msg.value);
    }

}
