contract ManufacturersManager {
  /*****************/
  /*** Variables ***/
  /*****************/
	address administrator;
	// manufacturers: mapping the addresses of manufacturers 
	// to company codes registered in GS1.
	mapping (address => ManufacturerInfo) manufacturers;

	// companyPrefixToAddress: reverse mapping from companyPrefix 
	// to manufacturer's address.
	mapping (uint40 => address) companyPrefixToAddress;

	struct ManufacturerInfo {
		uint40 companyPrefix;
		bytes32 companyName;
		uint expireTime;
	}

  /*****************/
  /*** Modifiers ***/
  /*****************/
	modifier onlyAdmin() {
		if (msg.sender != administrator) {
			throw;
		}
		_
	}

  /*****************/
  /** Constructor **/
  /*****************/
	function ManufacturersManager() {
		administrator = msg.sender;
	}

  /*****************/
  /*** Functions ***/
  /*****************/
	function enrollManufacturer(address manufacturer, 
															uint40 companyPrefix, 
															bytes32 companyName, 
															uint validDurationInYear) onlyAdmin {
		manufacturers[manufacturer].companyPrefix = companyPrefix;
		manufacturers[manufacturer].companyName = companyName;
		manufacturers[manufacturer].expireTime = now + validDurationInYear;

		// We also set the reverse map companyPrefix to manufacturer's address.
		companyPrefixToAddress[companyPrefix] = manufacturer;
	}

	function isAuthorized(address manufacturer) returns (bool) {
		if (manufacturers[manufacturer].companyPrefix == 0) {
			return false;
		} else {
			return true;
		}
	}

	function checkAuthorship(uint96 EPC, uint40 claimedCompanyPrefix) external returns (bool) {
		// checkAuthorship: returns whether a sender has authorship 
		// to claim the ownership of a given EPC.
		// More specifically, if a sender has the authorship of companyPrefix
		// written in the claimed EPC, this returns true. 
		// Otherwise, this returns false;

		uint40 companyPrefix = manufacturers[msg.sender].companyPrefix;

		if (companyPrefix == claimedCompanyPrefix) {
			return true;
		} else {
			return false;
    }

	}

	function getManufacturerAddress(uint96 EPC) external returns (address) {
		uint40 cp = getCompanyPrefixFrom(EPC);
		
		return companyPrefixToAddress[cp];
	}
}
