// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;
import {ERC20Token} from "../src/ERC20Token.sol";

contract SchoolManagement {

    ERC20Token public erc20Token;

    address public principal;
    address public vicePrincipal;
    uint32 private studentRegNo;
    uint32 private staffRegNo;
    uint32 private month;

    struct StudentPaymentData{
        uint feeAmount;
        bool isFeePaid;
        uint paymentTimestamp;
    }
    mapping(address => mapping(uint => StudentPaymentData)) private studentGradePaymentData;

    struct StudentBio{
        uint32 regNo;
        string name;
        string gender;
        uint8 age;
        bool isRegistered;
    }
    mapping(address => StudentBio) private studentBio;

    struct StaffSalaryPaymentData{
        bool isSalaryPaid;
        uint salaryAmountPaid;
        uint paymentTimestamp;
    }
    mapping(address => mapping(uint => StaffSalaryPaymentData)) private staffMonthlySalaryPayment;

    struct StaffBio{
        uint32 regNo;
        string name;
        string gender;
        string maritalStatus;
        string role;
        bool isStaff;
    }
    mapping(address => StaffBio) private staffBio;

    mapping(uint16 => uint) private gradeFee;
    mapping(bytes32 => uint) private staffSalary;
    
    event StudentWasRegistered(string indexed name, address indexed _address, string gender, uint age, uint grade);
    event StaffWasRegistered(string indexed name, address indexed _address, string gender, string maritalStatus, string role);
    event StudentFeeWasPaid(address indexed studentAddress,uint16 indexed grade, uint indexed feePaid);
    event StaffSalaryWasPaid(string indexed name, address indexed staffAddress, string indexed role, uint salary);

    constructor(address _erc20TokenAddress, uint _grade100Fee, uint _grade200Fee, uint _grade300Fee, uint _grade400Fee){
        erc20Token = ERC20Token(_erc20TokenAddress);
        principal = msg.sender;
        gradeFee[100] = _grade100Fee;
        gradeFee[200] = _grade200Fee;
        gradeFee[300] = _grade300Fee;
        gradeFee[400] = _grade400Fee;
        month = 1;
    }

    modifier onlyPrincipal(){
        require(msg.sender == principal, "You are not the principal");
        _;
    }

    modifier onlyManagement(){
        require(msg.sender == principal || msg.sender == vicePrincipal, "Only management can call this function");
        _;
    }

    function setVicePrincipal(address _address)external onlyPrincipal {
        vicePrincipal = _address;
    }

    function changePrincipal(address _address) external onlyPrincipal{
        principal = _address;
    }

    // Enter 100 or 200 or 300 or 400 for grade
    function updateGradeFee(uint16 _grade, uint _fee)external onlyPrincipal{
        require(_grade == 100 || _grade == 200 || _grade == 300 || _grade == 400, "Invalid grade inputed");
        require(_fee > 0, "Fee must be more than 0");
        gradeFee[_grade] = _fee;
    }

    // Enter Teacher or HOD or Management for _role, case sensitive
    function updateStaffSalary(string memory _role, uint _salary) external onlyPrincipal{
    bytes32 roleHash = getHash(_role);
    require(roleHash == getHash("Teacher") || roleHash == getHash("HOD") || roleHash == getHash("Management"), "Invalid Role");
    require(_salary > 0, "Salary must be more than 0");
    staffSalary[roleHash] = _salary;
    }

    // Enter 100 or 200 or 300 or 400 for grade
    function payStudentFee(address _address, uint16 _grade, uint _feeAmount) external {
    require(_address != address(0), "Invalid Address");
    require(_address.code.length == 0, "Contract address inputed");
    require(_grade == 100 || _grade == 200 || _grade == 300 || _grade == 400, "Invalid grade inputed");
    uint studentGradeFee = gradeFee[_grade];
    require(_feeAmount == studentGradeFee, "Invalid fee Amount");

    erc20Token.transferFrom(_address, address(this), _feeAmount);
    studentGradePaymentData[_address][_grade].isFeePaid = true;
    studentGradePaymentData[_address][_grade].feeAmount = _feeAmount;
    studentGradePaymentData[_address][_grade].paymentTimestamp = block.timestamp;

    emit StudentFeeWasPaid(_address, _grade, _feeAmount);
    }

    // Enter M or F for _gender, case sensitive
    // Enter 100 for grade
    function registerStudent(string memory _name, address _address, string memory _gender, uint8 _age, uint16 _grade) external onlyManagement{
    require(_grade == 100, "Student is not a fresher");
    require(studentGradePaymentData[_address][100].isFeePaid, "Student has not paid grade 100 fee");
    require(bytes(_name).length > 0, "Cannot input empty string");
    require(_address != address(0), "Invalid Address");
    require(!staffBio[_address].isStaff, "You cannot register a staff as student");
    require(_address.code.length == 0, "Contract address inputed");
    require(!studentBio[_address].isRegistered, "Already a student");
    bytes32 genderHash = getHash(_gender);
    require(genderHash == getHash("M") || genderHash == getHash("F"), "Invalid gender inputed");
    require(_age > 0, "Invalid age input");

    studentRegNo = studentRegNo + 1;
    studentBio[_address].regNo = studentRegNo;
    studentBio[_address].name = _name;
    studentBio[_address].gender = _gender;
    studentBio[_address].age = _age;
    studentBio[_address].isRegistered = true;

    emit StudentWasRegistered(_name, _address, _gender, _age, _grade);
    }

    // Internal helper function
    function getHash(string memory _text)pure internal returns(bytes32){
        return keccak256(abi.encodePacked(_text));
    }

    // Enter M,F for _gender , case sensitive
    // Enter Single or Married for _maritalStatus, case sensitive
    // Enter Teacher or HOD or Management for _role, case sensitive
    function registerStaff(string memory _name, address _address, string memory _gender, string memory _maritalStatus, string memory _role) external onlyPrincipal{
    require(_address != address(0), "Invalid Address");
    require(!staffBio[_address].isStaff, "Already a staff");
    require(!studentBio[_address].isRegistered, "You cannot register a student as staff");
    require(_address.code.length == 0, "Contract address inputed");
    require(bytes(_name).length > 0, "Cannot input empty string");
    bytes32 genderHash = getHash(_gender);
    bytes32 roleHash = getHash(_role);
    bytes32 maritalStatusHash = getHash(_maritalStatus);
    require(genderHash == getHash("M") || genderHash == getHash("F"), "Invalid gender inputed");
    require(maritalStatusHash == getHash("Single") || maritalStatusHash == getHash("Married"), "Invalid marital status");
    require(roleHash == getHash("Teacher") || roleHash == getHash("HOD") || roleHash == getHash("Management"), "Invalid Role");
    
    staffRegNo = staffRegNo + 1;
    staffBio[_address].regNo = staffRegNo;
    staffBio[_address].name = _name;
    staffBio[_address].gender = (_gender);
    staffBio[_address].maritalStatus = _maritalStatus;
    staffBio[_address].role = _role;
    staffBio[_address].isStaff = true;

    emit StaffWasRegistered(_name, _address, _gender, _maritalStatus, _role);
    }

    // External function to update Student Age
    function updateStudentAge(address _address, uint8 _age)external onlyManagement{
    require(studentBio[_address].isRegistered, "Not a student");
    require(_age > 0, "Invalid age input");
    studentBio[_address].age = _age;
    }

    // Enter Teacher or HOD or Management for _role, case sensitive
    function payStaff(address _address, string memory _role) external onlyPrincipal{
    require(staffBio[_address].isStaff, "Not a registered staff");
    require(!staffMonthlySalaryPayment[_address][month].isSalaryPaid, "Salary Already paid for current month");
    bytes32 roleHash = getHash(_role);
    require(roleHash == getHash("Teacher") || roleHash == getHash("HOD") || roleHash == getHash("Management"), "Inputed role does not exist");
    require(getHash(staffBio[_address].role) == roleHash, "Wrong role inputed for staff");

    string memory staffName = staffBio[_address].name;
    uint salary = staffSalary[roleHash];
    require(salary <= erc20Token.balanceOf(address(this)), "Insufficient school balance");

    erc20Token.transfer(_address, salary);
    staffMonthlySalaryPayment[_address][month].isSalaryPaid = true;
    staffMonthlySalaryPayment[_address][month].salaryAmountPaid = salary;
    staffMonthlySalaryPayment[_address][month].paymentTimestamp = block.timestamp;

    emit StaffSalaryWasPaid(staffName, _address, _role, salary);
    }

    function setNewMonth(uint32 _month)external onlyPrincipal{
        month = _month;
    }

    // View Functions
    function getStudentBio(address _address) external view returns(StudentBio memory){
        return studentBio[_address];
    }

    function getStudentYearlyPaymentData(address _address, uint _grade)external view returns(StudentPaymentData memory){
        return studentGradePaymentData[_address][_grade];
    }

    function getStaffBio(address _address) external view returns(StaffBio memory){
        return staffBio[_address];
    }

    function getStaffMonthlyPaymentData(address _address, uint _month)external view returns(StaffSalaryPaymentData memory){
        return staffMonthlySalaryPayment[_address][_month];
    }

    function getCurrentMonth()external view returns(uint32) {
        return month;
    }

    function getGradeFee(uint16 _grade)external view returns(uint){
        return gradeFee[_grade];
    }

    function getStaffSalary(string memory _role) external view returns(uint){
        bytes32 roleHash = getHash(_role);
        return staffSalary[roleHash];
    }

    function getSchoolBalance()external view returns(uint){
        return erc20Token.balanceOf(address(this));
    }
}