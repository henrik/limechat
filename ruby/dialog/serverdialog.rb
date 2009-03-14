# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

require 'dialoghelper'

class ServerDialog < NSObject
  include DialogHelper  
  attr_accessor :delegate, :prefix, :parent
  attr_reader :uid
  ib_outlet :window
  ib_mapped_outlet :nameText, :hostCombo, :passwordText, :nickText, :usernameText, :realnameText, :auto_connectCheck, :sslCheck
  ib_mapped_outlet :nickPasswordText
  ib_mapped_int_outlet :portText, :encodingCombo, :fallback_encodingCombo
  ib_mapped_outlet :leaving_commentText, :userinfoText, :invisibleCheck
  ib_mapped_outlet :login_commandsText
  ib_outlet :alt_nicksText
  ib_outlet :channelsTable, :addButton, :editButton, :deleteButton
  ib_outlet :okButton
  
  TABLE_ROW_TYPE = 'row'
  TABLE_ROW_TYPES = [TABLE_ROW_TYPE]
  
  def initialize
    @prefix = 'serverDialog'
  end
  
  def config
    @c
  end
  
  JA_SERVERS = [
    'irc.nara.wide.ad.jp (IRCnet)',
    'irc.tokyo.wide.ad.jp (IRCnet)',
    'irc.fujisawa.wide.ad.jp (IRCnet)',
    'irc.huie.hokudai.ac.jp (IRCnet)',
    'irc.media.kyoto-u.ac.jp (IRCnet)',
    '-',
    'irc.friend-chat.jp (Friend)',
    'irc.2ch.net (2ch)',
    'irc.cre.ne.jp (cre)',
    'irc.reicha.net (Reicha)',
    '-',
    'irc.freenode.net (Freenode)',
    'eu.undernet.org (Undernet)',
    'irc.quakenet.org (QuakeNet)',
    'irc.mozilla.org (Mozilla)',
    'chat1.ustream.tv (Ustream)',
  ]

  SERVERS = [
    'irc.freenode.net (Freenode)',
    'irc.efnet.net (EFnet)',
    'irc.us.ircnet.net (IRCnet)',
    'irc.fr.ircnet.net (IRCnet)',
    'us.undernet.org (Undernet)',
    'eu.undernet.org (Undernet)',
    'irc.quakenet.org (QuakeNet)',
    'uk.quakenet.org (QuakeNet)',
    'irc.mozilla.org (Mozilla)',
  ]
  
  def self.servers
    LanguageSupport.primary_language == 'ja' ? JA_SERVERS : SERVERS
  end
  
  def start(conf, uid)
    @c = conf
    @uid = uid
    NSBundle.loadNibNamed_owner('ServerDialog', self)
    @channelsTable.setTarget(self)
    @channelsTable.setDoubleAction('tableView_doubleClicked:')
  	@channelsTable.registerForDraggedTypes(TABLE_ROW_TYPES);
    @window.setTitle("New Server") if uid < 0
    load
    update_connection_page
    update_channels_page
    onEncodingComboChanged(nil)
    self.class.servers.each {|i| @hostCombo.addItemWithObjectValue(i.split(' ')[0]) }
    show
  end
  
  def show
    @window.centerOfWindow(@parent) unless @window.isVisible
    @window.makeKeyAndOrderFront(self)
  end
  
  def close
    @channelsTable.unregisterDraggedTypes
    @delegate = nil
    @window.close
  end
  
  def windowWillClose(sender)
    fire_event('onClose')
  end
  
  def onOk(sender)
    save
    fire_event('onOk', @c)
    @window.close
  end
  
  def onCancel(sender)
    @window.close
  end
  
  def load
    load_mapped_outlets(@c)
    @alt_nicksText.setStringValue(@c.alt_nicks.join(' '))
  end
  
  def save
    save_mapped_outlets(@c)
    @c.login_commands.delete_if {|i| i =~ /^\s*$/ }
    @c.alt_nicks = @alt_nicksText.stringValue.to_s.split(/[\s,]+/)
    @c.alt_nicks.delete_if {|i| i =~ /^\s+$/ }
  end
  
  def controlTextDidChange(n)
    update_connection_page
  end
  
  def onHostComboChanged(sender)
    update_connection_page
  end
  
  def onEncodingComboChanged(sender)
    sel = @encodingCombo.selectedItem
    if sel && sel.tag == NSUTF8StringEncoding
      @fallback_encodingCombo.setEnabled(true)
    else
      @fallback_encodingCombo.setEnabled(false)
    end
  end
  
  def update_connection_page
    name = @nameText.stringValue.to_s
    host = @hostCombo.stringValue.to_s
    port = @portText.stringValue.to_s
    nick = @nickText.stringValue.to_s
    username = @usernameText.stringValue.to_s
    realname = @realnameText.stringValue.to_s
    @okButton.setEnabled(!name.empty? && !host.empty? && host != '-' && port.to_i > 0 && !nick.empty? && !username.empty? && !realname.empty?)
  end
  
  def update_channels_page
    t = @channelsTable
    sel = t.selectedRows[0]
    unless sel
      @editButton.setEnabled(false)
      @deleteButton.setEnabled(false)
    else
      @editButton.setEnabled(true)
      @deleteButton.setEnabled(true)
    end
  end
  
  def reload_table
    @channelsTable.reloadData
  end
  
  def numberOfRowsInTableView(sender)
    @c.channels.size
  end
  
  def tableView_objectValueForTableColumn_row(sender, col, row)
    i = @c.channels[row]
    col = col.identifier.to_s.to_sym
    case col
    when :name; i.name
    when :pass; i.password
    when :join; i.auto_join
    end
  end
  
  def tableView_setObjectValue_forTableColumn_row(sender, obj, col, row)
    i = @c.channels[row]
    col = col.identifier.to_s.to_sym
    case col
    when :join; i.auto_join = obj.intValue != 0
    end
  end
  
  def tableViewSelectionDidChange(n)
    update_channels_page
  end
  
  def tableView_doubleClicked(sender)
    onEdit(sender)
  end
  
  def tableView_writeRows_toPasteboard(sender, rows, pboard)
    pboard.declareTypes_owner(TABLE_ROW_TYPES, self)
    pboard.setPropertyList_forType(rows, TABLE_ROW_TYPE)
    true
  end
  
  def tableView_validateDrop_proposedRow_proposedDropOperation(sender, info, row, op)
  	pboard = info.draggingPasteboard
  	if op == NSTableViewDropAbove && pboard.availableTypeFromArray(TABLE_ROW_TYPES)
  	  NSDragOperationGeneric
	  else
	    NSDragOperationNone
    end
  end
  
  def tableView_acceptDrop_row_dropOperation(sender, info, row, op)
  	pboard = info.draggingPasteboard
  	return false unless op == NSTableViewDropAbove && pboard.availableTypeFromArray(TABLE_ROW_TYPES)
    ary = @c.channels
    sel = @channelsTable.selectedRows.map {|i| ary[i.to_i] }
    
    targets = pboard.propertyListForType(TABLE_ROW_TYPE).to_a.map {|i| ary[i.to_i] }
    low = ary[0...row] || []
    high = ary[row...ary.size] || []
    targets.each do |i|
      low.delete(i)
      high.delete(i)
    end
    @c.channels = low + targets + high

    unless sel.empty?
      sel = sel.map {|i| @c.channels.index(i) }
      @channelsTable.selectRows(sel)
    end
    reload_table
    true
  end

  def onAdd(sender)
    sel = @channelsTable.selectedRows[0]
    conf = sel ? @c.channels[sel] : IRCChannelConfig.new
    @sheet = ChannelDialog.alloc.init
    @sheet.delegate = self
    @sheet.start_sheet(@window, conf, true)
  end
  
  def onEdit(sender)
    sel = @channelsTable.selectedRows[0]
    return unless sel
    conf = @c.channels[sel]
    @sheet = ChannelDialog.alloc.init
    @sheet.delegate = self
    @sheet.start_sheet(@window, conf)
  end
  
  def channelDialog_onOk(sender, conf)
    i = @c.channels.index {|t| t.name == conf.name }
    if i
      @c.channels[i] = conf
    else
      @c.channels << conf
    end
    reload_table
    @sheet = nil
  end
  
  def channelDialog_onCancel(sender)
    @sheet = nil
  end
  
  def onDelete(sender)
    sel = @channelsTable.selectedRows[0]
    return unless sel
    @c.channels.delete_at(sel)
    count = @c.channels.size
    if count > 0
      if count <= sel
        @channelsTable.select(count - 1)
      else
        @channelsTable.select(sel)
      end
    end
    reload_table
  end
end
