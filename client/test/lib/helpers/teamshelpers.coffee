helpers    = require '../helpers/helpers.js'
utils      = require '../utils/utils.js'
path       = require 'path'
awsKeyPath = path.resolve __dirname, '../../../../../config/aws/worker_ci_test_key.json'
awsKey     = require awsKeyPath

teamsModalSelector       = '.TeamsModal--groupCreation'
companyNameSelector      = '.login-form input[testpath=company-name]'
sidebarSectionsSelector  = '.activity-sidebar .SidebarChannelsSection'
chatItem                 = '.Pane-body .ChatList .ChatItem'
chatInputSelector        = '.ChatPaneFooter .ChatInputWidget textarea'
invitationsModalSelector = '.kdmodal-content  .AppModal--admin-tabs .invitations'
pendingMembersTab        = "#{invitationsModalSelector} .kdtabhandle.pending-invitations"
pendingMemberView        = "#{invitationsModalSelector} .kdlistitemview-member.pending"
teamsLoginModal          = '.TeamsModal--login'


module.exports =


  enterTeamURL: (browser) ->

    browser
      .waitForElementVisible  '[testpath=main-header]', 20000
      .waitForElementVisible  '.TeamsModal--domain', 20000
      .waitForElementVisible  'input[name=slug]', 20000
      .click                  'button[testpath=domain-button]'
      .pause                  2000 # wait for modal change


  fillUsernamePasswordForm: (browser, user) ->

    doneButton         = "#{teamsModalSelector} button.TeamsModal-button--green"
    usernameInput      = "#{teamsModalSelector} input[name=username]"
    passwordInput      = "#{teamsModalSelector} input[name=password]"
    alreadyMemberModal = "#{teamsModalSelector}.alreadyMember"

    browser
      .waitForElementVisible   teamsModalSelector, 20000
      .element 'css selector', alreadyMemberModal, (result) =>
        if result.status is 0
          browser
            .waitForElementVisible  passwordInput, 20000
            .setValue               passwordInput, user.password
        else
          browser
            .waitForElementVisible  usernameInput, 20000
            .clearValue             usernameInput
            .setValue               usernameInput, user.username
            .setValue               passwordInput, user.password

        browser
          .click doneButton
          .pause 2000 # wait for modal change

        @loginAssertion(browser)


  loginAssertion: (browser) ->

    user = utils.getUser()

    browser
      .waitForElementVisible  '[testpath=main-sidebar]', 20000 # Assertion

    console.log " ✔ Successfully logged in with username: #{user.username} and password: #{user.password} to team: #{helpers.getUrl(yes)}"


  loginToTeam: (browser, user, invalidCredentials = no) ->

    incorrectEmailAddress = 'a@b.com'
    incorrectUserName     = 'testUserName'
    wrongPassword         = 'password'
    unrecognizedMessage   = 'Unrecognized email'
    unknownUserMessage    = 'Unknown user name'
    wrongPasswordMessage  = 'Access denied'

    browser
      .pause                  2000 # wait for login page
      .waitForElementVisible  teamsLoginModal, 20000
      .waitForElementVisible  'form.login-form', 20000

    if invalidCredentials
      @insertInvalidCredentials(browser, incorrectEmailAddress, user.password, unrecognizedMessage)
      @insertInvalidCredentials(browser, incorrectUserName, user.password, unknownUserMessage)
      @insertInvalidCredentials(browser, user.username, wrongPassword, wrongPasswordMessage)
    else
      browser
        .setValue  inputUserName, user.username
        .setValue  inputPassword, user.password
        .click     loginButton

      @loginAssertion(browser)


  insertInvalidCredentials: (browser, usernameOrEmail, password, errorMessage) ->

    inputUserName        = 'input[name=username]'
    inputPassword        = 'input[name=password]'
    notificationSelector = '.team .kdnotification.main'
    loginButton          = 'button[testpath=login-button]'

    browser
      .setValue               inputUserName, usernameOrEmail
      .setValue               inputPassword, password
      .click                  loginButton
      .waitForElementVisible  notificationSelector, 20000
      .assert.containsText    notificationSelector, errorMessage
      .pause                  2000 # wait for notification to disappear
      .clearValue             inputUserName


  loginTeam: (browser, invalidCredentials = no) ->

    user = utils.getUser()
    url  = helpers.getUrl(yes)

    stackCatalogModal = '.StackCatalogModal'
    closeButton       = "#{stackCatalogModal} .kdmodal-inner .closeModal"

    browser.url url
    browser.maximizeWindow()

    browser.pause  3000
    browser.element 'css selector', teamsLoginModal, (result) =>
      if result.status is 0
        if invalidCredentials
          @loginToTeam browser, user, yes
        else
          @loginToTeam browser, user
      else
        @createTeam browser

      browser.pause 3000
      browser.element 'css selector', stackCatalogModal, (result) ->
        if result.status is 0
           browser
            .waitForElementVisible  stackCatalogModal, 20000
            .waitForElementVisible  closeButton, 20000
            .click                  closeButton

    return user


  closeTeamSettingsModal: (browser) ->

    adminModal  = '.AppModal.AppModal--admin.team-settings'
    closeButton = "#{adminModal} .closeModal"

    browser
      .waitForElementVisible adminModal, 20000
      .click                 closeButton


  logoutTeam: (browser) ->

    logoutLink = '.avatararea-popup.team a[href="/Logout"]'

    helpers.openAvatarAreaModal(browser, yes)

    browser
      .waitForElementVisible logoutLink, 20000
      .click                 logoutLink
      .waitForElementVisible teamsLoginModal, 20000


  createTeam: (browser, user, callback) ->

    modalSelector       = '.TeamsModal.TeamsModal--create'
    emailSelector       = "#{modalSelector} input[name=email]"
    companyNameSelector = "#{modalSelector} input[name=companyName]"
    signUpButton        = "#{modalSelector} button[type=submit]"
    user                = utils.getUser()
    invitationLink      = "#{helpers.getUrl()}/Teams/Create?email=#{user.email}"

    browser
      .url                   invitationLink
      .waitForElementVisible modalSelector, 20000
      .waitForElementVisible emailSelector, 20000
      .waitForElementVisible companyNameSelector, 20000
      .clearValue            emailSelector
      .setValue              emailSelector, user.email
      .pause                 2000
      .setValue              companyNameSelector, user.teamSlug
      .click                 signUpButton
      .pause                 2500

    @enterTeamURL(browser)
    @fillUsernamePasswordForm(browser, user)


  createInvitation: (browser, user, callback) ->

    adminLink      = '.avatararea-popup a[href="/Admin"]'
    inviteLink     = '.invite-teams.AppModal-navItem'
    teamInvitePage = '.TeamInvite'
    inviteButton   = "#{teamInvitePage} button"
    sendMailPage   = "#{teamInvitePage} .kdscrollview"
    sendMailButton = "#{teamInvitePage} button.green:not(.hidden)"
    notification   = '.kdnotification.main'

    helpers.openAvatarAreaModal(browser)
    browser
      .waitForElementVisible  adminLink, 20000
      .click                  adminLink
      .waitForElementVisible  inviteLink, 20000
      .click                  inviteLink
      .waitForElementVisible  teamInvitePage, 20000
      .setValue               "#{teamInvitePage} textarea.text", user.email
      .waitForElementVisible  inviteButton, 20000
      .click                  inviteButton
      .waitForElementVisible  sendMailPage, 20000
      .assert.containsText    sendMailPage, user.email # Assertion
      .waitForElementVisible  sendMailButton, 20000
      .click                  sendMailButton
      .waitForElementVisible  notification, 20000
      .assert.containsText    notification, 'Invitations sent!'
      .pause                  2000
      .getAttribute           "#{sendMailPage} a" , 'href', (result) ->
        callback result.value


  openTeamSettingsModal: (browser) ->

    avatarareaPopup  = '.avatararea-popup.team'
    teamDashboard    = '.AppModal--admin'
    teamSettingsLink = "#{avatarareaPopup} .admin a"

    browser
      .waitForElementVisible  avatarareaPopup, 20000
      .waitForElementVisible  teamSettingsLink, 20000
      .click                  teamSettingsLink
      .waitForElementVisible  teamDashboard, 20000 # Assertion
      .pause                  200 # Wait for team settings
      .assert.containsText    teamDashboard, 'Team Settings' # Assertion


  clickTeamSettings: (browser) ->

    helpers.openAvatarAreaModal(browser, yes)
    @openTeamSettingsModal(browser)


  startStackCreate: (browser) ->

    stackCreateButton        = '.activity-sidebar .SidebarTeamSection a[href="/Stacks/Welcome"]'
    stackCatalogModal        = '.StackCatalogModal'
    teamStackTemplatesButton = "#{stackCatalogModal} .kdtabhandle-tabs .team-stack-templates"
    stackPage                = '.stacks .stack-onboarding.get-started'

    browser
      .waitForElementVisible  stackCreateButton, 20000
      .click                  stackCreateButton
      .waitForElementVisible  teamStackTemplatesButton, 20000
      .click                  teamStackTemplatesButton
      .waitForElementVisible  stackPage, 20000


  openInvitationsTab: (browser) ->

    tabsSelector              = '.kdmodal-content .kdtabhandle-tabs'
    invitationsButtonSelector = "#{tabsSelector} .invitations"
    invitationsPageSelector   = '.kdmodal-content  .AppModal--admin-tabs .invitations'

    browser
      .waitForElementVisible  tabsSelector, 20000
      .waitForElementVisible  "#{tabsSelector} .invitations", 20000
      .waitForElementVisible  invitationsButtonSelector, 20000
      .click                  invitationsButtonSelector
      .waitForElementVisible  invitationsPageSelector, 20000 # Assertion
      .pause                  2000 # wait for page load


  moveToSidebarHeader: (browser, plus, channelHeader) ->

    sidebarSectionsHeaderSelector = "#{sidebarSectionsSelector} .SidebarSection-header"
    channelPlusSelector           = "#{sidebarSectionsHeaderSelector} a[href='/NewChannel']"

    browser
      .pause                   7500 # wait for load to sidebar
      .waitForElementVisible   sidebarSectionsSelector, 20000
      .moveToElement           sidebarSectionsHeaderSelector, 100, 7

    if plus
      browser
        .moveToElement          channelPlusSelector, 8, 5
        .waitForElementVisible  channelPlusSelector, 20000
        .click                  channelPlusSelector
    else if channelHeader
      browser
        .click                  sidebarSectionsHeaderSelector


  inviteUser: (browser, addMoreUser = no) ->

    invitationsModalSelector = '.kdmodal-content  .AppModal--admin-tabs .invitations'
    inviteUserView           = "#{invitationsModalSelector} .invite-view"
    emailInputSelector       = "#{inviteUserView} .invite-inputs input.user-email"
    userEmail                = "#{helpers.getFakeText().split(' ')[0]}#{Date.now()}@kd.io"
    inviteMemberButton       = "#{invitationsModalSelector} button.invite-members"
    confirmModal             = '.admin-invite-confirm-modal'
    confirmButton            = "#{confirmModal} button.confirm"
    notificationView         = '.kdnotification'

    browser
      .waitForElementVisible  inviteUserView, 20000
      .waitForElementVisible  emailInputSelector, 20000
      .setValue               emailInputSelector, userEmail
      .waitForElementVisible  inviteMemberButton, 20000
      .click                  inviteMemberButton

    browser.pause  2000 # wait for modal
    browser.element 'css selector', confirmModal, (result) ->
      if result.status is 0
        browser
          .waitForElementVisible confirmButton, 20000
          .click                 confirmButton

      successMessage = if addMoreUser
      then 'Invitation is sent to'
      else "Invitation is sent to #{userEmail}"

      browser
        .waitForElementVisible  notificationView, 20000
        .assert.containsText    notificationView, successMessage
        .pause                  2000 # wait for notification

      if addMoreUser
        browser
          .waitForElementVisible  emailInputSelector, 20000
      else
        browser
          .click                  pendingMembersTab
          .waitForElementVisible  pendingMemberView, 20000
          .assert.containsText    pendingMemberView, userEmail

    return userEmail


  clickPendingInvitations: (browser, openTab = yes) ->

    if openTab
      @clickTeamSettings(browser)
      @openInvitationsTab(browser)

    browser
      .waitForElementVisible  pendingMembersTab, 20000
      .click                  pendingMembersTab
      .waitForElementVisible  pendingMemberView, 20000 # Assertion


  invitationAction: (browser, userEmail, revoke) ->

    pendingMemberView         = "#{invitationsModalSelector} .kdlistitemview-member.pending"
    pendingMemberViewTime     = "#{pendingMemberView} time"
    pendingMemberViewSettings = "#{pendingMemberView}.settings-visible .settings"
    actionButton              = "#{pendingMemberViewSettings} .resend-button"
    invitedMemberAvatar       = "#{invitationsModalSelector} span[title='#{userEmail}']"

    if revoke
      actionButton = "#{pendingMemberViewSettings} .revoke-button"

    @clickPendingInvitations(browser, no)

    browser
      .waitForElementVisible  pendingMemberViewTime, 20000
      .click                  pendingMemberViewTime
      .waitForElementVisible  actionButton, 20000
      .pause                  3000
      .click                  actionButton

    if revoke
      browser
        .waitForElementNotPresent invitedMemberAvatar, 20000
        .expect.element(invitationsModalSelector).text.to.not.contain userEmail
    else
      browser
        .waitForElementVisible '.kdnotification', 20000 # Assertion
        .assert.containsText   '.kdnotification', 'Invitation is resent.'


  searchPendingInvitation: (browser, userEmail) ->

    pendingInvitations  = '.member-related .pending-invitations'
    searchSelector      = "#{pendingInvitations} .search"
    searchInputSelector = "#{searchSelector} input"
    emailList           = "#{pendingInvitations} .listview-wrapper"

    browser
      .waitForElementVisible     searchSelector, 20000
      .waitForElementVisible     searchInputSelector, 20000
      .click                     searchInputSelector
      .setValue                  searchInputSelector, userEmail + browser.Keys.ENTER
      .pause                     5000 # wait for listing
      .waitForElementVisible     emailList, 20000
      .assert.containsText       emailList, userEmail


  createStack: (browser, skipStackSetup = no) ->

    stackCreatePage       = '.Group-Stack-Templates .get-started'
    getStartedButton      = "#{stackCreatePage} .header button.green"
    modalSelector         = '.kdmodal-content .AppModal-content'
    providerSelector      = "#{modalSelector} .stack-onboarding .provider-selection"
    machineSelector       = "#{providerSelector} .providers"
    stackPreview          = "#{modalSelector} .stack-preview"
    codeSelector          = "#{stackPreview} .has-markdown"
    footerSelector        = "#{modalSelector} .stacks .footer"
    nextButtonSelector    = "#{footerSelector} button.next"
    awsSelector           = "#{machineSelector} .aws"
    configurationSelector = "#{modalSelector} .configuration .server-configuration"
    inputSelector         = "#{configurationSelector} .Database"
    mysqlSelector         = "#{inputSelector} .mysql input.checkbox + label"
    postgresqlSelector    = "#{inputSelector} .postgresql input.checkbox + label"
    server1PageSelector   = "#{modalSelector} .code-setup .server-1"
    githubSelector        = "#{server1PageSelector} .box-wrapper .github"
    bitbucketSelector     = "#{server1PageSelector} .box-wrapper .bitbucket"
    editorSelector        = "#{modalSelector} .editor-main"
    skipSetupSelector     = '.footer .skip-setup'
    stackTemplateSelector = '.kdtabhandlecontainer.hide-close-icons .stack-template'
    saveAndTestButton     = '.buttons button:nth-of-type(5)'

    @startStackCreate(browser)

    browser
      .waitForElementVisible  stackCreatePage, 20000
      .waitForElementVisible  getStartedButton, 20000
      .click                  getStartedButton

    if skipStackSetup
      browser
        .waitForElementVisible  skipSetupSelector, 20000
        .click                  skipSetupSelector
        .waitForElementVisible  stackTemplateSelector, 20000
        .assert.containsText    stackTemplateSelector, 'Stack Template'
        .assert.containsText    saveAndTestButton, 'SAVE & TEST'
    else
      browser
        .waitForElementVisible  providerSelector, 20000
        .waitForElementVisible  awsSelector, 20000
        .waitForElementVisible  "#{machineSelector} .vagrant" , 20000 # Assertion
        .click                  awsSelector
        .waitForElementVisible  stackPreview, 20000
        .waitForElementVisible  codeSelector, 20000
        .assert.containsText    codeSelector, 'koding_group_slug'
        .waitForElementVisible  footerSelector, 20000
        .waitForElementVisible  nextButtonSelector, 20000
        .pause                  2000 # wait for animation
        .click                  nextButtonSelector
        .waitForElementVisible  configurationSelector, 20000
        .pause                  2000 # wait for animation
        .waitForElementVisible  mysqlSelector, 20000
        .click                  mysqlSelector
        .pause                  2000 # wait for animation
        .waitForElementVisible  postgresqlSelector, 20000
        .click                  postgresqlSelector
        .waitForElementVisible  stackPreview, 20000
        .assert.containsText    codeSelector, 'mysql-server postgresql'
        .waitForElementVisible  nextButtonSelector, 20000
        .pause                  2000 # wait for animation
        .click                  nextButtonSelector
        .waitForElementVisible  server1PageSelector, 20000
        .waitForElementVisible  githubSelector, 20000 # Assertion
        .waitForElementVisible  bitbucketSelector, 20000 # Assertion
        .waitForElementVisible  nextButtonSelector, 20000
        .moveToElement          nextButtonSelector, 15, 10
        .pause                  2000
        .click                  nextButtonSelector
        .waitForElementVisible  "#{modalSelector} .define-stack-view", 20000
        .waitForElementVisible  editorSelector, 20000
        .pause                  1000
        .assert.containsText    editorSelector, 'aws_instance'


  createCredential: (browser, show = no, remove = no, use = no) ->

    credetialTabSelector   = '.team-stack-templates .kdtabhandle-tabs .credentials'
    stackTabSelector       = '.team-stack-templates .kdtabhandle.stack-template.active'
    credentialsPane        = '.credentials-form-view'
    editorSelector         = '.editor-main'
    saveButtonSelector     = '.add-credential-scroll .button-field button.green'
    newCredential          = '.step-creds .listview-wrapper .credential-list .credential-item'
    credentialName         = 'test credential'
    showCredentialButton   = "#{newCredential} button.show"
    deleteCredentialButton = "#{newCredential} button.delete"
    useCredentialButton    = "#{newCredential} button.verify"
    inUseLabelSelector     = "#{newCredential} .custom-tag.inuse"
    secretKeyInput         = "#{credentialsPane} .secret-key input"

    { accessKeyId, secretAccessKey } = @getAwsKey()

    keyPart    = accessKeyId.substr accessKeyId.length - 6
    secretPart = secretAccessKey.substr secretAccessKey.length - 13

    browser
      .waitForElementVisible  credetialTabSelector, 20000
      .moveToElement          credetialTabSelector, 50, 21
      .click                  credetialTabSelector
      .pause                  2000

    browser.element 'css selector', newCredential, (result) ->
      if result.status is -1
        browser
          .waitForElementVisible  credentialsPane, 20000
          .setValue               "#{credentialsPane} .title input", credentialName
          .pause                  500
          .setValue               "#{credentialsPane} .access-key input", accessKeyId
          .pause                  500
          .scrollToElement        secretKeyInput
          .setValue               secretKeyInput, secretAccessKey
          .pause                  1000
          .click                  '.credential-creation-intro'
          .scrollToElement        saveButtonSelector
          .click                  saveButtonSelector
          .pause                  2000 # wait for loade next page
          .waitForElementVisible  newCredential, 20000
          .assert.containsText    newCredential, credentialName

      browser
        .waitForElementVisible    newCredential, 20000
        .moveToElement            newCredential, 300, 20
        .pause                    1000

      if show
       browser
          .waitForElementVisible  showCredentialButton, 20000
          .click                  showCredentialButton
          .waitForElementVisible  '.credential-modal', 20000
          .pause                  2000
          .assert.containsText    '.credential-modal .kdmodal-title', 'test credential'
          .assert.containsText    '.credential-modal .kdmodal-content', keyPart
          .assert.containsText    '.credential-modal .kdmodal-content', secretPart

      if remove
        browser
          .waitForElementVisible    deleteCredentialButton, 20000
          .click                    deleteCredentialButton
          .pause                    1000
          .waitForElementVisible    '.remove-credential', 20000
          .assert.containsText      '.remove-credential', credentialName
          .click                    '.remove-credential button.red'
          .pause                    2000
          .waitForElementNotPresent newCredential, 20000

      if use
        browser
          .waitForElementVisible    useCredentialButton, 20000
          .click                    useCredentialButton
          .waitForElementVisible    stackTabSelector, 20000
          .waitForElementVisible    editorSelector, 20000
          .click                    credetialTabSelector
          .pause                    1000
          .waitForElementVisible    newCredential, 20000
          .waitForElementVisible    inUseLabelSelector, 20000


  saveTemplate: (browser) ->

    saveAndTestButton    = '.template-title-form .buttons .save-test'
    editorSelector       = '.stack-template .output .output-view'
    loaderIconNotVisible = "#{saveAndTestButton} .kdloader.hidden"
    stackModal           = '.stack-modal'
    closeButton          = "#{stackModal} .gray"
    stackTabSelector     = '.team-stack-templates .kdtabhandle.stack-template.active'
    closeStackPageButton = '.StackCatalogModal .close-icon'
    sidebarSelector      = '.activity-sidebar .SidebarTeamSection'
    sidebarStackSection  = "#{sidebarSelector} .SidebarStackSection.active"
    finalizeStepsButton  = "#{sidebarSelector} a[href='/Stacks/Welcome']:not(.SidebarSection-headerTitle)"
    envMachineStateModal = '.env-machine-state .has-markdown'

    browser
      .waitForElementVisible     saveAndTestButton, 20000
      .scrollToElement           saveAndTestButton
      .click                     saveAndTestButton
      .waitForElementVisible     editorSelector, 35000
      .waitForElementVisible     '.template-title-form .buttons .save-test .kdloader', 20000
      .waitForElementNotVisible  loaderIconNotVisible, 500000
      .pause                     3000

    browser.element 'css selector', stackModal, (result) ->
      if result.status is 0
        browser
          .assert.containsText    stackModal, 'Your stack script has been successfully saved'
          .waitForElementVisible  closeButton, 20000
          .click                  closeButton

    browser
      .waitForElementVisible     stackTabSelector, 20000
      .waitForElementVisible     closeStackPageButton, 20000
      .click                     closeStackPageButton
      .waitForElementVisible     sidebarStackSection, 20000
      .waitForElementNotPresent  finalizeStepsButton, 20000
      .waitForElementVisible     envMachineStateModal, 20000


  buildStack: (browser) ->

    envMachineStateModal = '.env-machine-state'
    buildStackButton     = "#{envMachineStateModal} .content-container .state-button"
    progressbarContainer = "#{envMachineStateModal} .progressbar-container"
    sidebarSelector      = '.activity-sidebar .SidebarTeamSection'
    sidebarStackSection  = "#{sidebarSelector} .SidebarStackSection.active"
    stackMachine         = "#{sidebarStackSection} .SidebarMachinesListItem.Running.active"

    browser
      .waitForElementVisible     buildStackButton, 20000
      .click                     buildStackButton
      .waitForElementVisible     progressbarContainer, 20000
      .waitForElementNotPresent  progressbarContainer,500000
      .pause                     3000 # wait for machine
      .waitForElementVisible     stackMachine, 20000


  getAwsKey: -> return awsKey


  checkIconsStacks: (browser) ->

    saveAndTestButton           = '.buttons button:nth-of-type(5)'
    stackTemplateSelector       = '.kdtabhandlecontainer.hide-close-icons .stack-template'
    stacksLogsSelector          = '.step-define-stack .kdscrollview'
    myStackTemplatesButton      = '.kdview.kdtabhandle-tabs .my-stack-templates'
    iconsSelector               = '.kdlistitemview-default.stacktemplate-item .stacktemplate-info'
    notReadyIconSelector        = "#{iconsSelector} .not-ready"
    privateIconSelector         = "#{iconsSelector} .private"
    stackTemplateSettingsButton = '.kdbutton.stack-settings-menu'
    deleteButton                = '.kdlistview-contextmenu.expanded .delete'
    confirmDeleteButton         = '.kdview.kdmodal-buttons .solid.red .button-title'

    browser
      .click                      saveAndTestButton
      .pause                      2000 #for stack creation logs to appear
      .waitForElementVisible      stacksLogsSelector, 20000
      .assert.containsText        stacksLogsSelector, 'An error occured: Required credentials are not provided yet'
      .click                      myStackTemplatesButton
      .waitForElementVisible      notReadyIconSelector, 30000
      .assert.containsText        notReadyIconSelector, 'NOT READY'
      .assert.containsText        privateIconSelector, 'PRIVATE'
      .waitForElementVisible      stackTemplateSettingsButton, 20000
      .click                      stackTemplateSettingsButton
      .waitForElementVisible      deleteButton, 20000
      .click                      deleteButton
      .waitForElementVisible      confirmDeleteButton, 20000
      .click                      confirmDeleteButton
      .pause                      2000
      .waitForElementVisible      stackTemplateSelector, 20000
      .assert.containsText        stackTemplateSelector, 'Stack Template'
      .assert.containsText        saveAndTestButton, 'SAVE & TEST'



  fillJoinForm: (browser, userData, assertLoggedIn = yes) ->

    loginForm     = '.TeamsModal.TeamsModal--groupCreation.join'
    emailInput    = "#{loginForm} input[name=email]"
    usernameInput = "#{loginForm} input[name=username]"
    passwordInput = "#{loginForm} input[name=password]"
    joinButton    = "#{loginForm} .TeamsModal-button--green"


    browser
      .waitForElementVisible loginForm, 20000
      .waitForElementVisible emailInput, 20000
      .waitForElementVisible usernameInput, 20000
      .waitForElementVisible passwordInput, 20000
      .waitForElementVisible joinButton, 20000
      .setValue              usernameInput, userData.username
      .setValue              passwordInput, userData.password
      .click                 joinButton

    if assertLoggedIn
      @loginAssertion(browser)


  getInvitationUrl: (browser, email, callback) ->

    fn = (email, done) ->
      options  =
        query  : email
        status : 'pending'

      _remote.api.JInvitation.search options, {}, (err, invitations) ->
        done { err, invitation: invitations[0] }

    browser
      .timeoutsAsyncScript 10000
      .executeAsync fn, [ email ], (result) ->
        { status, value } = result

        if status is -1 or value.err or not value.invitation
          helpers.notifyTestFailure browser, 'inviteUserAndJoinTeam'

        teamUrl       = helpers.getUrl yes
        invitationUrl = "#{teamUrl}/Invitation/#{value.invitation.code}"

        callback invitationUrl
