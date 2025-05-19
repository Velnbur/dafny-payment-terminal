/*
 * Formal verification of the "Payment Terminal" system in Dafny
 * Based on the provided LaTeX specification
 */

// Ensures that the PIN code is a valid 4-digit number
predicate ValidPinCode(pin: nat)
{
  pin < 10000
}

predicate ValidCardId(id: nat)
{
  id > 0 && id < 100000000000 // 10-digit card ID 
}

// Data types and state definitions
class Card {
  var id: nat
  var pinCode: nat
  var isBlocked: bool
  var balance: nat // Balance in cents (integer instead of real)

  constructor(cardId: nat, pin: nat, blocked: bool, initialBalance: nat)
    requires ValidCardId(cardId)
    requires ValidPinCode(pin)
    ensures pinCode == pin
    ensures isBlocked == blocked
    ensures balance == initialBalance
    ensures id == cardId
  {
    id := cardId;
    pinCode := pin;
    isBlocked := blocked;
    balance := initialBalance;
  }
}

class TransactionData {
  var amount: nat  // Amount in cents
  var remainingBalance: nat  // Remaining balance in cents

  constructor(transAmount: nat, remBalance: nat)
    ensures amount == transAmount
    ensures remainingBalance == remBalance
  {
    amount := transAmount;
    remainingBalance := remBalance;
  }
}

class Terminal {
  var isConnectedToNetwork: bool
  var paper: nat // Length of left paper
  var authorizedUser: nat // Currently authorized user ID
  var lastTransactionData: TransactionData?

  constructor(connected: bool, paperLength: nat)
    requires paperLength > 0
    ensures isConnectedToNetwork == connected
    ensures paper == paperLength
    ensures lastTransactionData == null
    ensures authorizedUser == 0
  {
    isConnectedToNetwork := connected;
    paper := paperLength;
    lastTransactionData := null;
    authorizedUser := 0;
  }

  // Функція: Авторизація користувача
  method Authorize(card: Card, enteredPin: nat) returns (success: bool)
    requires ValidPinCode(enteredPin)
    requires authorizedUser == 0
    requires lastTransactionData == null
    modifies this
    ensures paper == old(paper)
    ensures isConnectedToNetwork == old(isConnectedToNetwork)
    ensures lastTransactionData == null
    ensures !isConnectedToNetwork || enteredPin != card.pinCode || card.isBlocked ==> !success
    ensures isConnectedToNetwork && enteredPin == card.pinCode && !card.isBlocked ==> success
    ensures !success ==> authorizedUser == 0
    ensures success ==> authorizedUser == card.id
  {
    success := false;  // Initialize with false by default

    if (!isConnectedToNetwork) {
      return;
    }

    if (enteredPin != card.pinCode) {
      return;
    }

    if (card.isBlocked) {
      return;
    }

    // All conditions are met
    success := true;
    authorizedUser := card.id;
  }
 
  // Функція: Проведення транзакції
  method ProcessTransaction(card: Card, amount: nat) returns (success: bool)
    requires authorizedUser != 0
    requires lastTransactionData == null
    modifies this, card
    ensures paper == old(paper) 
    ensures authorizedUser == old(authorizedUser)
    ensures isConnectedToNetwork == old(isConnectedToNetwork)
    ensures card.id == old(card.id)
    ensures card.pinCode == old(card.pinCode)
    ensures card.isBlocked == old(card.isBlocked)
    ensures !isConnectedToNetwork || authorizedUser != card.id || old(card.balance) < amount ==> !success
    ensures isConnectedToNetwork && authorizedUser == card.id && card.balance >= amount ==> success
    ensures success ==> card.balance == old(card.balance) - amount
    ensures success ==> lastTransactionData != null && lastTransactionData.amount == amount && lastTransactionData.remainingBalance == card.balance
    ensures !success ==> card.balance == old(card.balance) && lastTransactionData == null
  {
    success := false;  // Initialize with false by default-

    if (!isConnectedToNetwork) {
      return;
    }

    if (authorizedUser != card.id) {
      return;
    }

    if (card.balance < amount) {
      return;
    }

    // All conditions are met
    card.balance := card.balance - amount;
    lastTransactionData := new TransactionData(amount, card.balance);
    success := true;
  }

  // Функція: Видача чеку
  method PrintReceipt() returns (success: bool)
    requires authorizedUser != 0
    requires lastTransactionData != null
    modifies this
    ensures isConnectedToNetwork == old(isConnectedToNetwork)
    ensures old(paper) == 0 ==> !success
    ensures old(paper) > 0 ==> success
    ensures !success ==> paper == old(paper) && lastTransactionData == old(lastTransactionData) && authorizedUser == old(authorizedUser)
    ensures success ==> paper == old(paper) - 1 && lastTransactionData == null && authorizedUser == 0
  {
    success := false;  // Initialize with false by default
    
    if (paper == 0) {
      return;
    }

    // All conditions are met
    paper := paper - 1; // Decrease paper length
    lastTransactionData := null; // Clear last transaction data
    authorizedUser := 0; // Reset authorized user
    success := true;
  }
  
