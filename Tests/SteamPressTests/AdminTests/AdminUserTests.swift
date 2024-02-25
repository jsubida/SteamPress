import XCTest
import Vapor
@testable import SteamPress

class AdminUserTests: XCTestCase {

    // MARK: - Properties
    private var app: Application!
    private var testWorld: TestWorld!
    private let createUserPath = "/admin/createUser/"
    private var user: BlogUser!
    private var presenter: CapturingAdminPresenter {
        return testWorld.context.blogAdminPresenter
    }

    // MARK: - Overrides

    override func setUpWithError() throws {
        testWorld = try TestWorld.create()
        user = testWorld.createUser(name: "Leia", username: "leia")
    }
    
    override func tearDownWithError() throws {
        try testWorld.shutdown()
    }

    // MARK: - User Creation

    func testPresenterGetsCorrectValuesForCreateUserPage() throws {
        _ = try testWorld.getResponse(to: createUserPath, loggedInUser: user)

        XCTAssertNil(presenter.createUserErrors)
        XCTAssertNil(presenter.createUserName)
        XCTAssertNil(presenter.createUserUsername)
        let passwordError = try XCTUnwrap(presenter.createUserPasswordError)
        XCTAssertFalse(passwordError)
        let confirmPasswordError = try XCTUnwrap(presenter.createUserPasswordError)
        XCTAssertFalse(confirmPasswordError)
        let resetPasswordRequired = try XCTUnwrap(presenter.createUserResetPasswordRequired)
        XCTAssertFalse(resetPasswordRequired)
        XCTAssertNil(presenter.createUserUserID)
        XCTAssertNil(presenter.createUserProfilePicture)
        XCTAssertNil(presenter.createUserTwitterHandle)
        XCTAssertNil(presenter.createUserBiography)
        XCTAssertNil(presenter.createUserTagline)
        let editing = try XCTUnwrap(presenter.createUserEditing)
        XCTAssertFalse(editing)
        let nameError = try XCTUnwrap(presenter.createUserNameError)
        XCTAssertFalse(nameError)
        let usernameError = try XCTUnwrap(presenter.createUserUsernameError)
        XCTAssertFalse(usernameError)
    }

    func testUserCanBeCreatedSuccessfully() throws {
        struct CreateUserData: Content {
            static let defaultContentType = HTTPMediaType.urlEncodedForm
            var name = "Luke"
            var username = "lukes"
            var password = "somepassword"
            var confirmPassword = "somepassword"
            var profilePicture = "https://static.brokenhands.io/images/cat.png"
            var tagline = "The awesome tagline"
            var biography = "The biograhy"
            var twitterHandle = "brokenhandsio"
        }

        let createData = CreateUserData()
        let response = try testWorld.getResponse(to: createUserPath, body: createData, loggedInUser: user)

        // First is user created in setup, final is one just created
        XCTAssertEqual(testWorld.context.repository.users.count, 2)
        let user = try XCTUnwrap(testWorld.context.repository.users.last)
        XCTAssertEqual(user.username, createData.username)
        XCTAssertEqual(user.name, createData.name)
        XCTAssertEqual(user.profilePicture, createData.profilePicture)
        XCTAssertEqual(user.tagline, createData.tagline)
        XCTAssertEqual(user.biography, createData.biography)
        XCTAssertEqual(user.twitterHandle, createData.twitterHandle)
        XCTAssertEqual(response.status, .seeOther)
        XCTAssertEqual(response.headers[.location].first, "/admin/")
    }
    
    func testUserHasNoAdditionalInfoIfEmptyStringsSent() throws {
        struct CreateUserData: Content {
            static let defaultContentType = HTTPMediaType.urlEncodedForm
            var name = "Luke"
            var username = "lukes"
            var password = "somepassword"
            var confirmPassword = "somepassword"
            var profilePicture = ""
            var tagline = ""
            var biography = ""
            var twitterHandle = ""
        }

        let createData = CreateUserData()
        _ = try testWorld.getResponse(to: createUserPath, body: createData, loggedInUser: user)

        // First is user created in setup, final is one just created
        XCTAssertEqual(testWorld.context.repository.users.count, 2)
        let user = try XCTUnwrap(testWorld.context.repository.users.last)
        XCTAssertNil(user.profilePicture)
        XCTAssertNil(user.tagline)
        XCTAssertNil(user.biography)
        XCTAssertNil(user.twitterHandle)
    }

