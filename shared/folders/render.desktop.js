// @flow
import List from './list'
import React, {Component} from 'react'
import type {Props} from './render'
import {Box, TabBar} from '../common-adapters'
import {TabBarItem, TabBarButton} from '../common-adapters/tab-bar'
import {globalStyles, globalColors, globalMargins} from '../styles'

class FoldersRender extends Component<void, Props, void> {
  _makeItem (isPublic: boolean, isSelected: boolean) {
    const icon = isPublic ? 'iconfont-folder-public' : 'iconfont-folder-private'
    const selectedColor = isPublic ? globalColors.yellowGreen : globalColors.darkBlue2
    const iconStyle = isPublic
      ? {color: globalColors.yellowGreen, marginBottom: isSelected ? 0 : 0, opacity: isSelected ? 1.0 : 0.6}
      : {color: globalColors.darkBlue2, marginBottom: isSelected ? 0 : 0, opacity: isSelected ? 1.0 : 0.6}
    return <TabBarButton
      source={{type: 'icon', icon}}
      style={{
        ...styleItem,
        borderBottom: `solid 2px ${isSelected ? selectedColor : 'transparent'}`,
      }}
      styleBadge={styleBadge}
      styleIcon={{...styleIcon, ...iconStyle}}
      styleLabel={{
        color: isPublic
          ? (isSelected ? globalColors.black_75 : globalColors.white_75)
          : (isSelected ? globalColors.white : globalColors.black_60),
        fontSize: 12,
      }}
      styleBadgeNumber={styleBadgeNumber}
      selected={isSelected}
      label={isPublic ? 'public/' : 'private/'}
      badgeNumber={isPublic ? this.props.publicBadge : this.props.privateBadge}
    />
  }

  render () {
    const sharedListProps = {
      style: this.props.listStyle,
      smallMode: this.props.smallMode,
      onRekey: this.props.onRekey,
      onOpen: this.props.onOpen,
      onClick: this.props.onClick,
    }

    return (
      <Box style={{...stylesContainer, backgroundColor: this.props.showingPrivate ? globalColors.darkBlue3 : globalColors.lightGrey, paddingTop: 0, minHeight: 32}}>
        <TabBar styleTabBar={{...tabBarStyle, backgroundColor: this.props.showingPrivate ? globalColors.darkBlue : globalColors.white, minHeight: this.props.smallMode ? 32 : 48, paddingTop: this.props.smallMode ? 0 : 8}}>
          {
            [false, true].map(isPublic => (
              <TabBarItem
                key={isPublic ? 'public' : 'private'}
                selected={this.props.showingPrivate !== isPublic}
                styleContainer={itemContainerStyle}
                tabBarButton={this._makeItem(isPublic, this.props.showingPrivate !== isPublic)}
                onClick={() => { this.props.onSwitchTab && this.props.onSwitchTab(!isPublic) }}>
                <List
                  {...(isPublic ? this.props.public : this.props.private)}
                  {...sharedListProps}
                  isPublic={isPublic}
                  showIgnored={isPublic ? this.props.publicShowingIgnored : this.props.privateShowingIgnored}
                  onToggleShowIgnored={() => this.props.onToggleShowIgnored(!isPublic)} />
              </TabBarItem>
            ))}
        </TabBar>
      </Box>
    )
  }
}

const stylesContainer = {
  ...globalStyles.flexBoxColumn,
  flexGrow: 1,
}

const styleBadge = {
  borderWidth: 0,
  minWidth: 13,
  minHeight: 13,
  borderRadius: 20,
  flex: 'initial',
  justifyContent: 'center',
  marginRight: 2,
  marginLeft: 4,
}

const styleIcon = {
  marginBottom: 2,
}

const styleItem = {
  ...globalStyles.flexBoxRow,
  paddingTop: 8,
  paddingBottom: 8,
  paddingLeft: globalMargins.medium,
  paddingRight: globalMargins.medium,
  justifyContent: 'flex-start',
  backgroundColor: globalColors.transparent,
}

const styleBadgeNumber = {
  lineHeight: '12px',
  fontSize: 10,
}

const itemContainerStyle = {
  ...globalStyles.flexBoxColumn,
  marginBottom: -1,
}

const tabBarStyle = {
  ...globalStyles.flexBoxRow,
}

export default FoldersRender
