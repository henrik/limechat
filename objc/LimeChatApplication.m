// Created by Satoshi Nakagawa.
// You can redistribute it and/or modify it under the Ruby's license or the GPL2.

#import "LimeChatApplication.h"

@interface NSObject (LimeChatApplicationDelegate)
- (void)applicationDidReceiveHotKey:(id)sender;
@end

@implementation LimeChatApplication

- (void)dealloc
{
	[hotkey release];
	[super dealloc];
}

- (void)sendEvent:(NSEvent *)e
{
	if ([e type] == 14 && [e subtype] == 6) {
		if ([[self delegate] respondsToSelector:@selector(applicationDidReceiveHotKey:)]) {
			[[self delegate] applicationDidReceiveHotKey:self];
		}
	}
	
	[super sendEvent:e];
}

- (void)registerHotKey:(int)keyCode modifierFlags:(int)modFlags
{
	if (!hotkey) {
		hotkey = [HotKeyManager new];
	}
	[hotkey registerHotKeyCode:keyCode withModifier:modFlags];
}

- (void)unregisterHotKey
{
	if (hotkey) {
		[hotkey unregisterHotKey];
	}
}

@end
