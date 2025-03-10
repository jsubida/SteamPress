@testable import SteamPress
import Vapor

import Foundation

class CapturingBlogPresenter: BlogPresenter {
    
    let eventLoop: EventLoop
    init(eventLoop: EventLoop) {
        self.eventLoop = eventLoop
    }
    
    func `for`(_ request: Request) -> BlogPresenter {
        return self
    }

    // MARK: - BlogPresenter
    private(set) var indexPosts: [BlogPost]?
    private(set) var indexTags: [BlogTag]?
    private(set) var indexAuthors: [BlogUser]?
    private(set) var indexPageInformation: BlogGlobalPageInformation?
    private(set) var indexPaginationTagInfo: PaginationTagInformation?
    private(set) var indexTagsForPosts: [Int: [BlogTag]]?
    func indexView(posts: [BlogPost], tags: [BlogTag], authors: [BlogUser], tagsForPosts: [Int : [BlogTag]], pageInformation: BlogGlobalPageInformation, paginationTagInfo: PaginationTagInformation) -> EventLoopFuture<View> {
        self.indexPosts = posts
        self.indexTags = tags
        self.indexAuthors = authors
        self.indexPageInformation = pageInformation
        self.indexPaginationTagInfo = paginationTagInfo
        self.indexTagsForPosts = tagsForPosts
        return TestDataBuilder.createFutureView(on: eventLoop)
    }

    private(set) var post: BlogPost?
    private(set) var postAuthor: BlogUser?
    private(set) var postPageInformation: BlogGlobalPageInformation?
    private(set) var postPageTags: [BlogTag]?
    func postView(post: BlogPost, author: BlogUser, tags: [BlogTag], pageInformation: BlogGlobalPageInformation) -> EventLoopFuture<View> {
        self.post = post
        self.postAuthor = author
        self.postPageInformation = pageInformation
        self.postPageTags = tags
        return TestDataBuilder.createFutureView(on: eventLoop)
    }

    private(set) var allAuthors: [BlogUser]?
    private(set) var allAuthorsPostCount: [Int: Int]?
    private(set) var allAuthorsPageInformation: BlogGlobalPageInformation?
    func allAuthorsView(authors: [BlogUser], authorPostCounts: [Int: Int], pageInformation: BlogGlobalPageInformation) -> EventLoopFuture<View> {
        self.allAuthors = authors
        self.allAuthorsPostCount = authorPostCounts
        self.allAuthorsPageInformation = pageInformation
        return TestDataBuilder.createFutureView(on: eventLoop)
    }

    private(set) var author: BlogUser?
    private(set) var authorPosts: [BlogPost]?
    private(set) var authorPostCount: Int?
    private(set) var authorPageInformation: BlogGlobalPageInformation?
    private(set) var authorPaginationTagInfo: PaginationTagInformation?
    private(set) var authorPageTagsForPost: [Int: [BlogTag]]?
    func authorView(author: BlogUser, posts: [BlogPost], postCount: Int, tagsForPosts: [Int : [BlogTag]], pageInformation: BlogGlobalPageInformation, paginationTagInfo: PaginationTagInformation) -> EventLoopFuture<View> {
        self.author = author
        self.authorPosts = posts
        self.authorPostCount = postCount
        self.authorPageInformation = pageInformation
        self.authorPaginationTagInfo = paginationTagInfo
        self.authorPageTagsForPost = tagsForPosts
        return TestDataBuilder.createFutureView(on: eventLoop)
    }

    private(set) var allTagsPageTags: [BlogTag]?
    private(set) var allTagsPagePostCount: [Int: Int]?
    private(set) var allTagsPageInformation: BlogGlobalPageInformation?
    func allTagsView(tags: [BlogTag], tagPostCounts: [Int: Int], pageInformation: BlogGlobalPageInformation) -> EventLoopFuture<View> {
        self.allTagsPageTags = tags
        self.allTagsPagePostCount = tagPostCounts
        self.allTagsPageInformation = pageInformation
        return TestDataBuilder.createFutureView(on: eventLoop)
    }

    private(set) var tag: BlogTag?
    private(set) var tagPosts: [BlogPost]?
    private(set) var tagPageInformation: BlogGlobalPageInformation?
    private(set) var tagPaginationTagInfo: PaginationTagInformation?
    private(set) var tagPageTotalPosts: Int?
    private(set) var tagPageAuthors: [BlogUser]?
    func tagView(tag: BlogTag, posts: [BlogPost], authors: [BlogUser], totalPosts: Int, pageInformation: BlogGlobalPageInformation, paginationTagInfo: PaginationTagInformation) -> EventLoopFuture<View> {
        self.tag = tag
        self.tagPosts = posts
        self.tagPageInformation = pageInformation
        self.tagPaginationTagInfo = paginationTagInfo
        self.tagPageTotalPosts = totalPosts
        self.tagPageAuthors = authors
        return TestDataBuilder.createFutureView(on: eventLoop)
    }

    private(set) var searchPosts: [BlogPost]?
    private(set) var searchAuthors: [BlogUser]?
    private(set) var searchTerm: String?
    private(set) var searchTotalResults: Int?
    private(set) var searchPageInformation: BlogGlobalPageInformation?
    private(set) var searchPaginationTagInfo: PaginationTagInformation?
    private(set) var searchPageTagsForPost: [Int: [BlogTag]]?
    func searchView(totalResults: Int, posts: [BlogPost], authors: [BlogUser], searchTerm: String?, tagsForPosts: [Int : [BlogTag]], pageInformation: BlogGlobalPageInformation, paginationTagInfo: PaginationTagInformation) -> EventLoopFuture<View> {
        self.searchPosts = posts
        self.searchTerm = searchTerm
        self.searchPageInformation = pageInformation
        self.searchTotalResults = totalResults
        self.searchAuthors = authors
        self.searchPaginationTagInfo = paginationTagInfo
        self.searchPageTagsForPost = tagsForPosts
        return TestDataBuilder.createFutureView(on: eventLoop)
    }

    private(set) var loginWarning: Bool?
    private(set) var loginErrors: [String]?
    private(set) var loginUsername: String?
    private(set) var loginUsernameError: Bool?
    private(set) var loginPasswordError: Bool?
    private(set) var loginPageInformation: BlogGlobalPageInformation?
    private(set) var loginPageRememberMe: Bool?
    func loginView(loginWarning: Bool, errors: [String]?, username: String?, usernameError: Bool, passwordError: Bool, rememberMe: Bool, pageInformation: BlogGlobalPageInformation) -> EventLoopFuture<View> {
        self.loginWarning = loginWarning
        self.loginErrors = errors
        self.loginUsername = username
        self.loginUsernameError = usernameError
        self.loginPasswordError = passwordError
        self.loginPageInformation = pageInformation
        self.loginPageRememberMe = rememberMe
        return TestDataBuilder.createFutureView(on: eventLoop)
    }
}
