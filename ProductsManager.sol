import "ManufacturersManager.sol";

contract ProductsManager {
  /*****************/
  /*** Variables ***/
  /*****************/
  address manufacturer;
  enum ProductStatus {Shipped, Owned, InRecall, Destroyed}
  // products: is a mapping EPC (bytes32) into ProductInfo.
  mapping (uint96 => ProductInfo) products;
	// Give incentive if the number of transfer is less than MAXTRANSFER. 
	uint8 MAXTRANSFER = 10;
	uint transferReward = 1; // Ether.

  // ProductInfo: is a struct that contains product information, e.g., current owner and status.
  struct ProductInfo {
    address owner;
    address recipient;
    ProductStatus status;
    uint creationTime;
    uint8 nTransferred;
  }

  /*****************/
  /*** Modifiers ***/
  /*****************/
  modifier onlyManufacturer() {
    if (msg.sender != manufacturer) {
      throw;
    }
    _
  }

  modifier onlyOwner(uint96 EPC) {
    if (products[EPC].owner != msg.sender) {
      throw;
    }
    _
  }

	modifier onlyRecipient(uint96 EPC) {
		if (msg.sender != products[EPC].recipient) {
			throw;
		}
		_
	}

	modifier onlyStatusIs(uint96 EPC, ProductStatus status) {
		if (status != products[EPC].status) {
			throw;
		}
		_
	}

  modifier onlyNotExist(uint96 EPC) {
    if (products[EPC].owner != 0x0) {
      throw;
    }
    _
  }

  modifier onlyExist(uint96 EPC) {
    if (products[EPC].owner == 0x0) {
      throw;
    }
    _
  }

  /*****************/
  /**** Events *****/
  /*****************/
  event ProductEnrolled(uint96 EPC, address owner);
  event ProductShipped(uint96 EPC, address owner);
  event OwnershipTransferred(uint96 EPC, address newOwner);
  event ProductDestroyed(uint96 EPC);

  /*****************/
  /** Constructor **/
  /*****************/
  function ProductsManager() {
    manufacturer = msg.sender;
  }

  /*****************/
  /*** Functions ***/
  /*****************/
	function enrollProduct(address mmAddr, uint96 EPC, uint40 companyPrefix) 
		onlyNotExist(EPC) 
		onlyManufacturer {
			if (EPC == 0) {
				throw;
			} 

			ManufacturersManager mm = ManufacturersManager(mmAddr);

			// At first, check whether a manufacturer possesses the right of the claimed EPC. 
			if (mm.checkAuthorship(EPC)) {
				products[EPC].owner = manufacturer;
				products[EPC].status = ProductStatus.Owned;
				products[EPC].creationTime = now;
				products[EPC].nTransferred = 0;
				// call an event.
				ProductEnrolled(EPC, products[EPC].owner);
			}
  }

  function shipProduct(address recipient, uint96 EPC) 
		onlyExist(EPC) 
		onlyOwner(EPC) 
		onlyStatusIs(EPC, ProductStatus.Owned) {
			if (recipient == products[EPC].owner) {
				throw;
			} else {
				products[EPC].status = ProductStatus.Shipped;
				products[EPC].recipient = recipient;
				// call an event.
				ProductShipped(EPC, recipient);
			}
  }

	function receiveProduct(uint96 EPC) 
		onlyExist(EPC) 
		onlyRecipient(EPC)
	 	onlyStatusIs(EPC, ProductStatus.Shipped) {
			// transfer ownership.
			products[EPC].owner = msg.sender;
			products[EPC].status = ProductStatus.Owned;
			products[EPC].nTransferred = products[EPC].nTransferred + 1;
			if (products[EPC].nTransferred <= MAXTRANSFER) {
				msg.sender.send(transferReward);
			}
			// call an event to inform the recipient of success of ownership transfer.
			OwnershipTransferred(EPC, products[EPC].owner);
	}

	function getRecipient(uint96 EPC) onlyExist(EPC) 
		onlyStatusIs(EPC, ProductStatus.Shipped) returns (address) {
		return products[EPC].recipient;
	}

  function getCurrentOwner(uint96 EPC) onlyExist(EPC) returns (address) {
    return products[EPC].owner;
  }

  function getProductStatus(uint96 EPC) onlyExist(EPC) returns (ProductStatus) {
    return products[EPC].status;
  }

  function getCreationTime(uint96 EPC) onlyExist(EPC) returns (uint) {
    return products[EPC].creationTime;
  }

  function destroyProduct(uint96 EPC) 
		onlyExist(EPC) 
		onlyOwner(EPC) {
			products[EPC].owner = 0x0;
			products[EPC].recipient = 0x0;
			products[EPC].status = ProductStatus.Destroyed;
	}

  function kill() onlyManufacturer {
    suicide(manufacturer);
  }

}
