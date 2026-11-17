class AppStrings {
  AppStrings(this.language);
  final String language;

  String call(String key) {
    final en = _english[key] ?? key;
    if (language != 'Tamil') return en;
    return _tamil[key] ?? en;
  }

  static const _english = <String, String>{
    'my_day': 'My Day', 'planner': 'My Planner', 'notes': 'My Notes',
    'progress': 'My Progress', 'today_tasks': "Today's Tasks", 'see_all': 'See all',
    'to_do': 'To-do', 'done': 'Done', 'habits': 'Habits', 'quick_add': 'Quick add',
    'task': 'Task', 'habit': 'Habit', 'event': 'Event', 'note': 'Note',
    'journal': 'Journal', 'water': 'Water', 'exercise': 'Exercise', 'sleep': 'Sleep', 'mood': 'Mood',
    'monthly': 'Month', 'weekly': 'Week', 'daily': 'Day', 'agenda': 'Agenda',
    'search_notes': 'Search notes', 'no_notes': 'Your notes will appear here.',
    'settings': 'Settings', 'save': 'Save', 'cancel': 'Cancel', 'delete': 'Delete',
    'title': 'Title', 'description': 'Description', 'priority': 'Priority',
    'high': 'High', 'medium': 'Medium', 'low': 'Low', 'reminder': 'Reminder',
    'name': 'Your name', 'language': 'Language', 'theme': 'Appearance',
    'light': 'Light', 'dark': 'Dark', 'system': 'System default', 'notifications': 'Notifications',
  };

  static const _tamil = <String, String>{
    'my_day': 'எனது நாள்', 'planner': 'திட்டமிடல்', 'notes': 'குறிப்புகள்',
    'progress': 'முன்னேற்றம்', 'today_tasks': 'இன்றைய பணிகள்', 'see_all': 'அனைத்தும்',
    'to_do': 'செய்ய வேண்டியது', 'done': 'முடிந்தது', 'habits': 'பழக்கங்கள்', 'quick_add': 'விரைவாகச் சேர்',
    'task': 'பணி', 'habit': 'பழக்கம்', 'event': 'நிகழ்வு', 'note': 'குறிப்பு',
    'journal': 'நாள்குறிப்பு', 'water': 'தண்ணீர்', 'exercise': 'உடற்பயிற்சி', 'sleep': 'தூக்கம்', 'mood': 'மனநிலை',
    'monthly': 'மாதம்', 'weekly': 'வாரம்', 'daily': 'நாள்', 'agenda': 'நிகழ்ச்சி நிரல்',
    'search_notes': 'குறிப்புகளைத் தேடு', 'no_notes': 'உங்கள் குறிப்புகள் இங்கே தோன்றும்.',
    'settings': 'அமைப்புகள்', 'save': 'சேமி', 'cancel': 'ரத்து', 'delete': 'நீக்கு',
    'title': 'தலைப்பு', 'description': 'விளக்கம்', 'priority': 'முன்னுரிமை',
    'high': 'உயர்', 'medium': 'நடுத்தரம்', 'low': 'குறைவு', 'reminder': 'நினைவூட்டல்',
    'name': 'உங்கள் பெயர்', 'language': 'மொழி', 'theme': 'தோற்றம்',
    'light': 'ஒளி', 'dark': 'இருள்', 'system': 'கணினி இயல்பு', 'notifications': 'அறிவிப்புகள்',
  };
}