  method ResetPaper(paperLength: nat)
    requires paperLength > 0
    modifies this
    ensures paper == paperLength
    ensures lastTransactionData == old(lastTransactionData)
    ensures authorizedUser == old(authorizedUser)
    ensures isConnectedToNetwork == old(isConnectedToNetwork)
  {
    paper := paperLength;
  }

  method Cancel()
    modifies this
    ensures lastTransactionData == null
    ensures authorizedUser == 0
    ensures isConnectedToNetwork == old(isConnectedToNetwork)
    ensures paper == old(paper)
  {
    lastTransactionData := null;
    authorizedUser := 0;
  }
}

method Main()
{
  print "Payment Terminal System Verification\n";

  // Create a card with 1000.00 (100000 cents) balance
  var card := new Card(100_000_000, 1234, false, 100000);

  // Create a terminal connected to network with paper
  var terminal := new Terminal(true, 5);

  // Authorization
  print "Testing Authorization...\n";
  var authSuccess := terminal.Authorize(card, 1234);
  print "Authorization ", if authSuccess then "succeeded" else "failed", "\n";
  if (!authSuccess) {
    return;
  }

  print "Testing Transaction...\n";
  var transAmount: nat := 50000; // $500.00
  var transSuccess := terminal.ProcessTransaction(card, transAmount);

  print "Transaction for ", transAmount, " cents ", 
        if transSuccess then "succeeded" else "failed", "\n";

  if (transSuccess) {
    print "Remaining balance: ", card.balance, " cents\n";
  }

  print "Testing Receipt Printing...\n";
  var receiptSuccess := terminal.PrintReceipt();
  print "Receipt printing ", if receiptSuccess then "succeeded" else "failed", "\n";
  
  print "Verification complete!\n";
}

/* Tests section */

method {:test} TestValidPinCode()
{
  assert ValidPinCode(1234);
  assert !ValidPinCode(12345);
}

method {:test} TestValidCardId()
{
  assert ValidCardId(1234567890);
  assert !ValidCardId(0);
  assert !ValidCardId(100000000000);
}

method {:test} TestCardConstructor()
{
  var card := new Card(1234567890, 1234, false, 100000);
  assert card.id == 1234567890;
  assert card.pinCode == 1234;
  assert !card.isBlocked;
  assert card.balance == 100000;
}

method {:test} TestTerminalConstructor()
{
  var terminal := new Terminal(true, 5);
  assert terminal.isConnectedToNetwork;
  assert terminal.paper == 5;
  assert terminal.lastTransactionData == null;
  assert terminal.authorizedUser == 0;
}

method {:test} TestAuthorize()
{
  var pin := 1234;
  var card := new Card(1234567890, pin, false, 100000);
  var terminal := new Terminal(true, 5);
  
  var authSuccess := terminal.Authorize(card, pin);
  assert authSuccess;
  assert terminal.authorizedUser == card.id;

  terminal.Cancel();

  var authFail := terminal.Authorize(card, 1235);
  assert !authFail;
  assert terminal.authorizedUser == 0;
}

method {:test} TestProcessTransaction()
{
  var card := new Card(1234567890, 1234, false, 100000);
  var terminal := new Terminal(true, 5);
  
  var auth := terminal.Authorize(card, 1234);
  assert auth;
  
  var transSuccess := terminal.ProcessTransaction(card, 50000);
  assert transSuccess;
  assert card.balance == 50000;

  terminal.Cancel();
  auth := terminal.Authorize(card, 1234);
  assert auth;

  var transFail := terminal.ProcessTransaction(card, 60000);
  assert !transFail;
  assert card.balance == 50000;
  assert terminal.lastTransactionData == null;
}

method {:test} UnavailableNetworkTerminal()
{
  var card := new Card(1234567890, 1234, false, 100000);
  var terminal := new Terminal(true, 5);
  
  var auth := terminal.Authorize(card, 1234);
  assert auth;

  terminal.isConnectedToNetwork := false; // Simulate network disconnection
  
  var transSuccess := terminal.ProcessTransaction(card, 50000);
  assert !transSuccess;
}

method {:test} TestPrintReceipt()
{
  var card := new Card(1234567890, 1234, false, 100000);
  var terminal := new Terminal(true, 1);
  
  var auth := terminal.Authorize(card, 1234);
  assert auth;

  var transSuccess := terminal.ProcessTransaction(card, 50000);
  assert transSuccess;

  var receiptSuccess := terminal.PrintReceipt();
  assert receiptSuccess;
  assert terminal.paper == 0;

  auth := terminal.Authorize(card, 1234);
  assert auth;

  transSuccess := terminal.ProcessTransaction(card, 10000);
  assert transSuccess;

  receiptSuccess := terminal.PrintReceipt();
  assert !receiptSuccess;

  terminal.ResetPaper(5);

  receiptSuccess := terminal.PrintReceipt();
  assert receiptSuccess;
}