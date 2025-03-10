import Vapor

struct PostAdminController: RouteCollection {

    // MARK: - Properties
    private let pathCreator: BlogPathCreator

    // MARK: - Initialiser
    init(pathCreator: BlogPathCreator) {
        self.pathCreator = pathCreator
    }

    // MARK: - Route setup
    func boot(routes: RoutesBuilder) throws {
        routes.get("createPost", use: createPostHandler)
        routes.post("createPost", use: createPostPostHandler)
        routes.get("posts", BlogPost.parameter, "edit", use: editPostHandler)
        routes.post("posts", BlogPost.parameter, "edit", use: editPostPostHandler)
        routes.post("posts", BlogPost.parameter, "delete", use: deletePostHandler)
    }

    // MARK: - Route handlers
    func createPostHandler(_ req: Request) throws -> EventLoopFuture<View> {
        return try req.adminPresenter.createPostView(errors: nil, title: nil, contents: nil, slugURL: nil, tags: nil, isEditing: false, post: nil, isDraft: nil, titleError: false, contentsError: false, pageInformation: req.adminPageInfomation())
    }

    func createPostPostHandler(_ req: Request) throws -> EventLoopFuture<Response> {
        let data = try req.content.decode(CreatePostData.self)
        let author = try req.auth.require(BlogUser.self)

        if data.draft == nil && data.publish == nil {
            throw Abort(.badRequest)
        }

        if let createPostErrors = validatePostCreation(data) {
            let view = try req.adminPresenter.createPostView(errors: createPostErrors.errors, title: data.title, contents: data.contents, slugURL: nil, tags: data.tags, isEditing: false, post: nil, isDraft: nil, titleError: createPostErrors.titleError, contentsError: createPostErrors.contentsError, pageInformation: req.adminPageInfomation())
            return view.encodeResponse(for: req)
        }

        guard let title = data.title, let contents = data.contents else {
            throw Abort(.internalServerError)
        }

        return try BlogPost.generateUniqueSlugURL(from: title, on: req).flatMap { uniqueSlug in
            let newPost: BlogPost
            do {
                newPost = try BlogPost(title: title, contents: contents, author: author, creationDate: Date(), slugUrl: uniqueSlug, published: data.publish != nil)
            } catch {
                return req.eventLoop.makeFailedFuture(error)
            }

            return req.blogPostRepository.save(newPost).flatMap { post in
                var existingTagsQuery = [EventLoopFuture<BlogTag?>]()
                for tagName in data.tags {
                    existingTagsQuery.append(req.blogTagRepository.getTag(tagName))
                }

                return existingTagsQuery.flatten(on: req.eventLoop).flatMap { existingTagsWithOptionals in
                    let existingTags = existingTagsWithOptionals.compactMap { $0 }
                    var tagsSaves = [EventLoopFuture<BlogTag>]()
                    for tagName in data.tags {
                        if !existingTags.contains(where: { $0.name == tagName }) {
                            let tag = BlogTag(name: tagName)
                            tagsSaves.append(req.blogTagRepository.save(tag))
                        }
                    }

                    return tagsSaves.flatten(on: req.eventLoop).flatMap { tags in
                        var tagLinks = [EventLoopFuture<Void>]()
                        for tag in tags {
                            tagLinks.append(req.blogTagRepository.add(tag, to: post))
                        }
                        for tag in existingTags {
                            tagLinks.append(req.blogTagRepository.add(tag, to: post))
                        }
                        let redirect = req.redirect(to: self.pathCreator.createPath(for: "posts/\(post.slugUrl)"))
                        return tagLinks.flatten(on: req.eventLoop).transform(to: redirect)
                    }
                }
            }
        }
    }

    func deletePostHandler(_ req: Request) throws -> EventLoopFuture<Response> {
        return req.parameters.findPost(on: req).flatMap { post in
            return req.blogTagRepository.deleteTags(for: post).flatMap {
                let redirect = req.redirect(to: self.pathCreator.createPath(for: "admin"))
                return req.blogPostRepository.delete(post).transform(to: redirect)
            }
        }
    }

    func editPostHandler(_ req: Request) throws -> EventLoopFuture<View> {
        return req.parameters.findPost(on: req).flatMap { post in
            return req.blogTagRepository.getTags(for: post).flatMap { tags in
                do {
                    return try req.adminPresenter.createPostView(errors: nil, title: post.title, contents: post.contents, slugURL: post.slugUrl, tags: tags.map { $0.name }, isEditing: true, post: post, isDraft: !post.published, titleError: false, contentsError: false, pageInformation: req.adminPageInfomation())
                } catch {
                    return req.eventLoop.makeFailedFuture(error)
                }
            }
        }
    }

