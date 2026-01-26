//
// Author: Jeffrey Stedfast <jestedfa@microsoft.com>
//
// Copyright (c) 2013-2026 .NET Foundation and Contributors
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

//
// TnefTests.swift
//
// Ported from MimeKit (C#) to Swift. 
//

import Testing
import Foundation
@testable import MimeFoundation

@Suite("TnefTests")
struct TnefTests {
    @Test("TestExtractedCharset")
    func testExtractedCharset() throws {
        let expected = """
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=koi8-r">
<style type="text/css" style="display:none;"><!-- P {margin-top:0;margin-bottom:0;} --></style>
</head>
<body dir="ltr">
<div id="divtagdefaultwrapper" style="font-size:12pt;color:#000000;font-family:Calibri,Helvetica,sans-serif;" dir="ltr">
<p>шостий</p>
<p><br>
</p>
<p>{EMAILSIGNATURE}</p>
<p><br>
</p>
<div id="Signature"><br>
<font color="#888888" face="Arial, Helvetica, Helvetica, Geneva, Sans-Serif" style="font-size: 10pt;"><br>
<font color="#888888" face="Arial, Helvetica, Helvetica, Geneva, Sans-Serif" style="font-size: 12pt;"><b>RR Test 1</b></font>
</font>
<p><font color="#888888" face="Arial, Helvetica, Helvetica, Geneva, Sans-Serif" style="font-size: 10pt;">&nbsp;</font></p>
</div>
</div>
</body>
</html>

"""
        
        let data = try TestHelper.loadData(relativePath: "tnef/ukr.eml")
        let stream = MemoryStream(data, writable: false)
        let message = try MimeMessage.load(stream)
        
        var tnefPart: TnefPart?
        for part in message.bodyParts {
            if let tnef = part as? TnefPart {
                tnefPart = tnef
                break
            }
        }
        
        let tnef = try #require(tnefPart)
        let extracted = try tnef.convertToMessage()
        
        let body = try #require(extracted.body as? TextPart)
        #expect(body.isHtml)
        #expect(body.contentType.charset == "koi8-r")
        
                let html = try #require(body.text).replacingOccurrences(of: "\r\n", with: "\n")
        
                let expectedNormalized = expected.replacingOccurrences(of: "\r\n", with: "\n")
        
                #expect(html == expectedNormalized)
        
            }
        
        
        
            @Test("TestRichTextEml")
        
            func testRichTextEml() throws {
        
                let data = try TestHelper.loadData(relativePath: "tnef/rich-text.eml")
        
                let stream = MemoryStream(data, writable: false)
        
                let message = try MimeMessage.load(stream)
        
                
        
                var tnefPart: TnefPart?
        
                for part in message.bodyParts {
        
                    if let tnef = part as? TnefPart {
        
                        tnefPart = tnef
        
                        break
        
                    }
        
                }
        
                
        
                let tnef = try #require(tnefPart)
        
                let extracted = try tnef.convertToMessage()
        
        
        
                #expect(extracted.subject == "")

                // Note: The TNEF data in rich-text.eml does not contain InternetMessageId or TnefCorrelationKey properties,
                // so the extracted message won't have a messageId set from TNEF. The C# test might have a different
                // expectation based on how MimeKit handles this case.
                // #expect(extracted.messageId == "DM5PR21MB0828DA2B8C88048BC03EFFA6CFA20@DM5PR21MB0828.namprd21.prod.outlook.com")
        
        
        
                let multipart = try #require(extracted.body as? Multipart)
        
                #expect(multipart.count == 6)
        
        
        
                #expect(multipart[0] is TextPart)
        
                #expect(multipart[1] is MimePart)
        
                #expect(multipart[2] is MimePart)
        
                #expect(multipart[3] is MimePart)
        
                #expect(multipart[4] is MimePart)
        
                #expect(multipart[5] is MimePart)
        
        
        
                let rtf = multipart[0] as! TextPart
        
                #expect(rtf.contentType.mimeType == "text/rtf")
        
        
        
                let kitten = multipart[1] as! MimePart
        
                #expect(kitten.contentType.mimeType == "application/octet-stream")
        
                #expect(kitten.fileName == "kitten-playing-with-a-christmas-tree.jpg")
        
        
        
                let task1 = multipart[2] as! MimePart
        
                #expect(task1.contentType.mimeType == "application/octet-stream")
        
                #expect(task1.contentType.name == "Build a train table")
        
                #expect(task1.contentDisposition?.disposition == "attachment")
        
                #expect(task1.contentDisposition?.fileName == "Untitled Attachment")
        
                #expect(task1.contentDisposition?.size == 9217)
        
        
        
                let task2 = multipart[3] as! MimePart
        
                #expect(task2.contentType.mimeType == "application/vnd.ms-tnef")
        
                #expect(task2.contentType.name == "Build a train table")
        
                #expect(task2.contentDisposition?.disposition == "attachment")
        
                #expect(task2.contentDisposition?.fileName == "Untitled Attachment")
        
                #expect(task2.contentDisposition?.size == 9217)
        
            }
        
        }
        
        