    func testUserMustResetPasswordIfSetToWhenCreatingUser() throws {
        struct CreateUserResetData: Content {
            static let defaultContentType = HTTPMediaType.urlEncodedForm
            var name = "Luke"
            var username = "lukes"
            var password = "somepassword"
            var confirmPassword = "somepassword"
            var profilePicture = "https://static.brokenhands.io/images/cat.png"
            var tagline = "The awesome tagline"
            var biography = "The biograhy"
            var twitterHandle = "brokenhandsio"
            var resetPasswordOnLogin = true
        }

        let data = CreateUserResetData()
        _ = try testWorld.getResponse(to: createUserPath, body: data, loggedInUser: user)

        let user = try XCTUnwrap(testWorld.context.repository.users.filter { $0.username == data.username }.first)
        XCTAssertTrue(user.resetPasswordRequired)
    }

    func testUserCannotBeCreatedWithoutName() throws {
        struct CreateUserData: Content {
            static let defaultContentType = HTTPMediaType.urlEncodedForm
            var username = "lukes"
            var password = "password"
            var confirmPassword = "password"
        }

        let createData = CreateUserData()
        _ = try testWorld.getResponse(to: createUserPath, body: createData, loggedInUser: user)

        let viewErrors = try XCTUnwrap(presenter.createUserErrors)
        XCTAssertTrue(viewErrors.contains("You must specify a name"))
        let nameError = try XCTUnwrap(presenter.createUserNameError)
        XCTAssertTrue(nameError)
    }

    func testUserCannotBeCreatedWithoutUsername() throws {
        struct CreateUserData: Content {
            static let defaultContentType = HTTPMediaType.urlEncodedForm
            var name = "Luke"
            var password = "password"
            var confirmPassword = "password"
        }

        let createData = CreateUserData()
        _ = try testWorld.getResponse(to: createUserPath, body: createData, loggedInUser: user)

        let viewErrors = try XCTUnwrap(presenter.createUserErrors)
        XCTAssertTrue(viewErrors.contains("You must specify a username"))
        let usernameError = try XCTUnwrap(presenter.createUserUsernameError)
        XCTAssertTrue(usernameError)
    }

    func testUserCannotBeCreatedWithUsernameThatAlreadyExists() throws {
        struct CreateUserData: Content {
            static let defaultContentType = HTTPMediaType.urlEncodedForm
            var name = "Luke"
            var password = "password"
            var confirmPassword = "password"
            var username = "lukes"
        }
        
        _ = testWorld.createUser(username: "lukes")

        let createData = CreateUserData()
        _ = try testWorld.getResponse(to: createUserPath, body: createData, loggedInUser: user)

        let viewErrors = try XCTUnwrap(presenter.createUserErrors)
        XCTAssertTrue(viewErrors.contains("Sorry that username has already been taken"))
        let usernameError = try XCTUnwrap(presenter.createUserUsernameError)
        XCTAssertTrue(usernameError)
    }

    func testUserCannotBeCreatedWithUsernameThatAlreadyExistsIgnoringCase() throws {
        struct CreateUserData: Content {
            static let defaultContentType = HTTPMediaType.urlEncodedForm
            var name = "Luke"
            var password = "password"
            var confirmPassword = "password"
            var username = "Lukes"
        }
        
        _ = testWorld.createUser(username: "lukes")

        let createData = CreateUserData()
        _ = try testWorld.getResponse(to: createUserPath, body: createData, loggedInUser: user)

        let viewErrors = try XCTUnwrap(presenter.createUserErrors)
        XCTAssertTrue(viewErrors.contains("Sorry that username has already been taken"))
        let usernameError = try XCTUnwrap(presenter.createUserUsernameError)
        XCTAssertTrue(usernameError)
    }