    func editPostPostHandler(_ req: Request) throws -> EventLoopFuture<Response> {
        let data = try req.content.decode(CreatePostData.self)
        return req.parameters.findPost(on: req).flatMap { post -> EventLoopFuture<Response> in
            if let errors = self.validatePostCreation(data) {
                do {
                    return try req.adminPresenter.createPostView(errors: errors.errors, title: data.title, contents: data.contents, slugURL: post.slugUrl, tags: data.tags, isEditing: true, post: post, isDraft: !post.published, titleError: errors.titleError, contentsError: errors.contentsError, pageInformation: req.adminPageInfomation()).encodeResponse(for: req)
                } catch {
                    return req.eventLoop.makeFailedFuture(error)
                }
            }

            guard let title = data.title, let contents = data.contents else {
                return req.eventLoop.makeFailedFuture(Abort(.internalServerError))
            }

            post.title = title
            post.contents = contents

            let slugURLFuture: EventLoopFuture<String>
            if let updateSlugURL = data.updateSlugURL, updateSlugURL {
                do {
                    slugURLFuture = try BlogPost.generateUniqueSlugURL(from: title, on: req)
                } catch {
                    return req.eventLoop.makeFailedFuture(error)
                }
            } else {
                slugURLFuture = req.eventLoop.future(post.slugUrl)
            }

            return slugURLFuture.flatMap { slugURL in
                post.slugUrl = slugURL
                if post.published {
                    post.lastEdited = Date()
                } else {
                    post.created = Date()
                    if let publish = data.publish, publish {
                        post.published = true
                    }
                }

                return req.blogTagRepository.getTags(for: post).and(req.blogTagRepository.getAllTags()).flatMap { existingTags, allTags in
                    let tagsToUnlink = existingTags.filter { (anExistingTag) -> Bool in
                        for tagName in data.tags {
                            if anExistingTag.name == tagName {
                                return false
                            }
                        }
                        return true
                    }
                    var removeTagLinkResults = [EventLoopFuture<Void>]()
                    for tagToUnlink in tagsToUnlink {
                        removeTagLinkResults.append(req.blogTagRepository.remove(tagToUnlink, from: post))
                    }

                    let newTagsNames = data.tags.filter { (tagName) -> Bool in
                        !existingTags.contains { (existingTag) -> Bool in
                            existingTag.name == tagName
                        }
                    }

                    var tagCreateSaves = [EventLoopFuture<BlogTag>]()
                    for newTagName in newTagsNames {
                        let foundInAllTags = allTags.filter { $0.name == newTagName }.first
                        if let existingTag = foundInAllTags {
                            tagCreateSaves.append(req.eventLoop.future(existingTag))
                        } else {
                            let newTag = BlogTag(name: newTagName)
                            tagCreateSaves.append(req.blogTagRepository.save(newTag))
                        }
                    }

                    return removeTagLinkResults.flatten(on: req.eventLoop).and(tagCreateSaves.flatten(on: req.eventLoop)).flatMap { (_, newTags) in
                        var postTagLinkResults = [EventLoopFuture<Void>]()
                        for tag in newTags {
                            postTagLinkResults.append(req.blogTagRepository.add(tag, to: post))
                        }
                        return postTagLinkResults.flatten(on: req.eventLoop).flatMap {
                            let redirect = req.redirect(to: self.pathCreator.createPath(for: "posts/\(post.slugUrl)"))
                            return req.blogPostRepository.save(post).transform(to: redirect)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Validators
    private func validatePostCreation(_ data: CreatePostData) -> CreatePostErrors? {
        var createPostErrors = [String]()
        var titleError = false
        var contentsError = false

        if data.title.isEmptyOrWhitespace() {
            createPostErrors.append("You must specify a blog post title")
            titleError = true
        }

        if data.contents.isEmptyOrWhitespace() {
            createPostErrors.append("You must have some content in your blog post")
            contentsError = true
        }

        if createPostErrors.count == 0 {
            return nil
        }

        return CreatePostErrors(errors: createPostErrors, titleError: titleError, contentsError: contentsError)
    }

}
