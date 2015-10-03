kd              = require 'kd'
React           = require 'kd-react'
immutable       = require 'immutable'
ActivityFlux    = require 'activity/flux'
ChatPane        = require 'activity/components/chatpane'
ChatInputFlux   = require 'activity/flux/chatinput'
ChatInputWidget = require 'activity/components/chatinputwidget'


module.exports = class PublicChatPane extends React.Component

  @defaultProps =
    thread   : immutable.Map()
    messages : immutable.List()
    padded   : no

  constructor: (props) ->

    super props

    @state =
      showIntegrationTooltip   : no
      showCollaborationTooltip : no


  channel: (key) -> @props.thread?.getIn ['channel', key]


  onSubmit: ({ value }) ->

    return  unless body = value
    name = @channel 'name'

    unless body.match ///\##{name}///
      body += " ##{name} "

    ActivityFlux.actions.message.createMessage @channel('id'), body


  onLoadMore: ->

    return  unless @props.messages.size
    return  if @props.thread.getIn ['flags', 'isMessagesLoading']

    from = @props.messages.first().get('createdAt')
    kd.utils.defer => ActivityFlux.actions.message.loadMessages @channel('id'), { from }


  onFollowChannel: ->

    ActivityFlux.actions.channel.followChannel @channel 'id'


  startCollaboration: (event) ->

    kd.utils.stopDOMEvent event

    @setState showCollaborationTooltip: yes

    kd.utils.wait 2000, => @setState showCollaborationTooltip: no


  inviteOthers: (event) ->

    kd.utils.stopDOMEvent event

    chatInputWidget = @refs.chatInputWidget
    textInput = React.findDOMNode chatInputWidget.refs.textInput
    textInput.focus()

    ChatInputFlux.actions.value.setValue @props.thread.get('channelId'), '/invite @'


  addIntegration: (event) ->

    kd.utils.stopDOMEvent event

    @setState showIntegrationTooltip: yes

    kd.utils.wait 2000, => @setState showIntegrationTooltip: no


  renderFollowChannel: ->

    <div className="PublicChatPane-subscribeContainer">
      YOU NEED TO FOLLOW THIS CHANNEL TO JOIN THE CONVERSATION
      <button
        ref       = "button"
        className = "Button Button-followChannel"
        onClick   = { @bound 'onFollowChannel' }>
          FOLLOW CHANNEL
      </button>
    </div>


  renderFooter: ->

    return null  unless @props.messages

    { thread } = @props

    footerInnerComponent = if @channel 'isParticipant'
    then <ChatInputWidget ref='chatInputWidget' onSubmit={@bound 'onSubmit'} thread= {thread} enableSearch={yes} />
    else @renderFollowChannel()

    <footer className="PublicChatPane-footer">
      {footerInnerComponent}
    </footer>


  render: ->

    <ChatPane
      thread             = { @props.thread }
      className          = "PublicChatPane"
      messages           = { @props.messages }
      onSubmit           = { @bound 'onSubmit' }
      onLoadMore         = { @bound 'onLoadMore' }
      inviteOthers       = { @bound 'inviteOthers' }
      addIntegration     = { @bound 'addIntegration' }
      startCollaboration = { @bound 'startCollaboration' }
      showIntegrationTooltip = { @state.showIntegrationTooltip }
      showCollaborationTooltip = { @state.showCollaborationTooltip }
    >
      {@renderFooter()}
    </ChatPane>


