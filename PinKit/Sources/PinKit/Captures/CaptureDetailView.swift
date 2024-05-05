import SwiftUI
import SDWebImageSwiftUI
import MapKit

struct CaptureDetailView: View {
    
    let capture: ContentEnvelope
    
    @Environment(HumaneCenterService.self)
    private var service
    
    @State
    private var detailedCaptureInformation: ContentEnvelope?
    
    @State
    private var originalPhotos: [FileAsset] = []
    
    @State
    private var derivativePhotos: [FileAsset] = []
    
    @State
    private var locationName: String?
    
    @State
    private var location: CLLocationCoordinate2D?
    
    var body: some View {
        List {
            Section {
                VStack {
                    if let vidUrl = capture.videoDownloadUrl() {
                        VideoView(id: capture.uuid, vidUrl: vidUrl)
                            .scaledToFill()
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else {
                        WebImage(url: makeThumbnailURL(content: capture, capture: capture.get()!)) { image in
                            image
                                .resizable()
                                .scaledToFill()
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        } placeholder: {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.bar)
                                .aspectRatio(1.33333333333, contentMode: .fit)
                                .overlay(ProgressView())
                        }
                    }
                    HStack {
                        if originalPhotos.isEmpty, capture.get()?.state == .processed {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.bar)
                                .aspectRatio(1.33333333333, contentMode: .fit)
                                .overlay(ProgressView())
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.bar)
                                .aspectRatio(1.33333333333, contentMode: .fit)
                                .overlay(ProgressView())
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.bar)
                                .aspectRatio(1.33333333333, contentMode: .fit)
                                .overlay(ProgressView())
                        } else {
                            ForEach(originalPhotos, id: \.fileUUID) { photo in
                                WebImage(url: makeThumbnailURL(
                                    uuid: capture.uuid,
                                    fileUUID: photo.fileUUID,
                                    accessToken: photo.accessToken
                                )) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(1.33333333333, contentMode: .fit)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                } placeholder: {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(.bar)
                                        .aspectRatio(1.33333333333, contentMode: .fit)
                                        .overlay(ProgressView())
                                }
                            }
                        }
                    }
                }
                .listRowInsets(.init())
                .listRowBackground(Color.clear)
            }
            Section {
                LabeledContent("Created") {
                    Text(capture.userCreatedAt, format: .dateTime)
                }
                if let locationName {
                    LabeledContent("Location", value: locationName)
                }
                if let location {
                    Map {
                        Marker("", coordinate: location)
                    }
                    .aspectRatio(1.777, contentMode: .fit)
                    .listRowInsets(.init())
                    .allowsHitTesting(false)
                }
            }
        }
        .toolbar {
            Menu("Options", systemImage: "ellipsis.circle") {
                CaptureMenuContents(capture: capture)
            }
        }
        .navigationTitle("Capture")
        .task {
            do {
                guard let capture: CaptureEnvelope = try await service.memory(self.capture.uuid).get() else {
                    return
                }
                withAnimation {
                    self.originalPhotos = capture.originals ?? []
                    self.derivativePhotos = capture.derivatives ?? []
                    self.locationName = capture.location
                    if let lat = capture.latitude, let lng = capture.longitude {
                        self.location = .init(latitude: lat, longitude: lng)
                    }
                }
            } catch {
                print(error)
            }
        }
    }
    
    func makeThumbnailURL(content: ContentEnvelope, capture: CaptureEnvelope) -> URL? {
        makeThumbnailURL(uuid: content.uuid, fileUUID: capture.thumbnail.fileUUID, accessToken: capture.thumbnail.accessToken)
    }
    
    func makeThumbnailURL(uuid: UUID, fileUUID: UUID, accessToken: String) -> URL? {
        URL(string: "https://webapi.prod.humane.cloud/capture/memory/\(uuid.uuidString)/file/\(fileUUID)")?.appending(queryItems: [
            .init(name: "token", value: accessToken),
            .init(name: "w", value: "640"),
            .init(name: "q", value: "100")
        ])
    }
}
