
# Payment Terminal

This project implements a simple payment terminal system with formal verification using Dafny.

## Requirements

- [Dafny](https://github.com/dafny-lang/dafny) programming language and verifier
- Python 3.x

> There is a dev environment in `shell.nix`, but if you don't know what it is, you can install everything by yourself.

## Project Structure

```shell
Payment_Terminal/
├── README.md
├── Makefile
└── Main.dfy    # Main implementation and verification file
```

## Running the Verification

1. Install Dafny and Python 3.x
2. Run verification and execute:

   ```shell
   make verify    # Run Dafny verification
   make run      # Execute Python implementation
   make all      # Run both verification and execution
   ```

## Verification Properties

The specification verifies the following properties:

- Transaction consistency
- Payment authorization flow
- Error handling states

For detailed information about the verification, refer to the comments in `Main.dfy`.
