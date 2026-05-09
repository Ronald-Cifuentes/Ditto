#include "DittoMac/HistoryStore.hpp"

#include <filesystem>
#include <cstdlib>
#include <iomanip>
#include <limits>
#include <sstream>
#include <stdexcept>

#include <sqlite3.h>

namespace ditto::mac {
namespace {

std::runtime_error sqlite_error(sqlite3* db, const std::string& action)
{
	const char* message = db == nullptr ? "no database handle" : sqlite3_errmsg(db);
	return std::runtime_error(action + ": " + (message == nullptr ? "unknown sqlite error" : message));
}

std::string hash_text(const std::string& text)
{
	unsigned long long hash = 14695981039346656037ull;
	for (unsigned char ch : text) {
		hash ^= ch;
		hash *= 1099511628211ull;
	}

	std::ostringstream out;
	out << std::hex << std::setw(16) << std::setfill('0') << hash;
	return out.str();
}

class Statement {
public:
	Statement(sqlite3* db, const char* sql)
		: db_(db)
	{
		if (sqlite3_prepare_v2(db_, sql, -1, &stmt_, nullptr) != SQLITE_OK) {
			throw sqlite_error(db_, "prepare statement");
		}
	}

	~Statement()
	{
		sqlite3_finalize(stmt_);
	}

	Statement(const Statement&) = delete;
	Statement& operator=(const Statement&) = delete;

