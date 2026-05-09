#pragma once

#include <cstddef>
#include <optional>
#include <string>
#include <vector>

struct sqlite3;

namespace ditto::mac {

struct Clip {
	long long id = 0;
	std::string created_at;
	std::string content;
};

class HistoryStore {
public:
	explicit HistoryStore(std::string db_path);
	~HistoryStore();

	HistoryStore(const HistoryStore&) = delete;
	HistoryStore& operator=(const HistoryStore&) = delete;

	HistoryStore(HistoryStore&&) = delete;
	HistoryStore& operator=(HistoryStore&&) = delete;

	const std::string& path() const;
	bool add_clip(const std::string& content, long long* inserted_id = nullptr);
	std::vector<Clip> list(int limit) const;
	std::optional<Clip> get_by_id(long long id) const;
	std::optional<Clip> latest() const;
	int count() const;
	void clear();

private:
	void open();
	void initialize_schema();
	void exec(const char* sql) const;

	std::string db_path_;
	::sqlite3* db_ = nullptr;
};

std::string configured_database_path();
std::string default_database_path();
std::string preview_text(const std::string& text, std::size_t max_bytes);

} // namespace ditto::mac
