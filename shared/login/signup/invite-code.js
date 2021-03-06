// @flow
import * as signupActions from '../../actions/signup'
import React, {Component} from 'react'
import Render from './invite-code.render'
import {bindActionCreators} from 'redux'
import {connect} from 'react-redux'

class InviteCode extends Component {
  render () {
    return (
      <Render
        inviteCode={this.props.inviteCode}
        onRequestInvite={this.props.startRequestInvite}
        onInviteCodeSubmit={this.props.checkInviteCode}
        inviteCodeErrorText={this.props.errorText}
        onBack={this.props.restartSignup}
        waiting={this.props.waiting} />
    )
  }
}

InviteCode.propTypes = {
  checkInviteCode: React.PropTypes.func,
  errorText: React.PropTypes.string,
}

// $FlowIssue type this connector
export default connect(
  state => ({
    errorText: state.signup.inviteCodeError,
    inviteCode: state.signup.inviteCode,
    waiting: state.signup.waiting,
  }),
    dispatch => bindActionCreators({
      ...signupActions,
    }, dispatch)
)(InviteCode)