    func testUserCannotBeCreatedWithoutPassword() throws {
        struct CreateUserData: Content {
            static let defaultContentType = HTTPMediaType.urlEncodedForm
            var name = "Luke"
            var username = "lukes"
            var confirmPassword = "password"
        }

        let createData = CreateUserData()
        _ = try testWorld.getResponse(to: createUserPath, body: createData, loggedInUser: user)

        let viewErrors = try XCTUnwrap(presenter.createUserErrors)
        XCTAssertTrue(viewErrors.contains("You must specify a password"))
        let passwordError = try XCTUnwrap(presenter.createUserPasswordError)
        XCTAssertTrue(passwordError)
    }

    func testUserCannotBeCreatedWithEmptyPassword() throws {
        struct CreateUserData: Content {
            static let defaultContentType = HTTPMediaType.urlEncodedForm
            var name = "Luke"
            var username = "lukes"
            var password = ""
            var confirmPassword = ""
        }

        let createData = CreateUserData()
        _ = try testWorld.getResponse(to: createUserPath, body: createData, loggedInUser: user)

        let viewErrors = try XCTUnwrap(presenter.createUserErrors)
        XCTAssertTrue(viewErrors.contains("You must specify a password"))
        let passwordError = try XCTUnwrap(presenter.createUserPasswordError)
        XCTAssertTrue(passwordError)
    }

    func testUserCannotBeCreatedWithoutSpecifyingAConfirmPassword() throws {
        struct CreateUserData: Content {
            static let defaultContentType = HTTPMediaType.urlEncodedForm
            var name = "Luke"
            var username = "lukes"
            var password = "password"
        }

        let createData = CreateUserData()
        _ = try testWorld.getResponse(to: createUserPath, body: createData, loggedInUser: user)

        let viewErrors = try XCTUnwrap(presenter.createUserErrors)
        XCTAssertTrue(viewErrors.contains("You must confirm your password"))
        let confirmPasswordError = try XCTUnwrap(presenter.createUserConfirmPasswordError)
        XCTAssertTrue(confirmPasswordError)
    }

    func testUserCannotBeCreatedWithPasswordsThatDontMatch() throws {
        struct CreateUserData: Content {
            static let defaultContentType = HTTPMediaType.urlEncodedForm
            var name = "Luke"
            var username = "lukes"
            var password = "astrongpassword"
            var confirmPassword = "anotherPassword"
        }

        let createData = CreateUserData()
        _ = try testWorld.getResponse(to: createUserPath, body: createData, loggedInUser: user)

        let viewErrors = try XCTUnwrap(presenter.createUserErrors)
        XCTAssertTrue(viewErrors.contains("Your passwords must match"))

        let passwordError = try XCTUnwrap(presenter.createUserPasswordError)
        let confirmPasswordError = try XCTUnwrap(presenter.createUserConfirmPasswordError)
        XCTAssertTrue(passwordError)
        XCTAssertTrue(confirmPasswordError)
    }

    func testUserCannotBeCreatedWithSimplePassword() throws {
        struct CreateUserData: Content {
            static let defaultContentType = HTTPMediaType.urlEncodedForm
            var name = "Luke"
            var username = "lukes"
            var password = "password"
            var confirmPassword = "password"
        }

        let createData = CreateUserData()
        _ = try testWorld.getResponse(to: createUserPath, body: createData, loggedInUser: user)

        let viewErrors = try XCTUnwrap(presenter.createUserErrors)
        XCTAssertTrue(viewErrors.contains("Your password must be at least 10 characters long"))
        let passwordError = try XCTUnwrap(presenter.createUserPasswordError)
        XCTAssertTrue(passwordError)
        let isEditing = try XCTUnwrap(presenter.createUserEditing)
        XCTAssertFalse(isEditing)
    }

