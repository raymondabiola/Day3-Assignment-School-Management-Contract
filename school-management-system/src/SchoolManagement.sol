// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;
import {ERC20Token} from "../src/ERC20Token.sol";

contract SchoolManagement {

    ERC20Token public erc20Token;

    address public principal;
    address public vicePrincipal;
    uint32 private studentRegNo;
    uint32 private staffRegNo;

    struct Student{
        uint32 regNo;
        string name;
        bytes32 sex;
        uint8 age;
        uint16 grade;
        bool isFeePaid;
        bool isRegistered;
        uint paymentTimestamp;
    }
    mapping(address => Student) private studentData;

    struct Staff{
        uint32 regNo;
        string name;
        bytes32 sex;
        bytes32 maritalStatus;
        bytes32 role;
        bool isStaff;
        uint paymentTimestamp;
    }
    mapping(address => Staff) private staffData;

    mapping(uint16 => uint) gradeFee;
    mapping(bytes32 => uint) staffSalary;

    event StudentFeeWasPaid(address indexed studentAddress,uint16 indexed grade, uint indexed feePaid);
    event StaffSalaryWasPaid(address indexed staffAddress, string indexed role, uint indexed salary);

    constructor(address _erc20TokenAddress){
        erc20Token = ERC20Token(_erc20TokenAddress);
        principal = msg.sender;
    }

    modifier onlyPrincipal(){
        require(msg.sender == principal, "You are not the principal");
        _;
    }

    modifier onlyManagement(){
        require(msg.sender == principal || msg.sender == vicePrincipal, "You are not the vice principal");
        _;
    }

    function setVicePrincipal(address _address)external onlyPrincipal {
        vicePrincipal = _address;
    }

    function changePrincipal(address _address) external onlyPrincipal{
        principal = _address;
    }

    function setGradeFee(uint16 _grade, uint _fee)external onlyPrincipal{
        require(_grade == 100 || _grade == 200 || _grade == 300 || _grade == 400, "Invalid grade inputed");
        require(_fee > 0, "Fee must be more than 0");
        gradeFee[_grade] = _fee;
    }

    function setStaffSalary(string memory _role, uint _salary) external onlyPrincipal{
    require(getHash(_role) == getHash("Teacher") || getHash(_role) == getHash("HOD") || getHash(_role) == getHash("Management"), "Invalid Role");
    require(_salary > 0, "Salary must be more than 0");
    bytes32 roleHash = getHash(_role);
    staffSalary[roleHash] = _salary;
    }

    function payFee(address _address, uint16 _grade, uint _feeAmount) external {
    require(_grade == 100 || _grade == 200 || _grade == 300 || _grade == 400, "Invalid grade inputed");
      uint studentGradeFee = gradeFee[_grade];
      require(_feeAmount == studentGradeFee, "Invalid fee Amount");
    erc20Token.transferFrom(_address, address(this), _feeAmount);
    studentData[_address].isFeePaid = true;
    studentData[_address].paymentTimestamp = block.timestamp;
    emit StudentFeeWasPaid(_address, _grade, _feeAmount);
    }

    function registerStudent(address _address, string memory _name, string memory _sex, uint8 _age, uint16 _grade) external onlyManagement{
    require(studentData[_address].isFeePaid, "Student has not paid fee");
    require(_grade == 100 || _grade == 200 || _grade == 300 || _grade == 400, "Invalid grade inputed");

    studentRegNo = studentRegNo + 1;
    studentData[_address].regNo = studentRegNo;
    studentData[_address].name = _name;
    studentData[_address].sex = getHash(_sex);
    studentData[_address].age = _age;
    studentData[_address].grade = _grade;
    studentData[_address].isRegistered = true;
    }

    function getHash(string memory _text)pure internal returns(bytes32){
        return keccak256(abi.encodePacked(_text));
    }

    function registerStaff(address _address, string memory _name, string memory _sex, string memory _maritalStatus, string memory _role) external onlyPrincipal{
    require(getHash(_sex) == getHash("M") || getHash(_sex) == getHash("F"), "Invalid Sex");
    require(getHash(_maritalStatus) == getHash("Single") || getHash(_maritalStatus) == getHash("Married"), "Invalid marital status");
    require(getHash(_role) == getHash("Teacher") || getHash(_role) == getHash("HOD") || getHash(_role) == getHash("Management"), "Invalid Role");
    
    staffRegNo = staffRegNo + 1;
    staffData[_address].regNo = staffRegNo;
    staffData[_address].name = _name;
    staffData[_address].sex = getHash(_sex);
    staffData[_address].maritalStatus = getHash(_maritalStatus);
    staffData[_address].role = getHash(_role);
    staffData[_address].isStaff = true;
    }

    function newSessionStudentDataUpdate(address _address, uint8 _age, uint16 _grade)external{
    require(_grade == 100 || _grade == 200 || _grade == 300 || _grade == 400, "Invalid grade inputed");
    studentData[_address].age = _age;
    studentData[_address].grade = _grade;
    studentData[_address].isFeePaid = false;
    }

    function payStaff(address _address, string memory _role) external onlyPrincipal{
    require(staffData[_address].isStaff, "Not a registered staff");
    require(getHash(_role) == getHash("Teacher") || getHash(_role) == getHash("HOD") || getHash(_role) == getHash("Management"), "Invalid Role");
    bytes32 roleHash = getHash(_role);
    require(staffData[_address].role == roleHash, "Role mismatch");
    uint salary = staffSalary[roleHash];
    require(salary <= erc20Token.balanceOf(address(this)), "Insufficient contract balance");
    erc20Token.transfer(_address, salary);
    staffData[_address].paymentTimestamp = block.timestamp;
    emit StaffSalaryWasPaid(_address, _role, salary);
    }

    // View Functions
    function getStudentData(address _address) external view returns(Student memory){
        return studentData[_address];
    }

    function getStaffData(address _address) external view returns(Staff memory){
        return staffData[_address];
    }
}