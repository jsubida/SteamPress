import XCTest
import SteamPress
import Vapor
import Foundation

class PostTests: XCTestCase {

    // MARK: - Properties
    var testWorld: TestWorld!
    var firstData: TestData!
    private let blogPostPath = "/posts/test-path"

    var presenter: CapturingBlogPresenter {
        return testWorld.context.blogPresenter
    }

    // MARK: - Overrides

    override func setUpWithError() throws {
        testWorld = try TestWorld.create(websiteURL: "/")
        firstData = try testWorld.createPost(title: "Test Path", slugUrl: "test-path")
    }
    
    override func tearDownWithError() throws {
        try testWorld.shutdown()
    }

    // MARK: - Tests

    func testBlogPostRetrievedCorrectlyFromSlugUrl() throws {
        _ = try testWorld.getResponse(to: blogPostPath)

        XCTAssertEqual(presenter.post?.title, firstData.post.title)
        XCTAssertEqual(presenter.post?.contents, firstData.post.contents)
        XCTAssertEqual(presenter.postAuthor?.name, firstData.author.name)
        XCTAssertEqual(presenter.postAuthor?.username, firstData.author.username)
    }
    
    func testPostPageGetsCorrectPageInformation() throws {
        _ = try testWorld.getResponse(to: blogPostPath)
        XCTAssertNil(presenter.postPageInformation?.disqusName)
        XCTAssertNil(presenter.postPageInformation?.googleAnalyticsIdentifier)
        XCTAssertNil(presenter.postPageInformation?.siteTwitterHandle)
        XCTAssertNil(presenter.postPageInformation?.loggedInUser)
        XCTAssertEqual(presenter.postPageInformation?.currentPageURL.absoluteString, blogPostPath)
        XCTAssertEqual(presenter.postPageInformation?.websiteURL.absoluteString, "/")
    }
    
    func testPostPageInformationGetsLoggedInUser() throws {
        _ = try testWorld.getResponse(to: blogPostPath, loggedInUser: firstData.author)
        XCTAssertEqual(presenter.postPageInformation?.loggedInUser?.username, firstData.author.username)
    }
    
    func testSettingEnvVarsWithPageInformation() throws {
        let googleAnalytics = "ABDJIODJWOIJIWO"
        let twitterHandle = "3483209fheihgifffe"
        let disqusName = "34829u48932fgvfbrtewerg"
        setenv("BLOG_GOOGLE_ANALYTICS_IDENTIFIER", googleAnalytics, 1)
        setenv("BLOG_SITE_TWITTER_HANDLE", twitterHandle, 1)
        setenv("BLOG_DISQUS_NAME", disqusName, 1)
        _ = try testWorld.getResponse(to: blogPostPath)
        XCTAssertEqual(presenter.postPageInformation?.disqusName, disqusName)
        XCTAssertEqual(presenter.postPageInformation?.googleAnalyticsIdentifier, googleAnalytics)
        XCTAssertEqual(presenter.postPageInformation?.siteTwitterHandle, twitterHandle)
    }
    
    func testPostPageGetsTags() throws {
        let tag1Name = "Something"
        let tag2Name = "Something else"
        _ = try testWorld.createTag(tag1Name, on: firstData.post)
        _ = try testWorld.createTag(tag2Name, on: firstData.post)
        
        _ = try testWorld.getResponse(to: blogPostPath)
        
        let tags = try XCTUnwrap(presenter.postPageTags)
        XCTAssertEqual(tags.count, 2)
        XCTAssertEqual(tags.first?.name, tag1Name)
        XCTAssertEqual(tags.last?.name, tag2Name)
    }
    
    func testExtraInitialiserWorks() throws {
        let post = BlogPost(blogID: 1, title: "title", contents: "contents", authorID: 1, creationDate: Date(), slugUrl: "slug-url", published: true)
        XCTAssertEqual(post.blogID, 1)
    }
}