    func testUserCannotBeCreatedWithEmptyName() throws {
        struct CreateUserData: Content {
            static let defaultContentType = HTTPMediaType.urlEncodedForm
            var mame = ""
            var username = "lukes"
            var password = "password"
            var confirmPassword = "password"
        }

        let createData = CreateUserData()
        _ = try testWorld.getResponse(to: createUserPath, body: createData, loggedInUser: user)

        let viewErrors = try XCTUnwrap(presenter.createUserErrors)
        XCTAssertTrue(viewErrors.contains("You must specify a name"))
        let nameError = try XCTUnwrap(presenter.createUserNameError)
        XCTAssertTrue(nameError)
    }

    func testUserCannotBeCreatedWithEmptyUsername() throws {
        struct CreateUserData: Content {
            static let defaultContentType = HTTPMediaType.urlEncodedForm
            var name = "Luke"
            var username = ""
            var password = "password"
            var confirmPassword = "password"
        }

        let createData = CreateUserData()
        _ = try testWorld.getResponse(to: createUserPath, body: createData, loggedInUser: user)

        let viewErrors = try XCTUnwrap(presenter.createUserErrors)
        XCTAssertTrue(viewErrors.contains("You must specify a username"))
        let usernameError = try XCTUnwrap(presenter.createUserUsernameError)
        XCTAssertTrue(usernameError)
    }

    func testUserCannotBeCreatedWithInvalidUsername() throws {
        struct CreateUserData: Content {
            static let defaultContentType = HTTPMediaType.urlEncodedForm
            var name = "Luke"
            var username = "lukes!"
            var password = "password"
            var confirmPassword = "password"
        }

        let createData = CreateUserData()
        _ = try testWorld.getResponse(to: createUserPath, body: createData, loggedInUser: user)

        let viewErrors = try XCTUnwrap(presenter.createUserErrors)
        XCTAssertTrue(viewErrors.contains("The username provided is not valid"))
        let usernameError = try XCTUnwrap(presenter.createUserUsernameError)
        XCTAssertTrue(usernameError)
    }

    func testPasswordIsActuallyHashedWhenCreatingAUser() throws {
        try testWorld.shutdown()
        testWorld = try TestWorld.create(passwordHasherToUse: .reversed)
        let usersPassword = "password"
        let hashedPassword = String(usersPassword.reversed())
        user = testWorld.createUser(name: "Leia", username: "leia", password: hashedPassword)

        struct CreateUserData: Content {
            static let defaultContentType = HTTPMediaType.urlEncodedForm
            var name = "Luke"
            var username = "lukes"
            var password = "somepassword"
            var confirmPassword = "somepassword"
        }

        let createData = CreateUserData()
        _ = try testWorld.getResponse(to: createUserPath, body: createData, loggedInUser: user, passwordToLoginWith: usersPassword)

        let newUser = try XCTUnwrap(testWorld.context.repository.users.last)
        XCTAssertEqual(newUser.password, String(createData.password.reversed()))
    }

    // MARK: - Edit Users

    func testPresenterGetsUserInformationOnEditUserPage() throws {
        _ = try testWorld.getResponse(to: "/admin/users/\(user.userID!)/edit", loggedInUser: user)
        XCTAssertEqual(presenter.createUserName, user.name)
        XCTAssertEqual(presenter.createUserUsername, user.username)
        XCTAssertEqual(presenter.createUserUserID, user.userID)
        XCTAssertEqual(presenter.createUserProfilePicture, user.profilePicture)
        XCTAssertEqual(presenter.createUserTwitterHandle, user.twitterHandle)
        XCTAssertEqual(presenter.createUserBiography, user.biography)
        XCTAssertEqual(presenter.createUserTagline, user.tagline)
        XCTAssertNil(presenter.createUserErrors)
        let passwordError = try XCTUnwrap(presenter.createUserPasswordError)
        XCTAssertFalse(passwordError)
        let confirmPasswordError = try XCTUnwrap(presenter.createUserPasswordError)
        XCTAssertFalse(confirmPasswordError)
        let resetPasswordRequired = try XCTUnwrap(presenter.createUserResetPasswordRequired)
        XCTAssertEqual(resetPasswordRequired, user.resetPasswordRequired)
        let editing = try XCTUnwrap(presenter.createUserEditing)
        XCTAssertTrue(editing)
        let nameError = try XCTUnwrap(presenter.createUserNameError)
        XCTAssertFalse(nameError)
        let usernameError = try XCTUnwrap(presenter.createUserUsernameError)
        XCTAssertFalse(usernameError)
    }

