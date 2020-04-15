#pragma once
class ActionEnums
{
public:
	ActionEnums();
	~ActionEnums();

	enum ActionEnumValues
	{ 
		FIRST_ACTION,
		SHOWDESCRIPTION,
		NEXTDESCRIPTION,
		PREVDESCRIPTION,
		SHOWMENU,
		NEWGROUP,
		NEWGROUPSELECTION,
		TOGGLEFILELOGGING,
		TOGGLEOUTPUTDEBUGSTRING,
		CLOSEWINDOW,
		NEXTTABCONTROL,
		PREVTABCONTROL,
		SHOWGROUPS,
		NEWCLIP,
		EDITCLIP,
		MODIFIER_ACTVE_SELECTIONUP,
		MODIFIER_ACTVE_SELECTIONDOWN,
		MODIFIER_ACTVE_MOVEFIRST,
		MODIFIER_ACTVE_MOVELAST,
		CANCELFILTER,
		HOMELIST,
		BACKGRROUP,
		TOGGLESHOWPERSISTANT,
		PASTE_SELECTED,
		DELETE_SELECTED,
		CLIP_PROPERTIES,
		PASTE_SELECTED_PLAIN_TEXT,
		MOVE_CLIP_TO_GROUP,
		ELEVATE_PRIVlEGES,
		SHOW_IN_TASKBAR,
		COMPARE_SELECTED_CLIPS,
		SELECT_LEFT_SIDE_COMPARE,
		SELECT_RIGHT_SITE_AND_DO_COMPARE,
		EXPORT_TO_TEXT_FILE,
		EXPORT_TO_QR_CODE,
		EXPORT_TO_GOOGLE_TRANSLATE,
		EXPORT_TO_BITMAP_FILE,
		SAVE_CURRENT_CLIPBOARD,
		MOVE_CLIP_UP,
		MOVE_CLIP_DOWN,
		MOVE_CLIP_TOP,
		FILTER_ON_SELECTED_CLIP,
		PASTE_UPPER_CASE,
		PASTE_LOWER_CASE,
		PASTE_CAPITALiZE,
		PASTE_SENTENCE_CASE,
		PASTE_REMOVE_LINE_FEEDS,
		PASTE_ADD_ONE_LINE_FEED,
		PASTE_ADD_TWO_LINE_FEEDS,
		PASTE_TYPOGLYCEMIA,
		SEND_TO_FRIEND_1,
		SEND_TO_FRIEND_2,
		SEND_TO_FRIEND_3,
		SEND_TO_FRIEND_4,
		SEND_TO_FRIEND_5,
		SEND_TO_FRIEND_6,
		SEND_TO_FRIEND_7,
		SEND_TO_FRIEND_8,
		SEND_TO_FRIEND_9,
		SEND_TO_FRIEND_10,
		SEND_TO_FRIEND_11,
		SEND_TO_FRIEND_12,
		SEND_TO_FRIEND_13,
		SEND_TO_FRIEND_14,
		SEND_TO_FRIEND_15,
		PASTE_POSITION_1,
		PASTE_POSITION_2,
		PASTE_POSITION_3,
		PASTE_POSITION_4,
		PASTE_POSITION_5,
		PASTE_POSITION_6,
		PASTE_POSITION_7,
		PASTE_POSITION_8,
		PASTE_POSITION_9,
		PASTE_POSITION_10,
		CONFIG_SHOW_FIRST_TEN_TEXT,
		CONFIG_SHOW_CLIP_WAS_PASTED,
		TOGGLE_LAST_GROUP_TOGGLE,
		MAKE_TOP_STICKY,
		MAKE_LAST_STICKY,
		REMOVE_STICKY,
		PASTE_ADD_CURRENT_TIME,
		IMPORT_CLIP,
		GLOBAl_HOTKEYS,
		DELETE_CLIP_DATA,
		REPLACE_TOP_STICKY_CLIP,
		PROMPT_SEND_TO_FRIEND,
		SAVE_CF_HDROP_FIlE_DATA,
		TOGGLE_CLIPBOARD_CONNECTION,
		MOVE_SELECTION_UP,
		MOVE_SELECTION_DOWN,
		TOGGLE_DESCRIPTION_WORD_WRAP,
		APPLY_LAST_SEARCH,
		TOGGLE_SEARCH_METHOD,
		PASTE_SCRIPT,
		MOVE_CLIP_LAST,
		PASTE_DONT_MOVE_CLIP,
		PASTE_TRIM_WHITE_SPACE,
		TRANSPARENCY_NONE,
		TRANSPARENCY_5,
		TRANSPARENCY_10,
		TRANSPARENCY_15,
		TRANSPARENCY_20,
		TRANSPARENCY_25,
		TRANSPARENCY_30,
		TRANSPARENCY_35,
		TRANSPARENCY_40,
		TRANSPARENCY_TOGGLE,
		TRANSPARENCY_INCREASE,
		TRANSPARENCY_DECREASE,
		EMAILTO_BODY,
		EMAILTO_ATTACH_EXPORT,
		EMAILTO_ATTACH_CONTENT,
		GMAIL,
		SLUGIFY,
		INVERT_CASE,
		COPY_SELECTION,
		FORCE_CLOSE_WINDOW,
		REFRESH_LIST,

		LAST_ACTION
	};

	static CString EnumDescription(ActionEnumValues value);

	static int GetDefaultShortCutKeyA(ActionEnumValues value, int pos);
	static int GetDefaultShortCutKeyB(ActionEnumValues value, int pos);
	static bool UserConfigurable(ActionEnumValues value);
	static bool ToolTipAction(ActionEnumValues value);
};

