import Vapor

struct APITagController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let tagsRoute = routes.grouped("tags")
        tagsRoute.get(use: allTagsHandler)
    }

    func allTagsHandler(_ req: Request) throws -> EventLoopFuture<[BlogTag]> {
        req.blogTagRepository.getAllTags()
    }
}