    func testUserCanBeUpdated() throws {
        struct EditUserData: Content {
            static let defaultContentType = HTTPMediaType.urlEncodedForm
            var name = "Darth Vader"
            var username = "darth_vader"
        }

        let editData = EditUserData()
        let response = try testWorld.getResponse(to: "/admin/users/\(user.userID!)/edit", body: editData, loggedInUser: user)

        XCTAssertEqual(testWorld.context.repository.users.count, 1)
        let updatedUser = try XCTUnwrap(testWorld.context.repository.users.last)
        XCTAssertEqual(updatedUser.username, editData.username)
        XCTAssertEqual(updatedUser.name, editData.name)
        XCTAssertEqual(updatedUser.userID, user.userID)
        XCTAssertEqual(response.status, .seeOther)
        XCTAssertEqual(response.headers[.location].first, "/admin/")
    }
    
    func testUserCanBeUpdatedWithSameUsername() throws {
        struct EditUserData: Content {
            static let defaultContentType = HTTPMediaType.urlEncodedForm
            var name = "Leia Organa"
            var username = "leia"
        }

        let editData = EditUserData()
        let response = try testWorld.getResponse(to: "/admin/users/\(user.userID!)/edit", body: editData, loggedInUser: user)

        XCTAssertEqual(testWorld.context.repository.users.count, 1)
        let updatedUser = try XCTUnwrap(testWorld.context.repository.users.last)
        XCTAssertEqual(updatedUser.username, editData.username)
        XCTAssertEqual(updatedUser.name, editData.name)
        XCTAssertEqual(updatedUser.userID, user.userID)
        XCTAssertEqual(response.status, .seeOther)
        XCTAssertEqual(response.headers[.location].first, "/admin/")
    }

    func testUserCanBeUpdatedWithAllInformation() throws {
        struct EditUserData: Content {
            static let defaultContentType = HTTPMediaType.urlEncodedForm
            var name = "Darth Vader"
            var username = "darth_vader"
            var twitterHandle = "darthVader"
            var profilePicture = "https://deathstar.org/pictures/dv.jpg"
            var tagline = "The Sith Lord formally known as Anakin"
            var biography = "Father of one, part cyborg, Sith Lord. Something something dark side."
        }

        let editData = EditUserData()
        let response = try testWorld.getResponse(to: "/admin/users/\(user.userID!)/edit", body: editData, loggedInUser: user)

        XCTAssertEqual(testWorld.context.repository.users.count, 1)
        let updatedUser = try XCTUnwrap(testWorld.context.repository.users.last)
        XCTAssertEqual(updatedUser.username, editData.username)
        XCTAssertEqual(updatedUser.name, editData.name)
        XCTAssertEqual(updatedUser.twitterHandle, editData.twitterHandle)
        XCTAssertEqual(updatedUser.profilePicture, editData.profilePicture)
        XCTAssertEqual(updatedUser.tagline, editData.tagline)
        XCTAssertEqual(updatedUser.biography, editData.biography)
        XCTAssertEqual(updatedUser.userID, user.userID)
        XCTAssertEqual(response.status, .seeOther)
        XCTAssertEqual(response.headers[.location].first, "/admin/")
    }
    
    func testOptionalInfoDoesntGetUpdatedWhenEditingUsernameAndSendingEmptyValuesIfSomeAlreadySet() throws {
        struct EditUserData: Content {
            static let defaultContentType = HTTPMediaType.urlEncodedForm
            var name = "Darth Vader"
            var username = "darth_vader"
            var twitterHandle = ""
            var profilePicture = ""
            var tagline = ""
            var biography = ""
        }
        
        user.profilePicture = nil
        user.twitterHandle = nil
        user.tagline = nil
        user.biography = nil

        let editData = EditUserData()
        _ = try testWorld.getResponse(to: "/admin/users/\(user.userID!)/edit", body: editData, loggedInUser: user)

        XCTAssertEqual(testWorld.context.repository.users.count, 1)
        let updatedUser = try XCTUnwrap(testWorld.context.repository.users.last)
        XCTAssertEqual(updatedUser.username, editData.username)
        XCTAssertEqual(updatedUser.name, editData.name)
        XCTAssertNil(updatedUser.twitterHandle)
        XCTAssertNil(updatedUser.profilePicture)
        XCTAssertNil(updatedUser.tagline)
        XCTAssertNil(updatedUser.biography)
        XCTAssertEqual(updatedUser.userID, user.userID)
    }
    
