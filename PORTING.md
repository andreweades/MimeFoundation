# MimeFoundation Porting Status

Legend: ✅ done, 🟡 partial, ⬜️ not started

Notes:
- Use Swift Testing (not XCTest).
- Keep strict concurrency; avoid `@unchecked Sendable`.

## Encodings
- ✅ Base64DecoderTests
- ✅ Base64EncoderTests
- ✅ HexDecoderTests
- ✅ HexEncoderTests
- ✅ MimeDecoderTestsBase
- ✅ MimeEncoderTestsBase
- ✅ PassThroughDecoderTests
- ✅ PassThroughEncoderTests
- ✅ PunycodeTests
- ✅ QEncoderTests
- ✅ QuotedPrintableDecoderTests
- ✅ QuotedPrintableEncoderTests
- ✅ Rfc2047Base64EncoderTests
- ✅ Rfc2047QuotedPrintableEncoderTests
- ✅ UUDecoderTests
- ✅ UUEncoderTests
- ✅ YDecoderTests
- ✅ YEncoderTests
- ✅ YEncodingTests

## Utils
- ✅ ByteArrayBuilderTests
- ✅ CharsetUtilsTests
- ✅ DateParserTests
- ✅ MimeUtilsTests
- ✅ OptimizedOrdinalComparerTests
- ✅ PackedByteArrayTests
- ✅ ParseUtilsTests
- ✅ Rfc2047Tests
- ✅ StringBuilderExtensionTests
- ✅ ValueStringBuilderTests

## Addressing
- ✅ DomainListTests
- ✅ MailboxAddressTests
- ✅ GroupAddressTests
- ✅ InternetAddressListTests
- ✅ InternetAddressTests
- ✅ InternetAddressConverterTests
- ✅ InternetAddressListConverterTests

## Headers
- ✅ HeaderTests
- ✅ HeaderListTests
- ✅ HeaderListCollectionTests

## Format/Parser
- ✅ FormatOptionsTests
- ✅ ParserOptionsTests
- ✅ ArgumentExceptionTests
- ✅ ExceptionTests
- ✅ AssortedTests

## Parameters & Types
- ✅ ParameterTests
- ✅ ParameterListTests
- ✅ ContentTypeTests
- ✅ ContentDispositionTests
- ✅ MimeTypeTests

## MIME Entities
- ✅ MimePartTests
- ✅ MimeContentTests
- ✅ MessagePartTests
- ✅ TextPartTests
- ✅ TextRfc822HeadersTests
- ✅ MultipartTests
- ✅ MultipartAlternativeTests
- ✅ MultipartRelatedTests
- ✅ MultipartReportTests

## Message Layer
- ✅ MimeMessageTests
- ✅ ConstructorTests
- ✅ BodyBuilderTests
- ✅ AttachmentCollectionTests
- ✅ MessageIdListTests
- ✅ MessageDeliveryStatusTests
- ✅ MessageDispositionNotificationTests
- ✅ MessageFeedbackReportTests
- ✅ MessagePartialTests
- ✅ MimeIteratorTests
- ✅ MimeVisitorTests
- ✅ MimeAnonymizerTests

## Parser/Reader
- ✅ MimeParserTests
- ✅ ExperimentalMimeParserTests
- ✅ MimeReaderTests

## IO / Streams
- ✅ BoundStreamTests
- ✅ CanReadWriteSeekStream
- ✅ ChainedStreamTests
- ✅ FilteredStreamTests
- ✅ MeasuringStreamTests
- ✅ MemoryBlockStreamTests
- ✅ ReadOneByteStream
- ✅ TimeoutStream
- ✅ DecoderFilterTests
- ✅ EncoderFilterTests
- ✅ FilterTests

## Text Converters
- ✅ FlowedToHtmlTests
- ✅ FlowedToTextTests
- ✅ HtmlToHtmlTests
- ✅ TextToFlowedTests
- ✅ TextToHtmlTests
- ✅ TextToTextTests

## TNEF
- ⬜️ TnefReaderTests
- ⬜️ TnefTests

## Cryptography
- ✅ AuthenticationResultsTests
- ✅ DkimRelaxedBodyFilterTests
- ✅ DkimHashStreamTests
- ✅ DkimSignatureStreamTests
- ✅ DkimPublicKeyLocatorBaseTests
- ✅ DkimTests
- ⬜️ ArcSignerTests
- ⬜️ ArcVerifierTests
- ✅ DkimSignerTests
- ✅ DkimVerifierTests
- ⬜️ OpenPgpTests
- ⬜️ S/MIME (unimplemented; requires CMS/X.509 backend decision)
