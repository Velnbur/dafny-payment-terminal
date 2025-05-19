DAFNY := dafny
DAFNY_OPTIONS := -t py

.PHONY: all
all: clean run

.PHONY: clean
clean:
	@echo "Cleaning up..."
	@rm -rf Main-py
	@echo "Cleaned up."

.PHONY: run
run:
	$(DAFNY) run $(DAFNY_OPTIONS) Main.dfy

.PHONY: test
test:
	$(DAFNY) test $(DAFNY_OPTIONS) Main.dfy