	sqlite3_stmt* get() const
	{
		return stmt_;
	}

private:
	sqlite3* db_ = nullptr;
	sqlite3_stmt* stmt_ = nullptr;
};

std::string column_text(sqlite3_stmt* stmt, int column)
{
	const unsigned char* value = sqlite3_column_text(stmt, column);
	const int bytes = sqlite3_column_bytes(stmt, column);
	return value == nullptr ? std::string() : std::string(reinterpret_cast<const char*>(value), bytes);
}

void bind_text(sqlite3* db, sqlite3_stmt* stmt, int index, const std::string& text)
{
	if (text.size() > static_cast<std::size_t>(std::numeric_limits<int>::max())) {
		throw std::runtime_error("text is too large for sqlite binding");
	}
	if (sqlite3_bind_text(stmt, index, text.data(), static_cast<int>(text.size()), SQLITE_TRANSIENT) != SQLITE_OK) {
		throw sqlite_error(db, "bind text");
	}
}

} // namespace

HistoryStore::HistoryStore(std::string db_path)
	: db_path_(std::move(db_path))
{
	open();
	initialize_schema();
}

HistoryStore::~HistoryStore()
{
	if (db_ != nullptr) {
		sqlite3_close(db_);
	}
}

const std::string& HistoryStore::path() const
{
	return db_path_;
}

void HistoryStore::open()
{
	std::filesystem::path path(db_path_);
	if (path.has_parent_path()) {
		std::filesystem::create_directories(path.parent_path());
	}

	const int flags = SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_FULLMUTEX;
	if (sqlite3_open_v2(db_path_.c_str(), &db_, flags, nullptr) != SQLITE_OK) {
		sqlite3* db = db_;
		const std::runtime_error error = sqlite_error(db, "open database");
		if (db != nullptr) {
			sqlite3_close(db);
		}
		db_ = nullptr;
		throw error;
	}
}

void HistoryStore::initialize_schema()
{
	exec("PRAGMA journal_mode=WAL");
	exec("CREATE TABLE IF NOT EXISTS clips ("
		 "id INTEGER PRIMARY KEY AUTOINCREMENT,"
		 "created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),"
		 "content TEXT NOT NULL,"
		 "content_hash TEXT NOT NULL"
		 ")");
	exec("CREATE INDEX IF NOT EXISTS idx_clips_created ON clips(id DESC)");
}

void HistoryStore::exec(const char* sql) const
{
	char* error = nullptr;
	if (sqlite3_exec(db_, sql, nullptr, nullptr, &error) != SQLITE_OK) {
		std::string message = error == nullptr ? "unknown sqlite error" : error;
		sqlite3_free(error);
		throw std::runtime_error("execute sql: " + message);
	}
}

bool HistoryStore::add_clip(const std::string& content, long long* inserted_id)
{
	if (inserted_id != nullptr) {
		*inserted_id = 0;
	}
	if (content.empty()) {
		return false;
	}

	const std::string hash = hash_text(content);
	{
		Statement latest_stmt(db_, "SELECT content_hash, content FROM clips ORDER BY id DESC LIMIT 1");
		const int step = sqlite3_step(latest_stmt.get());
		if (step == SQLITE_ROW) {
			const bool same_hash = column_text(latest_stmt.get(), 0) == hash;
			const bool same_content = column_text(latest_stmt.get(), 1) == content;
			if (same_hash && same_content) {
				return false;
			}
		} else if (step != SQLITE_DONE) {
			throw sqlite_error(db_, "read latest clip");
		}
	}

	Statement insert_stmt(db_, "INSERT INTO clips(content, content_hash) VALUES (?, ?)");
	bind_text(db_, insert_stmt.get(), 1, content);
	bind_text(db_, insert_stmt.get(), 2, hash);
	if (sqlite3_step(insert_stmt.get()) != SQLITE_DONE) {
		throw sqlite_error(db_, "insert clip");
	}

	if (inserted_id != nullptr) {
		*inserted_id = sqlite3_last_insert_rowid(db_);
	}
	return true;
}

std::vector<Clip> HistoryStore::list(int limit) const
{
	Statement stmt(db_, "SELECT id, created_at, content FROM clips ORDER BY id DESC LIMIT ?");
	if (sqlite3_bind_int(stmt.get(), 1, limit) != SQLITE_OK) {
		throw sqlite_error(db_, "bind limit");
	}

	std::vector<Clip> clips;
	for (;;) {
		const int step = sqlite3_step(stmt.get());
		if (step == SQLITE_DONE) {
			break;
		}
		if (step != SQLITE_ROW) {
			throw sqlite_error(db_, "list clips");
		}

		Clip clip;
		clip.id = sqlite3_column_int64(stmt.get(), 0);
		clip.created_at = column_text(stmt.get(), 1);
		clip.content = column_text(stmt.get(), 2);
		clips.push_back(std::move(clip));
	}
	return clips;
}

std::optional<Clip> HistoryStore::get_by_id(long long id) const
{
	Statement stmt(db_, "SELECT id, created_at, content FROM clips WHERE id = ?");
	if (sqlite3_bind_int64(stmt.get(), 1, id) != SQLITE_OK) {
		throw sqlite_error(db_, "bind id");
	}

	const int step = sqlite3_step(stmt.get());
	if (step == SQLITE_DONE) {
		return std::nullopt;
	}
	if (step != SQLITE_ROW) {
		throw sqlite_error(db_, "read clip");
	}

	Clip clip;
	clip.id = sqlite3_column_int64(stmt.get(), 0);
	clip.created_at = column_text(stmt.get(), 1);
	clip.content = column_text(stmt.get(), 2);
	return clip;
}

std::optional<Clip> HistoryStore::latest() const
{
	Statement stmt(db_, "SELECT id, created_at, content FROM clips ORDER BY id DESC LIMIT 1");
	const int step = sqlite3_step(stmt.get());
	if (step == SQLITE_DONE) {
		return std::nullopt;
	}
	if (step != SQLITE_ROW) {
		throw sqlite_error(db_, "read latest clip");
	}

	Clip clip;
	clip.id = sqlite3_column_int64(stmt.get(), 0);
	clip.created_at = column_text(stmt.get(), 1);
	clip.content = column_text(stmt.get(), 2);
	return clip;
}

int HistoryStore::count() const
{
	Statement stmt(db_, "SELECT COUNT(*) FROM clips");
	if (sqlite3_step(stmt.get()) != SQLITE_ROW) {
		throw sqlite_error(db_, "count clips");
	}
	return sqlite3_column_int(stmt.get(), 0);
}

void HistoryStore::clear()
{
	exec("DELETE FROM clips");
}

std::string default_database_path()
{
	const char* home = std::getenv("HOME");
	if (home == nullptr || *home == '\0') {
		throw std::runtime_error("HOME is not set; set DITTO_MAC_DB to choose a database path");
	}

	std::filesystem::path path(home);
	path /= "Library";
	path /= "Application Support";
	path /= "DittoMac";
	path /= "history.sqlite";
	return path.string();
}

std::string configured_database_path()
{
	const char* configured = std::getenv("DITTO_MAC_DB");
	if (configured != nullptr && *configured != '\0') {
		return configured;
	}
	return default_database_path();
}

std::string preview_text(const std::string& text, std::size_t max_bytes)
{
	std::string sanitized;
	sanitized.reserve(text.size());
	for (char ch : text) {
		switch (ch) {
		case '\n':
			sanitized += "\\n";
			break;
		case '\r':
			sanitized += "\\r";
			break;
		case '\t':
			sanitized += "\\t";
			break;
		case '\0':
			sanitized += "\\0";
			break;
		default:
			sanitized += ch;
			break;
		}
	}

	if (sanitized.size() <= max_bytes) {
		return sanitized;
	}
	if (max_bytes <= 3) {
		return sanitized.substr(0, max_bytes);
	}
	return sanitized.substr(0, max_bytes - 3) + "...";
}

} // namespace ditto::mac
