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

import Testing
@testable import MimeFoundation

@Test("TextToFlowed default property values")
func textToFlowedDefaultPropertyValues() {
    let converter = TextToFlowed()

    #expect(converter.detectEncodingFromByteOrderMark == false)
    #expect(converter.footer == nil)
    #expect(converter.header == nil)
    #expect(converter.inputEncoding == .utf8)
    #expect(converter.inputFormat == .plain)
    #expect(converter.inputStreamBufferSize == 4096)
    #expect(converter.outputEncoding == .utf8)
    #expect(converter.outputFormat == .flowed)
    #expect(converter.outputStreamBufferSize == 4096)
}

@Test("TextToFlowed simple conversion")
func textToFlowedSimpleConversion() {
    let newline = "\n"
    let expected = "> Thou art a villainous ill-breeding spongy dizzy-eyed reeky elf-skinned  " + newline +
        "> pigeon-egg!" + newline +
        ">> Thou artless swag-bellied milk-livered dismal-dreaming idle-headed scut!" + newline +
        ">>> Thou errant folly-fallen spleeny reeling-ripe unmuzzled ratsbane!" + newline +
        ">>>> Henceforth, the coding style is to be strictly enforced, including the  " + newline +
        ">>>> use of only upper case." + newline +
        ">>>>> I've noticed a lack of adherence to the coding styles, of late." + newline +
        ">>>>>> Any complaints?" + newline
    let text = "> Thou art a villainous ill-breeding spongy dizzy-eyed reeky elf-skinned pigeon-egg!" + newline +
        ">> Thou artless swag-bellied milk-livered dismal-dreaming idle-headed scut!" + newline +
        ">>> Thou errant folly-fallen spleeny reeling-ripe unmuzzled ratsbane!" + newline +
        ">>>> Henceforth, the coding style is to be strictly enforced, including the use of only upper case." + newline +
        ">>>>> I've noticed a lack of adherence to the coding styles, of late." + newline +
        ">>>>>> Any complaints?" + newline

    let converter = TextToFlowed()
    let result = converter.convert(text)
    #expect(result == expected)

    let unflowed = FlowedToText()
    unflowed.deleteSpace = true
    let roundTrip = unflowed.convert(expected)
    #expect(roundTrip == text)
}

@Test("TextToFlowed space stuffing From line")
func textToFlowedSpaceStuffingFromLine() {
    let newline = "\n"
    let expected = "My favorite James Bond movie is" + newline +
        " From Russia with love." + newline
    let text = "My favorite James Bond movie is" + newline +
        "From Russia with love." + newline
    let converter = TextToFlowed()
    let result = converter.convert(text)

    #expect(result == expected)

    let unflowed = FlowedToText()
    let roundTrip = unflowed.convert(expected)
    #expect(roundTrip == text)
}

@Test("TextToFlowed space stuffing leading space")
func textToFlowedSpaceStuffingLeadingSpace() {
    let newline = "\n"
    let expected = "This is a regular line." + newline +
        "  This line starts with a space." + newline
    let text = "This is a regular line." + newline +
        " This line starts with a space." + newline
    let converter = TextToFlowed()
    let result = converter.convert(text)

    #expect(result == expected)

    let unflowed = FlowedToText()
    let roundTrip = unflowed.convert(expected)
    #expect(roundTrip == text)
}

