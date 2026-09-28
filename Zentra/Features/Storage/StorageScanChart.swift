import SwiftUI

struct StorageScanChart: View {
    let files: Int
    let bytes: Int64
    let currentURL: URL?

    @State private var sweep: CGFloat = 0

    private let bars: [CGFloat] = [0.28,0.46,0.34,0.68,0.52,0.82,0.58,0.92,0.64,0.76,0.48,0.70]

    var body: some View {
        GeometryReader { outer in
            ZentraCard {
                VStack(alignment: .leading, spacing: 22) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 8) {
                                Circle().fill(Color.zentraAccent).frame(width: 7,height: 7)
                                    .shadow(color: Color.zentraAccent.opacity(0.7), radius: 6)
                                Text("storage.scanChart.title").zentraFont(13,weight:.semibold).foregroundStyle(Color.zentraTextPrimary)
                            }
                            Text("storage.scanChart.subtitle").zentraFont(9.5).foregroundStyle(Color.zentraTextTertiary)
                        }
                        Spacer(minLength: 30)
                        VStack(alignment:.trailing,spacing:3) {
                            Text(ByteCountFormatter.string(fromByteCount:bytes,countStyle:.file)).zentraFont(20,weight:.semibold).foregroundStyle(Color.zentraTextPrimary)
                            Text(String(format:NSLocalizedString("storage.scanChart.files",comment:""),files)).zentraFont(9.5).foregroundStyle(Color.zentraTextTertiary)
                        }
                    }

                    GeometryReader { proxy in
                        ZStack(alignment:.bottomLeading) {
                            VStack(spacing:0) {
                                ForEach(0..<4,id:\.self) { _ in
                                    Spacer()
                                    Rectangle().fill(Color.white.opacity(0.035)).frame(height:1)
                                }
                            }
                            HStack(alignment:.bottom,spacing:8) {
                                ForEach(Array(bars.enumerated()),id:\.offset) { index,value in
                                    RoundedRectangle(cornerRadius:5)
                                        .fill(LinearGradient(colors:[Color.zentraAccent.opacity(0.20),Color.zentraAccent.opacity(0.92)],startPoint:.bottom,endPoint:.top))
                                        .frame(maxWidth:.infinity)
                                        .frame(height:max(10,proxy.size.height * value * (0.90 + CGFloat(index % 3) * 0.035)))
                                }
                            }
                            LinearGradient(colors:[.clear,Color.zentraAccent.opacity(0.13),.clear],startPoint:.leading,endPoint:.trailing)
                                .frame(width:max(90,proxy.size.width * 0.18))
                                .offset(x:sweep)
                                .blendMode(.screen)
                        }.clipped()
                        .onAppear {
                            sweep = -max(100,proxy.size.width * 0.2)
                            withAnimation(.linear(duration:2.8).repeatForever(autoreverses:false)) { sweep = proxy.size.width + 100 }
                        }
                    }.frame(maxWidth:.infinity,minHeight:150,maxHeight:190)

                    HStack(spacing:9) {
                        Image(systemName:"doc.text.magnifyingglass").font(.system(size:11)).foregroundStyle(Color.zentraAccent)
                        Text(currentURL?.path ?? String(localized:"storage.scanChart.preparing"))
                            .lineLimit(1).truncationMode(.middle).zentraFont(9.5).foregroundStyle(Color.zentraTextTertiary)
                        Spacer()
                        ProgressView().controlSize(.small)
                    }
                }
                .frame(width:max(0,outer.size.width - 2),alignment:.leading)
                .padding(2)
            }
            .frame(width:outer.size.width,alignment:.leading)
        }
        .frame(maxWidth:.infinity,minHeight:290)
    }
}
