import AppKit
import Foundation

struct Piece { var text: String; var color: String; var bold: Bool = false }
struct Sample { var file: String; var title: String; var bg: String; var bar: String; var fg: String; var accent: String; var muted: String; var p10k: Bool; var prefixColor: String; var context: String; var left: String; var style: String }
func color(_ hex: String) -> NSColor {
    let value = Int(hex, radix: 16)!
    return NSColor(calibratedRed: CGFloat((value >> 16) & 255)/255, green: CGFloat((value >> 8) & 255)/255, blue: CGFloat(value & 255)/255, alpha: 1)
}
let samples: [Sample] = [
    Sample(file:"powerlevel10k-dark.png", title:"zsh · Powerlevel10k · dark", bg:"141C26", bar:"202C3A", fg:"F2F5F8", accent:"1EB8D1", muted:"9AABBC", p10k:true, prefixColor:"F2F5F8", context:"production", left:"~/projects/service   main  ❯", style:"p10k"),
    Sample(file:"powerlevel10k-light.png", title:"zsh · Powerlevel10k · light", bg:"F4F6F8", bar:"E5EAF0", fg:"222832", accent:"007D91", muted:"69798A", p10k:true, prefixColor:"222832", context:"staging", left:"~/projects/service   main  ❯", style:"p10k"),
    Sample(file:"bash-dark.png", title:"bash · dark", bg:"1E1C2B", bar:"2D293E", fg:"F0EDF9", accent:"F0EDF9", muted:"AAA2C2", p10k:false, prefixColor:"F0EDF9", context:"production", left:"user@workstation:~/projects/service$", style:"plain"),
    Sample(file:"fish-light.png", title:"fish · light", bg:"F9F5ED", bar:"EDE5D8", fg:"252B31", accent:"252B31", muted:"7E7770", p10k:false, prefixColor:"252B31", context:"staging", left:"user@workstation ~/projects/service>", style:"plain"),
    Sample(file:"starship-dark.png", title:"Starship · dark", bg:"101922", bar:"202B38", fg:"E8EFF4", accent:"1EB8D1", muted:"8EA3B4", p10k:false, prefixColor:"E8EFF4", context:"production", left:"~/projects/service on main", style:"starship")
]
let output = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory:true)
for sample in samples {
    let width = 1440, height = 300
    let rep = NSBitmapImageRep(bitmapDataPlanes:nil, pixelsWide:width, pixelsHigh:height, bitsPerSample:8, samplesPerPixel:4, hasAlpha:true, isPlanar:false, colorSpaceName:.deviceRGB, bytesPerRow:0, bitsPerPixel:0)!
    let ctx = NSGraphicsContext(bitmapImageRep:rep)!
    NSGraphicsContext.saveGraphicsState(); NSGraphicsContext.current = ctx
    color(sample.bg).setFill(); NSRect(x:0,y:0,width:width,height:height).fill()
    color(sample.bar).setFill(); NSRect(x:0,y:248,width:width,height:52).fill()
    for (x,c) in [(24,"FF6A61"),(47,"F5BD4F"),(70,"65C65A")] { color(c).setFill(); NSBezierPath(ovalIn:NSRect(x:x,y:267,width:12,height:12)).fill() }
    let titleFont = NSFont.systemFont(ofSize:20, weight:.medium)
    (sample.title as NSString).draw(at:NSPoint(x:100,y:264), withAttributes:[.font:titleFont,.foregroundColor:color(sample.muted)])
    let font = NSFont(name:"Menlo-Regular",size:25) ?? NSFont.monospacedSystemFont(ofSize:25,weight:.regular)
    let bold = NSFont(name:"Menlo-Bold",size:25) ?? NSFont.monospacedSystemFont(ofSize:25,weight:.bold)
    func draw(_ pieces:[Piece], x:CGFloat, y:CGFloat) {
        var dx=x
        for piece in pieces {
            let attrs: [NSAttributedString.Key:Any] = [.font:piece.bold ? bold : font,.foregroundColor:color(piece.color)]
            let text = piece.text as NSString
            text.draw(at:NSPoint(x:dx,y:y),withAttributes:attrs)
            dx += text.size(withAttributes:attrs).width
        }
    }
    let brand = [Piece(text:"N",color:sample.prefixColor), Piece(text:"9:",color:sample.accent,bold:sample.style == "starship"), Piece(text:sample.context,color:sample.accent,bold:sample.style == "starship")]
    let normal = Piece(text:"sloctl config current-context",color:sample.fg)
    if sample.p10k {
        draw([Piece(text:sample.left + " ",color:sample.fg),normal],x:35,y:180)
        draw([Piece(text:sample.context,color:sample.fg)],x:35,y:127)
        draw([Piece(text:sample.left,color:sample.fg)],x:35,y:74)
        let full = "N9:"+sample.context
        let w = (full as NSString).size(withAttributes:[.font:font]).width
        draw(brand,x:CGFloat(width)-35-w,y:74)
    } else {
        let prefix = sample.style == "starship" ? [Piece(text:sample.left + " ",color:sample.muted)] + brand + [Piece(text:" ❯ ",color:sample.muted)] : brand + [Piece(text:" "+sample.left+" ",color:sample.muted)]
        draw(prefix + [normal],x:35,y:180)
        draw([Piece(text:sample.context,color:sample.fg)],x:35,y:127)
        let bottom = sample.style == "starship" ? [Piece(text:sample.left + " ",color:sample.muted)] + brand + [Piece(text:" ❯",color:sample.muted)] : brand + [Piece(text:" "+sample.left,color:sample.muted)]
        draw(bottom,x:35,y:74)
    }
    NSGraphicsContext.restoreGraphicsState()
    try rep.representation(using:.png,properties:[:])!.write(to:output.appendingPathComponent(sample.file))
}
