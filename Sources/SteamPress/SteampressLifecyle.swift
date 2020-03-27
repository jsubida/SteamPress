import Vapor

public struct SteampressLifecyle: LifecycleHandler {

    let blogPath: String?
    let feedInformation: FeedInformation
    let postsPerPage: Int
    let enableAuthorPages: Bool
    let enableTagPages: Bool
    let pathCreator: BlogPathCreator

    /**
     Initialiser for SteamPress' Provider to add a blog to your Vapor App. You can pass it an optional
     `blogPath` to add the blog to. For instance, if you pass in "blog", your blog will be accessible
     at http://mysite.com/blog/, or if you pass in `nil` your blog will be added to the root of your
     site (i.e. http://mysite.com/)
     - Parameter blogPath: The path to add the blog to (see above).
     - Parameter feedInformation: Information to vend to the RSS and Atom feeds. Defaults to empty information.
     - Parameter postsPerPage: The number of posts to show per page on the main index page of the blog. Defaults to 10.
     - Parameter enableAuthorsPages: Flag used to determine whether to publicly expose the authors endpoints
     or not. Defaults to true.
     - Parameter enableTagsPages: Flag used to determine whether to publicy expose the tags endpoints or not.
     Defaults to true.
     */
    public init(
        blogPath: String? = nil,
        feedInformation: FeedInformation = FeedInformation(),
        postsPerPage: Int = 10,
        enableAuthorPages: Bool = true,
        enableTagPages: Bool = true) {
        self.blogPath = blogPath
        self.feedInformation = feedInformation
        self.postsPerPage = postsPerPage
        self.enableAuthorPages = enableAuthorPages
        self.enableTagPages = enableTagPages
        self.pathCreator = BlogPathCreator(blogPath: self.blogPath)
    }

//    public func register(_ services: inout Services) throws {
//        services.register(BlogRememberMeMiddleware.self)
//    }

    public func willBoot(_ application: Application) throws {
        application.randomNumberGenerators.initialize()
        application.blogPresenters.initialize()
        application.adminPresenters.initialize(pathCreator: pathCreator)
        application.passwordHashers.initialize()
        application.passwordVerifiers.initialize()
        
        let router = application.routes

        let feedController = FeedController(pathCreator: self.pathCreator, feedInformation: self.feedInformation)
        let apiController = APIController()
        let blogController = BlogController(pathCreator: self.pathCreator, enableAuthorPages: self.enableAuthorPages, enableTagPages: self.enableTagPages, postsPerPage: self.postsPerPage)
        let blogAdminController = BlogAdminController(pathCreator: self.pathCreator)

        let blogRoutes: RoutesBuilder
        if let blogPath = blogPath {
            blogRoutes = router.grouped(PathComponent(stringLiteral: blogPath))
        } else {
            blogRoutes = router.grouped("")
        }
        let steampressSessionsConfig = SessionsConfiguration(cookieName: "steampress-session") { value in
            HTTPCookies.Value(string: value.string)
        }
        let steampressSessions = SessionsMiddleware(session: application.sessions.driver, configuration: steampressSessionsConfig)
        let steampressAuthSessions = BlogAuthSessionsMiddleware()
        let sessionedRoutes = blogRoutes.grouped(steampressSessions, steampressAuthSessions)

        try sessionedRoutes.register(collection: feedController)
        try sessionedRoutes.register(collection: apiController)
        try sessionedRoutes.register(collection: blogController)
        try sessionedRoutes.register(collection: blogAdminController)
    }
}
