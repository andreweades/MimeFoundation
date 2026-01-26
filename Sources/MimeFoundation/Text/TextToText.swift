//
// TextToText.swift
//
// Ported from MimeKit (C#) to Swift.
//

/// A text to text converter.
///
/// A pass-through converter that copies plain text from input to output,
/// optionally adding header and footer content.
public final class TextToText: TextConverter {
    /// Initializes a new instance of the ``TextToText`` class.
    ///
    /// Creates a new text to text converter.
    public override init() {
        super.init()
    }

    /// Gets the input format.
    ///
    /// Always returns ``TextFormat/plain`` for this converter.
    public override var inputFormat: TextFormat {
        .plain
    }

    /// Gets the output format.
    ///
    /// Always returns ``TextFormat/plain`` for this converter.
    public override var outputFormat: TextFormat {
        .plain
    }

    /// Converts the contents of the reader from the ``inputFormat`` to the ``outputFormat``
    /// and uses the writer to write the resulting text.
    ///
    /// Copies the contents of the reader to the writer, optionally adding header
    /// and footer text.
    ///
    /// - Parameters:
    ///   - reader: The text reader providing the plain text input.
    ///   - writer: The text writer to receive the plain text output.
    public override func convert(_ reader: TextReadable, _ writer: TextWritable) {
        if let header, !header.isEmpty {
            writer.write(header)
        }

        let content = reader.readToEnd()
        if !content.isEmpty {
            writer.write(content)
        }

        if let footer, !footer.isEmpty {
            writer.write(footer)
        }
    }
}
