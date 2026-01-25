# MimeFoundation Makefile

.PHONY: build test test-smime test-with-openssl clean

# Default target
all: build

# Build the package
build:
	swift build

# Run all tests
test:
	swift test

# Run only S/MIME tests
test-smime:
	swift test --filter SecureMime

# Run S/MIME tests and verify with OpenSSL
# This target runs the tests, extracts the signed message, and verifies it with openssl
test-with-openssl:
	@echo "=== Running S/MIME tests ==="
	@swift test --filter "SecureMimeTests/generateSignedMessageForOpenSSL" 2>&1 | tee /tmp/smime-test-output.txt
	@echo ""
	@echo "=== Verifying signature with OpenSSL ==="
	@SIGNED_MSG="$${TMPDIR}signed-message.eml"; \
	CERT_FILE="$${TMPDIR}test-cert.pem"; \
	if [ -f "$$SIGNED_MSG" ] && [ -f "$$CERT_FILE" ]; then \
		echo "Signed message: $$SIGNED_MSG"; \
		echo "Certificate: $$CERT_FILE"; \
		echo ""; \
		openssl smime -verify -in "$$SIGNED_MSG" -CAfile "$$CERT_FILE" -noverify; \
		RESULT=$$?; \
		echo ""; \
		if [ $$RESULT -eq 0 ]; then \
			echo "✅ OpenSSL verification PASSED"; \
		else \
			echo "❌ OpenSSL verification FAILED"; \
			exit 1; \
		fi \
	else \
		echo "❌ Error: Signed message or certificate not found"; \
		echo "   Expected: $$SIGNED_MSG"; \
		echo "   Expected: $$CERT_FILE"; \
		exit 1; \
	fi

# Clean build artifacts
clean:
	swift package clean
	rm -f /tmp/smime-test-output.txt

# Help target
help:
	@echo "MimeFoundation Makefile targets:"
	@echo "  build            - Build the package"
	@echo "  test             - Run all tests"
	@echo "  test-smime       - Run only S/MIME tests"
	@echo "  test-with-openssl - Run S/MIME test and verify with OpenSSL"
	@echo "  clean            - Clean build artifacts"
	@echo "  help             - Show this help message"
