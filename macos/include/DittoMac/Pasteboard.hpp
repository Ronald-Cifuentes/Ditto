#pragma once

#include <optional>
#include <string>

namespace ditto::mac {

std::optional<std::string> read_text_from_pasteboard();
void write_text_to_pasteboard(const std::string& text);
long pasteboard_change_count();

} // namespace ditto::mac