@Test("TextToFlowed flowing long lines")
func textToFlowedFlowingLongLines() {
    let text = "But, soft! what light through yonder window breaks? " +
        "It is the east, and Juliet is the sun. " +
        "Arise, fair sun, and kill the envious moon, " +
        "Who is already sick and pale with grief, " +
        "That thou her maid art far more fair than she: " +
        "Be not her maid, since she is envious; " +
        "Her vestal livery is but sick and green " +
        "And none but fools do wear it; cast it off. " +
        "It is my lady, O, it is my love! " +
        "O, that she knew she were! " +
        "She speaks yet she says nothing: what of that? " +
        "Her eye discourses; I will answer it. " +
        "I am too bold, 'tis not to me she speaks: " +
        "Two of the fairest stars in all the heaven, " +
        "Having some business, do entreat her eyes " +
        "To twinkle in their spheres till they return. " +
        "What if her eyes were there, they in her head? " +
        "The brightness of her cheek would shame those stars, " +
        "As daylight doth a lamp; her eyes in heaven " +
        "Would through the airy region stream so bright " +
        "That birds would sing and think it were not night. " +
        "See, how she leans her cheek upon her hand! " +
        "O, that I were a glove upon that hand, " +
        "That I might touch that cheek!\n"

    let expected = """
But, soft! what light through yonder window breaks? It is the east, and  
Juliet is the sun. Arise, fair sun, and kill the envious moon, Who is  
already sick and pale with grief, That thou her maid art far more fair than  
she: Be not her maid, since she is envious; Her vestal livery is but sick  
and green And none but fools do wear it; cast it off. It is my lady, O, it  
is my love! O, that she knew she were! She speaks yet she says nothing: what  
of that? Her eye discourses; I will answer it. I am too bold, 'tis not to me  
she speaks: Two of the fairest stars in all the heaven, Having some  
business, do entreat her eyes To twinkle in their spheres till they return.  
What if her eyes were there, they in her head? The brightness of her cheek  
would shame those stars, As daylight doth a lamp; her eyes in heaven Would  
through the airy region stream so bright That birds would sing and think it  
were not night. See, how she leans her cheek upon her hand! O, that I were a  
glove upon that hand, That I might touch that cheek!
""".replacingOccurrences(of: "\r\n", with: "\n") + "\n"

    let converter = TextToFlowed()
    let result = converter.convert(text).replacingOccurrences(of: "\r\n", with: "\n")

    #expect(result == expected)

    let unflowed = FlowedToText()
    unflowed.deleteSpace = true
    let roundTrip = unflowed.convert(expected).replacingOccurrences(of: "\r\n", with: "\n")
    #expect(roundTrip == text)
}

@Test("TextToFlowed flowing long quoted lines")
func textToFlowedFlowingLongQuotedLines() {
    let text = "A passage from Shakespear's Romeo + Juliet:\n" +
        "> Begin quote\n" +
        ">> But, soft! what light through yonder window breaks? " +
        "It is the east, and Juliet is the sun. " +
        "Arise, fair sun, and kill the envious moon, " +
        "Who is already sick and pale with grief, " +
        "That thou her maid art far more fair than she: " +
        "Be not her maid, since she is envious; " +
        "Her vestal livery is but sick and green " +
        "And none but fools do wear it; cast it off. " +
        "It is my lady, O, it is my love! " +
        "O, that she knew she were! " +
        "She speaks yet she says nothing: what of that? " +
        "Her eye discourses; I will answer it. " +
        "I am too bold, 'tis not to me she speaks: " +
        "Two of the fairest stars in all the heaven, " +
        "Having some business, do entreat her eyes " +
        "To twinkle in their spheres till they return. " +
        "What if her eyes were there, they in her head? " +
        "The brightness of her cheek would shame those stars, " +
        "As daylight doth a lamp; her eyes in heaven " +
        "Would through the airy region stream so bright " +
        "That birds would sing and think it were not night. " +
        "See, how she leans her cheek upon her hand! " +
        "O, that I were a glove upon that hand, " +
        "That I might touch that cheek!\n" +
        "> End quote\n\n" +
        "Did that flow correctly?\n"

    let expected = """
A passage from Shakespear's Romeo + Juliet:
> Begin quote
>> But, soft! what light through yonder window breaks? It is the east, and  
>> Juliet is the sun. Arise, fair sun, and kill the envious moon, Who is  
>> already sick and pale with grief, That thou her maid art far more fair  
>> than she: Be not her maid, since she is envious; Her vestal livery is but  
>> sick and green And none but fools do wear it; cast it off. It is my lady,  
>> O, it is my love! O, that she knew she were! She speaks yet she says  
>> nothing: what of that? Her eye discourses; I will answer it. I am too  
>> bold, 'tis not to me she speaks: Two of the fairest stars in all the  
>> heaven, Having some business, do entreat her eyes To twinkle in their  
>> spheres till they return. What if her eyes were there, they in her head?  
>> The brightness of her cheek would shame those stars, As daylight doth a  
>> lamp; her eyes in heaven Would through the airy region stream so bright  
>> That birds would sing and think it were not night. See, how she leans her  
>> cheek upon her hand! O, that I were a glove upon that hand, That I might  
>> touch that cheek!
> End quote

Did that flow correctly?
""".replacingOccurrences(of: "\r\n", with: "\n") + "\n"

    let converter = TextToFlowed()
    let result = converter.convert(text).replacingOccurrences(of: "\r\n", with: "\n")

    #expect(result == expected)

    let unflowed = FlowedToText()
    unflowed.deleteSpace = true
    let roundTrip = unflowed.convert(expected).replacingOccurrences(of: "\r\n", with: "\n")
    #expect(roundTrip == text)
}
