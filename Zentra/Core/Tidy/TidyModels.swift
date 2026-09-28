import Foundation

enum TidyCategory:String,CaseIterable,Identifiable,Sendable { case images,video,audio,documents,archives,installers,other; var id:String{rawValue} }
struct TidyItem:Identifiable,Hashable,Sendable { let url:URL;let size:Int64;let category:TidyCategory;var id:URL{url} }
struct TidyAnalysis:Sendable { let items:[TidyItem];var bytes:Int64{items.reduce(0){$0+$1.size}} }
