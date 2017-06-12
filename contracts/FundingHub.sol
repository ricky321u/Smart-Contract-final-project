pragma solidity ^0.4.4;

import "./Project.sol";

contract FundingHub {

    uint currentProjectIndex = 0;

    mapping(address => Project) projects;

    function createProject(bytes32 name, uint amountToBeRaised, uint deadlineTime) external {
      //External functions are part of the contract interface,
      //which means they can be called from other contracts and via transactions.
        Project newProject = new Project(name, msg.sender, amountToBeRaised, deadlineTime);
        projects[address(newProject)] = newProject;
        ProjectCreated(address(newProject), name, msg.sender, amountToBeRaised, deadlineTime);
    }

    function contribute(address projectAddress) external payable {
        projects[projectAddress].fund.value(msg.value)(msg.sender);
    }

    event ProjectCreated(address  projectAddress, bytes32 projectName,
      address  ownerAddress, uint amountToBeRaised, uint deadlineTime);
}
