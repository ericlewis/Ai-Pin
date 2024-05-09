import SwiftUI
import AppIntents
import PinKit
import SwiftData
import BackgroundTasks

@main
struct Ai_PinApp: App {
    
    #if os(iOS)
    @UIApplicationDelegateAdaptor(AppDelegate.self)
    var appDelegate
    #endif

    @State
    private var sceneNavigationStore: NavigationStore
    
    @State
    private var sceneService: HumaneCenterService

    @State
    private var sceneCapturesRepository: CapturesRepository
    
    @State
    private var sceneMyDataRepository: MyDataRepository
    
    @State
    private var sceneSettingsRepository: SettingsRepository
    
    @State
    private var sceneModelContainer: ModelContainer
    
    @AccentColor
    private var accentColor: Color
    
    @Environment(\.scenePhase)
    private var phase
    
    let sceneDatabase: any Database

    init() {
        let navigationStore = NavigationStore.shared
        sceneNavigationStore = navigationStore
        
        let service = HumaneCenterService.live()
        sceneService = service
        
        let capturesRepository = CapturesRepository(api: service)
        sceneCapturesRepository = capturesRepository
        
        let myDataRepository = MyDataRepository(api: service)
        sceneMyDataRepository = myDataRepository
        
        let settingsRepository = SettingsRepository(service: service)
        sceneSettingsRepository = settingsRepository
        
        let modelContainerConfig = ModelConfiguration("fdas", isStoredInMemoryOnly: false)
        let modelContainer = try! ModelContainer(
            for: _Note.self,
            configurations: modelContainerConfig
        )
        sceneModelContainer = modelContainer
        
        let database = SharedDatabase(modelContainer: modelContainer).database
        sceneDatabase = database

        AppDependencyManager.shared.add(dependency: navigationStore)
        AppDependencyManager.shared.add(dependency: capturesRepository)
        AppDependencyManager.shared.add(dependency: myDataRepository)
        AppDependencyManager.shared.add(dependency: settingsRepository)
        AppDependencyManager.shared.add(dependency: service)
        AppDependencyManager.shared.add(dependency: database)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(sceneCapturesRepository)
                .environment(sceneNavigationStore)
                .environment(sceneMyDataRepository)
                .environment(sceneSettingsRepository)
                .environment(sceneService)
                .tint(accentColor)
        }
        .defaultAppStorage(.init(suiteName: "group.com.ericlewis.Pin-Pal") ?? .standard)
        .environment(\.database, sceneDatabase)
        .modelContainer(sceneModelContainer)
        .backgroundTask(.appRefresh("com.ericlewis.Pin-Pal.Notes.refresh")) {
            await handleNotesRefresh()
        }
        .onChange(of: phase) { oldPhase, newPhase in
            switch (oldPhase, newPhase) {
            case (.inactive, .background):
                requestNotesRefreshBackgroundTask()
            default: break
            }
        }
    }
    
    func requestNotesRefreshBackgroundTask() {
        let request = BGAppRefreshTaskRequest(identifier: "com.ericlewis.Pin-Pal.Notes.refresh")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 5 * 60) // 5 min
        do {
            try BGTaskScheduler.shared.submit(request)
            print("submitted bg task")
        } catch {
            print("Could not schedule app refresh: \(error)")
        }
    }
    
    func handleNotesRefresh() async {
        do {
            let intent = SyncNotesIntent()
            intent.database = sceneDatabase
            intent.service = sceneService
            let _ = try await intent.perform()
            requestNotesRefreshBackgroundTask()
        } catch {
            
        }
    }
}

#if os(iOS)
class AppDelegate: NSObject, UIApplicationDelegate {

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let sceneConfiguration = UISceneConfiguration(name: "Custom Configuration", sessionRole: connectingSceneSession.role)
        sceneConfiguration.delegateClass = SceneDelegate.self
        return sceneConfiguration
    }
    
    class SceneDelegate: UIResponder, UIWindowSceneDelegate {
        func windowScene(_ windowScene: UIWindowScene, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
            if NavigationStore.shared.activeNote == nil {
                NavigationStore.shared.activeNote = .create()
            }
        }
    }
}
#endif