    func testUpdatingOptionalInfoToEmptyValuesWhenValueOriginallySetSetsItToNil() throws {
        struct EditUserData: Content {
            static let defaultContentType = HTTPMediaType.urlEncodedForm
            var name = "Darth Vader"
            var username = "darth_vader"
            var twitterHandle = ""
            var profilePicture = ""
            var tagline = ""
            var biography = ""
        }

        user.profilePicture = "https://static.brokenhands.io/picture.png"
        user.tagline = "Tagline"
        user.biography = "Biography"
        user.twitterHandle = "darthVader"
        let editData = EditUserData()
        _ = try testWorld.getResponse(to: "/admin/users/\(user.userID!)/edit", body: editData, loggedInUser: user)

        XCTAssertEqual(testWorld.context.repository.users.count, 1)
        let updatedUser = try XCTUnwrap(testWorld.context.repository.users.last)
        XCTAssertEqual(updatedUser.username, editData.username)
        XCTAssertEqual(updatedUser.name, editData.name)
        XCTAssertNil(updatedUser.twitterHandle)
        XCTAssertNil(updatedUser.profilePicture)
        XCTAssertNil(updatedUser.tagline)
        XCTAssertNil(updatedUser.biography)
        XCTAssertEqual(updatedUser.userID, user.userID)
    }

    func testWhenEditingUserResetPasswordFlagSetIfRequired() throws {
        struct EditUserData: Content {
            static let defaultContentType = HTTPMediaType.urlEncodedForm
            var name = "Luke"
            var username = "lukes"
            var resetPasswordOnLogin = true
        }

        let editData = EditUserData()
        let response = try testWorld.getResponse(to: "/admin/users/\(user.userID!)/edit", body: editData, loggedInUser: user)

        XCTAssertEqual(testWorld.context.repository.users.count, 1)
        let updatedUser = try XCTUnwrap(testWorld.context.repository.users.last)
        XCTAssertTrue(updatedUser.resetPasswordRequired)
        XCTAssertEqual(updatedUser.userID, user.userID)
        XCTAssertEqual(response.status, .seeOther)
        XCTAssertEqual(response.headers[.location].first, "/admin/")
    }

    func testWhenEditingUserResetPasswordFlagNotSetIfSetToFalse() throws {
        struct EditUserData: Content {
            static let defaultContentType = HTTPMediaType.urlEncodedForm
            var name = "Luke"
            var username = "lukes"
            var resetPasswordOnLogin = false
        }

        let editData = EditUserData()
        let response = try testWorld.getResponse(to: "/admin/users/\(user.userID!)/edit", body: editData, loggedInUser: user)

        XCTAssertEqual(testWorld.context.repository.users.count, 1)
        let updatedUser = try XCTUnwrap(testWorld.context.repository.users.last)
        XCTAssertFalse(updatedUser.resetPasswordRequired)
        XCTAssertEqual(updatedUser.userID, user.userID)
        XCTAssertEqual(response.status, .seeOther)
        XCTAssertEqual(response.headers[.location].first, "/admin/")
    }

