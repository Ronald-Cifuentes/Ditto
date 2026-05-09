#include "DittoMac/Pasteboard.hpp"

#import <AppKit/AppKit.h>

#include <stdexcept>

namespace ditto::mac {

std::optional<std::string> read_text_from_pasteboard()
{
	@autoreleasepool {
		NSPasteboard* pasteboard = [NSPasteboard generalPasteboard];
		NSString* value = [pasteboard stringForType:NSPasteboardTypeString];
		if (value == nil) {
			return std::nullopt;
		}

		NSData* data = [value dataUsingEncoding:NSUTF8StringEncoding];
		if (data == nil) {
			return std::string();
		}
		return std::string(static_cast<const char*>([data bytes]), [data length]);
	}
}

void write_text_to_pasteboard(const std::string& text)
{
	@autoreleasepool {
		NSString* value = [[NSString alloc] initWithBytes:text.data()
		                                           length:text.size()
		                                         encoding:NSUTF8StringEncoding];
		if (value == nil) {
			throw std::runtime_error("pasteboard text must be valid UTF-8");
		}

		NSPasteboard* pasteboard = [NSPasteboard generalPasteboard];
		[pasteboard clearContents];
		if (![pasteboard setString:value forType:NSPasteboardTypeString]) {
			throw std::runtime_error("failed to write text to pasteboard");
		}
	}
}

long pasteboard_change_count()
{
	@autoreleasepool {
		return [[NSPasteboard generalPasteboard] changeCount];
	}
}

} // namespace ditto::mac
