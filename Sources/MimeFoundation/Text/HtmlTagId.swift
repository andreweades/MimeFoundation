//
// HtmlTagId.swift
//
// Ported from MimeKit (C#) to Swift.
//

public enum HtmlTagId: String, Sendable {
    case unknown = ""
    case a = "a"
    case abbr = "abbr"
    case acronym = "acronym"
    case address = "address"
    case applet = "applet"
    case area = "area"
    case article = "article"
    case aside = "aside"
    case audio = "audio"
    case b = "b"
    case base = "base"
    case baseFont = "basefont"
    case bdi = "bdi"
    case bdo = "bdo"
    case bgSound = "bgsound"
    case big = "big"
    case blink = "blink"
    case blockQuote = "blockquote"
    case body = "body"
    case br = "br"
    case button = "button"
    case canvas = "canvas"
    case caption = "caption"
    case center = "center"
    case cite = "cite"
    case code = "code"
    case col = "col"
    case colGroup = "colgroup"
    case command = "command"
    case comment = "!"
    case dataList = "datalist"
    case dd = "dd"
    case del = "del"
    case details = "details"
    case dfn = "dfn"
    case dialog = "dialog"
    case dir = "dir"
    case div = "div"
    case dl = "dl"
    case dt = "dt"
    case em = "em"
    case embed = "embed"
    case fieldSet = "fieldset"
    case figCaption = "figcaption"
    case figure = "figure"
    case font = "font"
    case footer = "footer"
    case form = "form"
    case frame = "frame"
    case frameSet = "frameset"
    case h1 = "h1"
    case h2 = "h2"
    case h3 = "h3"
    case h4 = "h4"
    case h5 = "h5"
    case h6 = "h6"
    case head = "head"
    case header = "header"
    case hr = "hr"
    case html = "html"
    case i = "i"
    case iframe = "iframe"
    case image = "img"
    case input = "input"
    case ins = "ins"
    case isIndex = "isindex"
    case kbd = "kbd"
    case keygen = "keygen"
    case label = "label"
    case legend = "legend"
    case li = "li"
    case link = "link"
    case listing = "listing"
    case main = "main"
    case map = "map"
    case mark = "mark"
    case marquee = "marquee"
    case menu = "menu"
    case menuitem = "menuitem"
    case meta = "meta"
    case meter = "meter"
    case nav = "nav"
    case nextId = "nextid"
    case noBr = "nobr"
    case noEmbed = "noembed"
    case noFrames = "noframes"
    case noScript = "noscript"
    case object = "object"
    case ol = "ol"
    case optGroup = "optgroup"
    case option = "option"
    case output = "output"
    case p = "p"
    case param = "param"
    case plainText = "plaintext"
    case pre = "pre"
    case progress = "progress"
    case q = "q"
    case rp = "rp"
    case rt = "rt"
    case ruby = "ruby"
    case s = "s"
    case samp = "samp"
    case script = "script"
    case section = "section"
    case select = "select"
    case small = "small"
    case source = "source"
    case span = "span"
    case strike = "strike"
    case strong = "strong"
    case style = "style"
    case sub = "sub"
    case summary = "summary"
    case sup = "sup"
    case table = "table"
    case tbody = "tbody"
    case td = "td"
    case textArea = "textarea"
    case tfoot = "tfoot"
    case th = "th"
    case thead = "thead"
    case time = "time"
    case title = "title"
    case tr = "tr"
    case track = "track"
    case tt = "tt"
    case u = "u"
    case ul = "ul"
    case variable = "var"
    case video = "video"
    case wbr = "wbr"
    case xml = "xml"
    case xmp = "xmp"
}

public enum HtmlTagIdUtils {
    private static let nameToId: [String: HtmlTagId] = {
        var map: [String: HtmlTagId] = [:]
        // We can use the RawValue if it matches the name
        // However, some have special names or we want to be safe
        let allTags: [HtmlTagId] = [
            .a, .abbr, .acronym, .address, .applet, .area, .article, .aside, .audio,
            .b, .base, .baseFont, .bdi, .bdo, .bgSound, .big, .blink, .blockQuote,
            .body, .br, .button, .canvas, .caption, .center, .cite, .code, .col,
            .colGroup, .command, .comment, .dataList, .dd, .del, .details, .dfn,
            .dialog, .dir, .div, .dl, .dt, .em, .embed, .fieldSet, .figCaption,
            .figure, .font, .footer, .form, .frame, .frameSet, .h1, .h2, .h3,
            .h4, .h5, .h6, .head, .header, .hr, .html, .i, .iframe, .image,
            .input, .ins, .isIndex, .kbd, .keygen, .label, .legend, .li, .link,
            .listing, .main, .map, .mark, .marquee, .menu, .menuitem, .meta,
            .meter, .nav, .nextId, .noBr, .noEmbed, .noFrames, .noScript, .object,
            .ol, .optGroup, .option, .output, .p, .param, .plainText, .pre,
            .progress, .q, .rp, .rt, .ruby, .s, .samp, .script, .section,
            .select, .small, .source, .span, .strike, .strong, .style, .sub,
            .summary, .sup, .table, .tbody, .td, .textArea, .tfoot, .th,
            .thead, .time, .title, .tr, .track, .tt, .u, .ul, .variable,
            .video, .wbr, .xml, .xmp
        ]
        for id in allTags {
            map[id.rawValue] = id
        }
        return map
    }()

    private static let emptyElements: Set<HtmlTagId> = [
        .area, .base, .br, .col, .command, .embed, .hr, .image, .input, .keygen,
        .link, .meta, .param, .source, .track, .wbr
    ]

    public static func toHtmlTagName(_ id: HtmlTagId) -> String {
        if id == .unknown {
            return ""
        }
        return id.rawValue
    }

    public static func toHtmlTagId(_ name: String) -> HtmlTagId {
        if name.isEmpty {
            return .unknown
        }
        if name.hasPrefix("!") {
            return .comment
        }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return .unknown
        }
        if let mapped = nameToId[trimmed.lowercased()] {
            return mapped
        }
        return .unknown
    }

    public static func isEmptyElement(_ id: HtmlTagId) -> Bool {
        emptyElements.contains(id)
    }

    public static func isFormattingElement(_ id: HtmlTagId) -> Bool {
        switch id {
        case .a, .b, .big, .code, .em, .font, .i, .noBr, .s, .small, .strike, .strong, .tt, .u:
            return true
        default:
            return false
        }
    }
}

public extension HtmlTagId {
    var htmlTagName: String {
        HtmlTagIdUtils.toHtmlTagName(self)
    }

    var isEmptyElement: Bool {
        HtmlTagIdUtils.isEmptyElement(self)
    }

    var isFormattingElement: Bool {
        HtmlTagIdUtils.isFormattingElement(self)
    }

    static func from(tagName: String) -> HtmlTagId {
        HtmlTagIdUtils.toHtmlTagId(tagName)
    }
}