    func testPasswordIsUpdatedWhenNewPasswordProvidedWhenEditingUser() throws {
        struct EditUserData: Content {
            static let defaultContentType = HTTPMediaType.urlEncodedForm
            var name = "Luke"
            var username = "lukes"
            var password = "anewpassword"
            var confirmPassword = "anewpassword"
        }

        let editData = EditUserData()
        let response = try testWorld.getResponse(to: "/admin/users/\(user.userID!)/edit", body: editData, loggedInUser: user)

        XCTAssertEqual(testWorld.context.repository.users.count, 1)
        let updatedUser = try XCTUnwrap(testWorld.context.repository.users.last)
        XCTAssertEqual(updatedUser.password, editData.password)
        XCTAssertEqual(updatedUser.userID, user.userID)
        XCTAssertEqual(response.status, .seeOther)
        XCTAssertEqual(response.headers[.location].first, "/admin/")
    }
    
    func testPasswordIsNotUpdatedWhenEmptyPasswordProvidedWhenEditingUser() throws {
        struct EditUserData: Content {
            static let defaultContentType = HTTPMediaType.urlEncodedForm
            var name = "Luke"
            var username = "lukes"
            var password = ""
            var confirmPassword = ""
        }

        let oldPassword = user.password
        let editData = EditUserData()
        let response = try testWorld.getResponse(to: "/admin/users/\(user.userID!)/edit", body: editData, loggedInUser: user)

        XCTAssertEqual(testWorld.context.repository.users.count, 1)
        let updatedUser = try XCTUnwrap(testWorld.context.repository.users.last)
        XCTAssertEqual(updatedUser.password, oldPassword)
        XCTAssertEqual(updatedUser.userID, user.userID)
        XCTAssertEqual(response.status, .seeOther)
        XCTAssertEqual(response.headers[.location].first, "/admin/")
    }

    func testErrorShownWhenUpdatingUsersPasswordWithNonMatchingPasswords() throws {
        struct EditUserData: Content {
            static let defaultContentType = HTTPMediaType.urlEncodedForm
            var name = "Luke"
            var username = "lukes"
            var password = "anewpassword"
            var confirmPassword = "someotherpassword"
        }

        let editData = EditUserData()
        _ = try testWorld.getResponse(to: "/admin/users/\(user.userID!)/edit", body: editData, loggedInUser: user)

        let viewErrors = try XCTUnwrap(presenter.createUserErrors)
        XCTAssertTrue(viewErrors.contains("Your passwords must match"))
        let passwordError = try XCTUnwrap(presenter.createUserPasswordError)
        let confirmPasswordError = try XCTUnwrap(presenter.createUserConfirmPasswordError)
        XCTAssertEqual(presenter.createUserUserID, user.userID)
        XCTAssertTrue(passwordError)
        XCTAssertTrue(confirmPasswordError)
    }

    func testErrorShownWhenChangingUsersPasswordWithShortPassword() throws {
        struct EditUserData: Content {
            static let defaultContentType = HTTPMediaType.urlEncodedForm
            var name = "Luke"
            var username = "lukes"
            var password = "a"
            var confirmPassword = "a"
        }

        let editData = EditUserData()
        _ = try testWorld.getResponse(to: "/admin/users/\(user.userID!)/edit", body: editData, loggedInUser: user)

        let viewErrors = try XCTUnwrap(presenter.createUserErrors)
        XCTAssertTrue(viewErrors.contains("Your password must be at least 10 characters long"))
        let passwordError = try XCTUnwrap(presenter.createUserPasswordError)
        XCTAssertTrue(passwordError)
    }

    func testPasswordIsActuallyHashedWhenEditingAUser() throws {
        try testWorld.shutdown()
        testWorld = try TestWorld.create(passwordHasherToUse: .reversed)
        let usersPassword = "password"
        let hashedPassword = String(usersPassword.reversed())
        user = testWorld.createUser(name: "Leia", username: "leia", password: hashedPassword)

        struct EditUserData: Content {
            static let defaultContentType = HTTPMediaType.urlEncodedForm
            var name = "Darth Vader"
            var username = "darth_vader"
            var password = "somenewpassword"
            var confirmPassword = "somenewpassword"
        }

        let editData = EditUserData()
        _ = try testWorld.getResponse(to: "/admin/users/\(user.userID!)/edit", body: editData, loggedInUser: user, passwordToLoginWith: usersPassword)

        let updatedUser = try XCTUnwrap(testWorld.context.repository.users.last)
        XCTAssertEqual(updatedUser.password, String(editData.password.reversed()))
    }

