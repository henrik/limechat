# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

require 'utility'
require 'singleton'
require 'model/abstract_preferences_section'

class Preferences
  include Singleton
  
  class Keyword < AbstractPreferencesSection
    defaults_accessor :words, []
    defaults_accessor :dislike_words, []
    defaults_accessor :whole_line, false
    defaults_accessor :current_nick, true
    
    MATCH_PARTIAL = 0
    MATCH_EXACT_WORD = 1
    defaults_accessor :matching_method, MATCH_PARTIAL
  end
  
  class Dcc < AbstractPreferencesSection
    defaults_accessor :first_port, 1096
    defaults_accessor :last_port, 1115
    defaults_accessor :myaddress, ''
    defaults_accessor :auto_receive, false
    
    ADDR_DETECT_JOIN = 0
    ADDR_DETECT_NIC = 1
    ADDR_DETECT_SPECIFY = 2
    defaults_accessor :address_detection_method, ADDR_DETECT_JOIN
  end
  
  class General < AbstractPreferencesSection
    TAB_COMPLETE_NICK = 0
    TAB_UNREAD = 1
    TAB_NONE = 100
    defaults_accessor :tab_action, TAB_COMPLETE_NICK
    
    LAYOUT_2_COLUMNS = 0
    LAYOUT_3_COLUMNS = 1
    defaults_accessor :main_window_layout, LAYOUT_2_COLUMNS
    
    defaults_accessor :confirm_quit, true
    
    defaults_accessor :use_hotkey, false
    defaults_accessor :hotkey_key_code, 0
    defaults_accessor :hotkey_modifier_flags, 0
    
    defaults_accessor :connect_on_doubleclick, false
    defaults_accessor :disconnect_on_doubleclick, false
    defaults_accessor :join_on_doubleclick, true
    defaults_accessor :leave_on_doubleclick, false
    
    defaults_accessor :use_growl, true
    defaults_accessor :stop_growl_on_active, true
    
    defaults_accessor :log_transcript, false
    defaults_accessor :transcript_folder, '~/Documents/LimeChat Transcripts'
    defaults_accessor :max_log_lines, 300
    
    defaults_accessor :paste_syntax, (LanguageSupport.primary_language == 'ja' ? 'notice' : 'privmsg')
  end
  
  class Sound < AbstractPreferencesSection
    [ :login, :disconnect, :highlight, :newtalk, :kicked, :invited, :channeltext, :talktext,
      :file_receive_request, :file_receive_success, :file_receive_failure, :file_send_success, :file_send_failure
    ].each { |attr| defaults_accessor attr, '' }
  end
  
  class Theme < AbstractPreferencesSection
    defaults_accessor :name, 'resource:Default'
    defaults_accessor :override_log_font, false
    defaults_accessor :log_font_name, 'Lucida Grande'
    defaults_accessor :log_font_size, 12
    defaults_accessor :override_nick_format, false
    defaults_accessor :nick_format, '%n: '
    defaults_accessor :override_timestamp_format, false
    defaults_accessor :timestamp_format, '%H:%M'
  end
  
  attr_reader :dcc, :general, :keyword, :sound, :theme
  
  def initialize
    @keyword = Keyword.new
    @general = General.new
    @sound   = Sound.new
    @theme   = Theme.new
    @dcc     = Dcc.new
  end
  
  # def load_world
  #   read_defaults('world')
  # end
  # 
  # def save_world(c)
  #   write_defaults('world', c)
  #   sync
  # end
  # 
  # def load_window(key)
  #   read_defaults(key)
  # end
  # 
  # def save_window(key, value)
  #   write_defaults(key, value)
  #   sync
  # end
  
  private
  
  def sync
    NSUserDefaults.standardUserDefaults.synchronize
  end
  
  # And register the defaults
  register_default_values!
end

module Kernel
  # A shortcut method for easy access anywhere to the shared user defaults
  def preferences
    Preferences.instance
  end
end