//
// TextToText.swift
//
// Ported from MimeKit (C#) to Swift.
//

public final class TextToText: TextConverter {
    public override init() {
        super.init()
    }

    public override var inputFormat: TextFormat {
        .plain
    }

    public override var outputFormat: TextFormat {
        .plain
    }

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