    func testNameMustBeSetWhenEditingAUser() throws {
        struct EditUserData: Content {
            static let defaultContentType = HTTPMediaType.urlEncodedForm
            var name = ""
            var username = "darth_vader"
            var password = "somenewpassword"
            var confirmPassword = "somenewpassword"
        }

        let editData = EditUserData()
        _ = try testWorld.getResponse(to: "/admin/users/\(user.userID!)/edit", body: editData, loggedInUser: user)

        let editErrors = try XCTUnwrap(presenter.createUserErrors)
        XCTAssertTrue(editErrors.contains("You must specify a name"))
        let nameError = try XCTUnwrap(presenter.createUserNameError)
        XCTAssertTrue(nameError)
    }

    func testUsernameMustBeSetWhenEditingAUser() throws {
        struct EditUserData: Content {
            static let defaultContentType = HTTPMediaType.urlEncodedForm
            var name = "Darth Vader"
            var username = ""
            var password = "somenewpassword"
            var confirmPassword = "somenewpassword"
        }

        let editData = EditUserData()
        _ = try testWorld.getResponse(to: "/admin/users/\(user.userID!)/edit", body: editData, loggedInUser: user)

        let editErrors = try XCTUnwrap(presenter.createUserErrors)
        XCTAssertTrue(editErrors.contains("You must specify a username"))
        let usernameError = try XCTUnwrap(presenter.createUserUsernameError)
        XCTAssertTrue(usernameError)
    }

    // MARK: - Delete users

    func testCanDeleteUser() throws {
        let user2 = testWorld.createUser(name: "Han", username: "han")

        let response = try testWorld.getResponse(to: "/admin/users/\(user2.userID!)/delete", body: EmptyContent(), loggedInUser: user)

        XCTAssertEqual(response.status, .seeOther)
        XCTAssertEqual(response.headers[.location].first, "/admin/")
        XCTAssertEqual(testWorld.context.repository.users.count, 1)
        XCTAssertNotEqual(testWorld.context.repository.users.last?.name, "Han")
    }

    func testCannotDeleteSelf() throws {
        let user2 = testWorld.createUser(name: "Han", username: "han")
        let testData = try testWorld.createPost(author: user2)

        _ = try testWorld.getResponse(to: "/admin/users/\(user2.userID!)/delete", body: EmptyContent(), loggedInUser: user2)

        let viewErrors = try XCTUnwrap(presenter.adminViewErrors)
        XCTAssertTrue(viewErrors.contains("You cannot delete yourself whilst logged in"))
        XCTAssertEqual(testWorld.context.repository.users.count, 2)
        
        XCTAssertEqual(presenter.adminViewPosts?.count, 1)
        XCTAssertEqual(presenter.adminViewPosts?.first?.title, testData.post.title)
        XCTAssertEqual(presenter.adminViewUsers?.count, 2)
        XCTAssertEqual(presenter.adminViewUsers?.last?.username, user2.username)
    }

    func testCannotDeleteLastUser() throws {
        try testWorld.shutdown()
        testWorld = try TestWorld.create()
        let adminUser = testWorld.createUser(name: "Admin", username: "admin")
        let testData = try testWorld.createPost(author: adminUser)
        _ = try testWorld.getResponse(to: "/admin/users/\(adminUser.userID!)/delete", body: EmptyContent(), loggedInUser: adminUser)

        let viewErrors = try XCTUnwrap(presenter.adminViewErrors)
        XCTAssertTrue(viewErrors.contains("You cannot delete the last user"))
        XCTAssertEqual(testWorld.context.repository.users.count, 1)
        
        XCTAssertEqual(presenter.adminViewPosts?.count, 1)
        XCTAssertEqual(presenter.adminViewPosts?.first?.title, testData.post.title)
        XCTAssertEqual(presenter.adminViewUsers?.count, 1)
        XCTAssertEqual(presenter.adminViewUsers?.first?.username, adminUser.username)
    }

}
