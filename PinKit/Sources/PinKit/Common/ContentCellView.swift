import SwiftUI

struct ContentCellView: View {
    let content: ContentEnvelope
    
    @AppStorage(Constant.UI_CUSTOM_ACCENT_COLOR_V1)
    private var accentColor: Color = Constant.defaultAppAccentColor
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            switch content.data {
            case let .capture(capture):
                AsyncImage(url: makeThumbnailURL(capture: capture)) { image in
                    image
                        .resizable()
                        .scaledToFit()
                } placeholder: {
                    Rectangle()
                        .fill(.bar)
                        .aspectRatio(1.333, contentMode: .fit)
                        .overlay {
                            ProgressView()
                        }
                }
            case let .note(note):
                VStack(alignment: .leading, spacing: 5) {
                    Text(note.title)
                        .foregroundStyle(accentColor)
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .overlay(alignment: .topTrailing) {
                            if content.favorite {
                                Image(systemName: "heart")
                                    .symbolVariant(.fill)
                                    .foregroundStyle(.red)
                            }
                        }
                    Text(LocalizedStringKey(note.text))
                }
                Text(content.userCreatedAt, format: .dateTime)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            case .unknown:
                VStack(alignment: .leading) {
                    Text("Unknown")
                        .foregroundStyle(.red)
                        .font(.headline)
                    Text(content.userCreatedAt, format: .dateTime)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
        }
    }
    
    func makeThumbnailURL(capture: CaptureEnvelope) -> URL? {
        URL(string: "https://webapi.prod.humane.cloud/capture/memory/\(content.uuid.uuidString)/file/\(capture.thumbnail!.fileUUID)")?.appending(queryItems: [
            .init(name: "token", value: capture.thumbnail!.accessToken),
            .init(name: "w", value: "640"),
            .init(name: "q", value: "100")
        ])
    }
}