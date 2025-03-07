import Vapor
import SwiftSoup
import SwiftMarkdown

public struct ViewBlogPresenter: BlogPresenter {
    
    let viewRenderer: ViewRenderer
    let longDateFormatter: LongPostDateFormatter
    let numericDateFormatter: NumericPostDateFormatter
    let eventLoopGroup: EventLoopGroup

    public func indexView(posts: [BlogPost], tags: [BlogTag], authors: [BlogUser], tagsForPosts: [Int: [BlogTag]], pageInformation: BlogGlobalPageInformation, paginationTagInfo: PaginationTagInformation) -> EventLoopFuture<View> {
        do {
            let viewPosts = try posts.convertToViewBlogPosts(authors: authors, tagsForPosts: tagsForPosts, longDateFormatter: longDateFormatter, numericDateFormatter: numericDateFormatter)
            let viewTags = try tags.map { try $0.toViewBlogTag() }
            let context = BlogIndexPageContext(posts: viewPosts, tags: viewTags, authors: authors, pageInformation: pageInformation, paginationTagInformation: paginationTagInfo)
            return viewRenderer.render("blog/blog", context)
        } catch {
            return eventLoopGroup.future(error: error)
        }
    }

    public func postView(post: BlogPost, author: BlogUser, tags: [BlogTag], pageInformation: BlogGlobalPageInformation) -> EventLoopFuture<View> {
        do {
            var postImage: String?
            var postImageAlt: String?
            if let image = try SwiftSoup.parse(markdownToHTML(post.contents)).select("img").first() {
                postImage = try image.attr("src")
                let imageAlt = try image.attr("alt")
                if imageAlt != "" {
                    postImageAlt = imageAlt
                }
            }
            let shortSnippet = post.shortSnippet()
            let viewPost = try post.toViewPost(authorName: author.name, authorUsername: author.username, longFormatter: longDateFormatter, numericFormatter: numericDateFormatter, tags: tags)

            let context = BlogPostPageContext(title: post.title, post: viewPost, author: author, pageInformation: pageInformation, postImage: postImage, postImageAlt: postImageAlt, shortSnippet: shortSnippet)
            return viewRenderer.render("blog/post", context)
        } catch {
            return eventLoopGroup.future(error: error)
        }

    }

    public func allAuthorsView(authors: [BlogUser], authorPostCounts: [Int: Int], pageInformation: BlogGlobalPageInformation) -> EventLoopFuture<View> {
        do {
            var viewAuthors = try authors.map { user -> ViewBlogAuthor in
                guard let userID = user.userID else {
                    throw SteamPressError(identifier: "ViewBlogPresenter", "User ID Was Not Set")
                }
                return ViewBlogAuthor(userID: userID, name: user.name, username: user.username, resetPasswordRequired: user.resetPasswordRequired, profilePicture: user.profilePicture, twitterHandle: user.twitterHandle, biography: user.biography, tagline: user.tagline, postCount: authorPostCounts[userID] ?? 0)

            }
            viewAuthors.sort { $0.postCount > $1.postCount }
            let context = AllAuthorsPageContext(pageInformation: pageInformation, authors: viewAuthors)
            return viewRenderer.render("blog/authors", context)
        } catch {
            return eventLoopGroup.future(error: error)
        }
    }

    public func authorView(author: BlogUser, posts: [BlogPost], postCount: Int, tagsForPosts: [Int: [BlogTag]], pageInformation: BlogGlobalPageInformation, paginationTagInfo: PaginationTagInformation) -> EventLoopFuture<View> {
        do {
            let myProfile: Bool
            if let loggedInUser = pageInformation.loggedInUser {
                myProfile = loggedInUser.userID == author.userID
            } else {
                myProfile = false
            }
            let viewPosts = try posts.convertToViewBlogPosts(authors: [author], tagsForPosts: tagsForPosts, longDateFormatter: longDateFormatter, numericDateFormatter: numericDateFormatter)
            let context = AuthorPageContext(author: author, posts: viewPosts, pageInformation: pageInformation, myProfile: myProfile, postCount: postCount, paginationTagInformation: paginationTagInfo)
            return viewRenderer.render("blog/profile", context)
        } catch {
            return eventLoopGroup.future(error: error)
        }
    }

    public func allTagsView(tags: [BlogTag], tagPostCounts: [Int: Int], pageInformation: BlogGlobalPageInformation) -> EventLoopFuture<View> {
        do {
            var viewTags = try tags.map { tag -> BlogTagWithPostCount in
                guard let tagID = tag.tagID else {
                    throw SteamPressError(identifier: "ViewBlogPresenter", "Tag ID Was Not Set")
                }
                guard let urlEncodedName = tag.name.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
                    throw SteamPressError(identifier: "ViewBlogPresenter", "Failed to URL encoded tag name")
                }
                return BlogTagWithPostCount(tagID: tagID, name: tag.name, postCount: tagPostCounts[tagID] ?? 0, urlEncodedName: urlEncodedName)
            }
            viewTags.sort { $0.postCount > $1.postCount }
            let context = AllTagsPageContext(title: "All Tags", tags: viewTags, pageInformation: pageInformation)
            return viewRenderer.render("blog/tags", context)
        } catch {
            return eventLoopGroup.future(error: error)
        }
    }

    public func tagView(tag: BlogTag, posts: [BlogPost], authors: [BlogUser], totalPosts: Int, pageInformation: BlogGlobalPageInformation, paginationTagInfo: PaginationTagInformation) -> EventLoopFuture<View> {
        do {
            let tagsForPosts = try posts.reduce(into: [Int: [BlogTag]]()) { dict, blog in
                guard let blogID = blog.blogID else {
                    throw SteamPressError(identifier: "ViewBlogPresenter", "Blog has no ID set")
                }
                dict[blogID] = [tag]
            }
            
            let viewPosts = try posts.convertToViewBlogPosts(authors: authors, tagsForPosts: tagsForPosts, longDateFormatter: longDateFormatter, numericDateFormatter: numericDateFormatter)
            let context = TagPageContext(tag: tag, pageInformation: pageInformation, posts: viewPosts, postCount: totalPosts, paginationTagInformation: paginationTagInfo)
            return viewRenderer.render("blog/tag", context)
        } catch {
            return eventLoopGroup.future(error: error)
        }
    }

    public func searchView(totalResults: Int, posts: [BlogPost], authors: [BlogUser], searchTerm: String?, tagsForPosts: [Int: [BlogTag]], pageInformation: BlogGlobalPageInformation, paginationTagInfo: PaginationTagInformation) -> EventLoopFuture<View> {
        do {
            let viewPosts = try posts.convertToViewBlogPosts(authors: authors, tagsForPosts: tagsForPosts, longDateFormatter: longDateFormatter, numericDateFormatter: numericDateFormatter)
            let context = SearchPageContext(searchTerm: searchTerm, posts: viewPosts, totalResults: totalResults, pageInformation: pageInformation, paginationTagInformation: paginationTagInfo)
            return viewRenderer.render("blog/search", context)
        } catch {
            return eventLoopGroup.future(error: error)
        }
    }

    public func loginView(loginWarning: Bool, errors: [String]?, username: String?, usernameError: Bool, passwordError: Bool, rememberMe: Bool, pageInformation: BlogGlobalPageInformation) -> EventLoopFuture<View> {
        let context = LoginPageContext(errors: errors, loginWarning: loginWarning, username: username, usernameError: usernameError, passwordError: passwordError, rememberMe: rememberMe, pageInformation: pageInformation)
        return viewRenderer.render("blog/admin/login", context)
    }
    
}
