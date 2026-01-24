import Foundation
import Testing
import _CryptoExtras
@testable import MimeFoundation

@Suite
struct DkimVerifierTests {
    private final class DummyPublicKeyLocator: DkimPublicKeyLocator {
        private let key: DkimPublicKey

        init(_ key: DkimPublicKey) {
            self.key = key
        }

        func locatePublicKey(methods: String, domain: String, selector: String, cancellationToken: CancellationToken?) throws -> DkimPublicKey {
            key
        }

        func locatePublicKeyAsync(methods: String, domain: String, selector: String, cancellationToken: CancellationToken?) async throws -> DkimPublicKey {
            key
        }
    }

    private static func loadRsaPublicKey() throws -> DkimPublicKey {
        let url = TestHelper.dataURL(for: "dkim/example.pub")
        let pem = try String(contentsOf: url, encoding: .utf8)
        let key = try _RSA.Signing.PublicKey(unsafePEMRepresentation: pem)
        return .rsa(key)
    }

    @Test("DkimVerifier defaults")
    func dkimVerifierDefaults() throws {
        let publicKey = try Self.loadRsaPublicKey()
        let verifier = DkimVerifier(publicKeyLocator: DummyPublicKeyLocator(publicKey))

        #expect(verifier.minimumRsaKeyLength == 1024)
        #expect(verifier.isEnabled(.rsaSha1) == false)
        #expect(verifier.isEnabled(.rsaSha256) == true)
    }

    @Test("DkimVerifier enable/disable")
    func dkimVerifierEnableDisable() throws {
        let publicKey = try Self.loadRsaPublicKey()
        let verifier = DkimVerifier(publicKeyLocator: DummyPublicKeyLocator(publicKey))

        #expect(verifier.isEnabled(.rsaSha1) == false)
        verifier.enable(.rsaSha1)
        #expect(verifier.isEnabled(.rsaSha1) == true)
        verifier.disable(.rsaSha1)
        #expect(verifier.isEnabled(.rsaSha1) == false)
    }

    @Test("DkimVerifier argument exceptions")
    func dkimVerifierArgumentExceptions() throws {
        let publicKey = try Self.loadRsaPublicKey()
        let verifier = DkimVerifier(publicKeyLocator: DummyPublicKeyLocator(publicKey))
        let message = MimeMessage()
        let dkimHeader = Header(.dkimSignature, value: "value")
        let arcHeader = Header(.arcMessageSignature, value: "value")

        #expect(throws: DkimVerifierError.self) {
            _ = try verifier.verify(message, arcHeader)
        }
        #expect(throws: DkimVerifierError.self) {
            _ = try verifier.verify(.default, message, arcHeader)
        }

        #expect(throws: DkimVerifierError.self) {
            _ = try verifier.verify(message, dkimHeader)
        }
    }

    @Test("DkimVerifier argument exceptions async")
    func dkimVerifierArgumentExceptionsAsync() async throws {
        let publicKey = try Self.loadRsaPublicKey()
        let verifier = DkimVerifier(publicKeyLocator: DummyPublicKeyLocator(publicKey))
        let message = MimeMessage()
        let arcHeader = Header(.arcMessageSignature, value: "value")

        await #expect(throws: DkimVerifierError.self) {
            _ = try await verifier.verifyAsync(message, arcHeader)
        }

        await #expect(throws: DkimVerifierError.self) {
            _ = try await verifier.verifyAsync(.default, message, arcHeader)
        }
    }
}
