pragma solidity ^0.4.4;

contract Project {

    struct ProjectDetails {
        bytes32 name;
        address ownerAddress;
        uint amountToBeRaised;
        uint deadlineTime;
        uint currentFundingTotal;
        ProjectStatus status;
    }

    struct Contribution {
        address contributorAddress;
        uint amountContributed;
    }

enum ProjectStatus { FUNDING, PAIDOUT, REFUNDED } //Project

    ProjectDetails projectDetails;
    Contribution[] contributions;
    address hubAddress;

    function Project(bytes32 name, address ownerAddress, uint amountToBeRaised, uint deadlineTime) {
        hubAddress = msg.sender;
        projectDetails.name = name;
        projectDetails.ownerAddress = ownerAddress;
        projectDetails.amountToBeRaised = amountToBeRaised;
        projectDetails.deadlineTime = deadlineTime;
        projectDetails.currentFundingTotal = 0;
        projectDetails.status = ProjectStatus.FUNDING;
    }

    function fund(address contributerAddress) onlyHub payable {
        if (projectDetails.status == ProjectStatus.PAIDOUT || projectDetails.status == ProjectStatus.REFUNDED) throw;
        //當PAIDOUT或退款後就break
        uint amountToFund = msg.value;

        if(isPassedDeadline()) { //當超過限期沒有募資成功
            projectDetails.status = ProjectStatus.REFUNDED;

            //Send funds back to this contributer
          sendFunds(contributerAddress, amountToFund);

            //Refund all other contributers
            refund();
        } else {
            uint overContributedAmount = 0;
            if (projectDetails.currentFundingTotal + amountToFund > projectDetails.amountToBeRaised) {
                //Funded too much
                //Refund excess
                overContributedAmount = (projectDetails.currentFundingTotal + amountToFund) - projectDetails.amountToBeRaised;

                //Recalculate amount to fund
                amountToFund = projectDetails.amountToBeRaised - projectDetails.currentFundingTotal;
            }

            addContribution(contributerAddress, amountToFund);

            if (projectDetails.amountToBeRaised == projectDetails.currentFundingTotal) {
                projectDetails.status = ProjectStatus.PAIDOUT;

                //Project已籌款成功, payout!
                payout();

                //Refund if over contributed
                if (overContributedAmount != 0) {
                    sendFunds(contributerAddress, overContributedAmount);
                }
            }
        }
    }

    function payout() private {
        sendFunds(projectDetails.ownerAddress, projectDetails.currentFundingTotal);

        ProjectFullyFunded(this); //在Deadline前募資成功會觸發this Event
    }

    function refund() private {
        ProjectNotFundedBeforeDeadline(this); //在Deadline前沒有募資成功會觸發This Event

        for (uint i = 0; i < contributions.length; i++) {
            sendFunds(contributions[i].contributorAddress, contributions[i].amountContributed);
        }
    }

    function getProjectDetails() public returns(
        bytes32 name, address ownerAddress, uint amountToBeRaised, uint deadlineTime,
        uint currentFundingTotal, ProjectStatus status, uint numberOfContributions) {

        return (projectDetails.name,
            projectDetails.ownerAddress,
            projectDetails.amountToBeRaised,
            projectDetails.deadlineTime,
            projectDetails.currentFundingTotal,
            projectDetails.status,
            contributions.length);
    }

      function sendFunds(address recipient, uint amount) private {
          Paid (recipient, amount);

          if(!recipient.send(amount)) {
              throw;
          }
      }

    function addContribution(address contributorAddress, uint amountToFund) private {
        uint index = contributions.length;
        contributions.length++;

        contributions[index].contributorAddress = contributorAddress;
        contributions[index].amountContributed = amountToFund;

        projectDetails.currentFundingTotal += amountToFund;

        ContributionMade(this, contributorAddress, amountToFund);
    }

    function isPassedDeadline() private returns(bool) {//超過限期時間
        return now > projectDetails.deadlineTime;
    }

    modifier onlyHub () {
        if (hubAddress != msg.sender) {
            throw;
        }
        _;
    }

    event ContributionMade(address projectAddress, address contributorAddress, uint amountContributed);

    event ProjectFullyFunded(address projectAddress);

    event ProjectNotFundedBeforeDeadline(address projectAddres);

    event Paid(address paidAddress, uint value);
}
