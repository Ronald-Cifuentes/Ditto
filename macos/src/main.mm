#include "DittoMac/HistoryStore.hpp"
#include "DittoMac/Pasteboard.hpp"

#import <Foundation/Foundation.h>

#include <chrono>
#include <cstdlib>
#include <iostream>
#include <limits>
#include <optional>
#include <sstream>
#include <stdexcept>
#include <string>
#include <thread>

namespace {

constexpr const char* kVersion = "0.1.0";

void print_usage(std::ostream& out)
{
	out << "ditto-mac " << kVersion << "\n"
	    << "Usage:\n"
	    << "  ditto-mac capture\n"
	    << "  ditto-mac listen [--interval-ms N] [--once]\n"
	    << "  ditto-mac list [--limit N]\n"
	    << "  ditto-mac show <id|latest>\n"
	    << "  ditto-mac copy <id|latest>\n"
	    << "  ditto-mac copy-stdin\n"
	    << "  ditto-mac paste\n"
	    << "  ditto-mac count\n"
	    << "  ditto-mac clear\n"
	    << "  ditto-mac db-path\n";
}

int parse_positive_int(const std::string& value, const std::string& name, int max_value)
{
	std::size_t consumed = 0;
	long parsed = 0;
	try {
		parsed = std::stol(value, &consumed, 10);
	} catch (const std::exception&) {
		throw std::runtime_error(name + " must be a positive integer");
	}

	if (consumed != value.size() || parsed <= 0 || parsed > max_value) {
		throw std::runtime_error(name + " must be between 1 and " + std::to_string(max_value));
	}
	return static_cast<int>(parsed);
}

long long parse_id(const std::string& value)
{
	std::size_t consumed = 0;
	long long parsed = 0;
	try {
		parsed = std::stoll(value, &consumed, 10);
	} catch (const std::exception&) {
		throw std::runtime_error("clip id must be a positive integer or 'latest'");
	}

	if (consumed != value.size() || parsed <= 0) {
		throw std::runtime_error("clip id must be a positive integer or 'latest'");
	}
	return parsed;
}

std::string read_stdin()
{
	std::ostringstream buffer;
	buffer << std::cin.rdbuf();
	return buffer.str();
}

std::optional<ditto::mac::Clip> resolve_clip(ditto::mac::HistoryStore& store, const std::string& selector)
{
	if (selector == "latest") {
		return store.latest();
	}
	return store.get_by_id(parse_id(selector));
}

bool capture_once(ditto::mac::HistoryStore& store)
{
	std::optional<std::string> value = ditto::mac::read_text_from_pasteboard();
	if (!value.has_value() || value->empty()) {
		std::cout << "no text captured\n";
		return false;
	}

	long long id = 0;
	const bool inserted = store.add_clip(*value, &id);
	if (inserted) {
		std::cout << "captured\t" << id << "\n";
	} else {
		std::cout << "unchanged\n";
	}
	return inserted;
}

int run(int argc, char* argv[])
{
	if (argc < 2) {
		print_usage(std::cerr);
		return 2;
	}

	const std::string command = argv[1];
	if (command == "help" || command == "--help" || command == "-h") {
		print_usage(std::cout);
		return 0;
	}
	if (command == "version" || command == "--version") {
		std::cout << kVersion << "\n";
		return 0;
	}
	if (command == "db-path") {
		std::cout << ditto::mac::configured_database_path() << "\n";
		return 0;
	}
	if (command == "paste") {
		std::optional<std::string> value = ditto::mac::read_text_from_pasteboard();
		if (!value.has_value()) {
			return 1;
		}
		std::cout << *value;
		return 0;
	}
	if (command == "copy-stdin") {
		ditto::mac::write_text_to_pasteboard(read_stdin());
		return 0;
	}

	ditto::mac::HistoryStore store(ditto::mac::configured_database_path());

	if (command == "capture") {
		capture_once(store);
		return 0;
	}
	if (command == "listen") {
		int interval_ms = 500;
		bool once = false;
		for (int i = 2; i < argc; ++i) {
			const std::string arg = argv[i];
			if (arg == "--once") {
				once = true;
			} else if (arg == "--interval-ms") {
				if (i + 1 >= argc) {
					throw std::runtime_error("--interval-ms requires a value");
				}
				interval_ms = parse_positive_int(argv[++i], "--interval-ms", 60000);
			} else {
				throw std::runtime_error("unknown listen argument: " + arg);
			}
		}

		if (once) {
			capture_once(store);
			return 0;
		}

		long last_change_count = ditto::mac::pasteboard_change_count();
		capture_once(store);
		for (;;) {
			std::this_thread::sleep_for(std::chrono::milliseconds(interval_ms));
			const long current_change_count = ditto::mac::pasteboard_change_count();
			if (current_change_count != last_change_count) {
				last_change_count = current_change_count;
				capture_once(store);
			}
		}
	}
	if (command == "list") {
		int limit = 20;
		for (int i = 2; i < argc; ++i) {
			const std::string arg = argv[i];
			if (arg == "--limit") {
				if (i + 1 >= argc) {
					throw std::runtime_error("--limit requires a value");
				}
				limit = parse_positive_int(argv[++i], "--limit", 1000);
			} else {
				throw std::runtime_error("unknown list argument: " + arg);
			}
		}

		for (const ditto::mac::Clip& clip : store.list(limit)) {
			std::cout << clip.id << "\t" << clip.created_at << "\t"
			          << ditto::mac::preview_text(clip.content, 80) << "\n";
		}
		return 0;
	}
	if (command == "show" || command == "copy") {
		if (argc != 3) {
			throw std::runtime_error(command + " requires <id|latest>");
		}
		std::optional<ditto::mac::Clip> clip = resolve_clip(store, argv[2]);
		if (!clip.has_value()) {
			throw std::runtime_error("clip not found: " + std::string(argv[2]));
		}

		if (command == "show") {
			std::cout << clip->content;
		} else {
			ditto::mac::write_text_to_pasteboard(clip->content);
			std::cout << "copied\t" << clip->id << "\n";
		}
		return 0;
	}
	if (command == "count") {
		std::cout << store.count() << "\n";
		return 0;
	}
	if (command == "clear") {
		store.clear();
		std::cout << "cleared\n";
		return 0;
	}

	throw std::runtime_error("unknown command: " + command);
}

} // namespace

int main(int argc, char* argv[])
{
	@autoreleasepool {
		try {
			return run(argc, argv);
		} catch (const std::exception& error) {
			std::cerr << "ditto-mac: " << error.what() << "\n";
			return 1;
		}
	}
}
