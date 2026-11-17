import 'package:flutter/widgets.dart';

class AppStrings {
  AppStrings(this.language);
  final String language;

  String call(String key) {
    final en = _english[key] ?? key;
    if (language != 'Tamil') return en;
    return _tamil[key] ?? translate(en, language);
  }

  static String translate(String value, String language) =>
      language == 'Tamil' ? (_uiTamil[value] ?? value) : value;

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
    'light': 'ஒளி', 'dark': 'இருள்', 'system': 'சாதன அமைப்பு', 'notifications': 'அறிவிப்புகள்',
  };

  static const _uiTamil = <String, String>{
    'My Day': 'எனது நாள்', 'My Planner': 'எனது திட்டமிடல்', 'My Notes': 'எனது குறிப்புகள்',
    'My Progress': 'எனது முன்னேற்றம்', 'Settings': 'அமைப்புகள்', 'Today': 'இன்று',
    'Month': 'மாதம்', 'Week': 'வாரம்', 'Day': 'நாள்', 'Agenda': 'நிகழ்ச்சி நிரல்',
    'Add Task': 'பணியைச் சேர்', 'Add habit': 'பழக்கத்தைச் சேர்', 'Task': 'பணி',
    'Habit': 'பழக்கம்', 'Event': 'நிகழ்வு', 'Note': 'குறிப்பு', 'Journal': 'நாள்குறிப்பு',
    'Water': 'தண்ணீர்', 'Exercise': 'உடற்பயிற்சி', 'Sleep': 'தூக்கம்', 'Mood': 'மனநிலை',
    'To-do': 'செய்ய வேண்டியது', 'Progress': 'முன்னேற்றம்', 'Done': 'முடிந்தது',
    'Today’s Tasks': 'இன்றைய பணிகள்', 'Today’s tasks': 'இன்றைய பணிகள்',
    'Your Habits': 'உங்கள் பழக்கங்கள்', 'Today at a glance': 'இன்றைய சுருக்கம்',
    'Reorder': 'வரிசையை மாற்று', 'Search a task...': 'பணியைத் தேடு...',
    'A clear day ahead': 'இன்று நல்ல தொடக்கம்', 'No matching tasks': 'பொருந்தும் பணிகள் இல்லை',
    'Add a task when something needs your attention.': 'செய்ய வேண்டியதை இங்கே சேர்க்கவும்.',
    'Try another search phrase.': 'வேறு சொல்லைத் தேடவும்.',
    'Build a small routine': 'சிறிய பழக்கத்தை உருவாக்குங்கள்',
    'Track a habit and grow your streak one day at a time.': 'தினமும் பழக்கத்தைப் பின்பற்றி தொடர்ச்சியை வளர்த்திடுங்கள்.',
    'Paused': 'இடைநிறுத்தப்பட்டது', 'Resume habit': 'பழக்கத்தைத் தொடரவும்',
    'Pause habit': 'பழக்கத்தை இடைநிறுத்து', 'Habit options': 'பழக்க விருப்பங்கள்',
    'day streak': 'நாள் தொடர்ச்சி', 'missed': 'தவறியது', 'A LITTLE WISDOM': 'ஒரு சிறிய ஞானம்',
    'Stored on this device': 'இந்த சாதனத்தில் சேமிக்கப்பட்டது',
    'Your notes will appear here.': 'உங்கள் குறிப்புகள் இங்கே தோன்றும்.',
    'No notes match your search.': 'உங்கள் தேடலுக்கு குறிப்புகள் இல்லை.',
    'Capture ideas, reminders and things worth remembering.': 'யோசனைகள் மற்றும் நினைவூட்டல்களைச் சேமிக்கவும்.',
    'Create your first note': 'முதல் குறிப்பை உருவாக்கு', 'Delete note?': 'குறிப்பை நீக்கவா?',
    'This note will be removed from this device.': 'இந்த குறிப்பு சாதனத்திலிருந்து நீக்கப்படும்.',
    'Edit': 'திருத்து', 'Delete': 'நீக்கு', 'Cancel': 'ரத்து', 'Save': 'சேமி',
    'Nothing planned yet': 'இன்னும் எதுவும் திட்டமிடப்படவில்லை',
    'Add a task, event or date note.': 'பணி, நிகழ்வு அல்லது தேதி குறிப்பைச் சேர்க்கவும்.',
    'Add a note to this date': 'இந்த தேதிக்கு குறிப்பைச் சேர்',
    'Productivity history': 'செயல்திறன் வரலாறு', 'Habit consistency': 'பழக்கத் தொடர்ச்சி',
    'Activity heatmap': 'செயல்பாட்டு வரைபடம்', 'Personal tracking': 'தனிப்பட்ட கண்காணிப்பு',
    'Sleep & mood trends': 'தூக்கம் மற்றும் மனநிலை போக்கு',
    'Sleep & mood history': 'தூக்கம் மற்றும் மனநிலை வரலாறு',
    'Sleep duration': 'தூக்க நேரம்', 'Mood score': 'மனநிலை மதிப்பெண்',
    'Sleep logs': 'தூக்க பதிவுகள்', 'Mood check-ins': 'மனநிலை பதிவுகள்',
    'Journal entries': 'நாள்குறிப்பு பதிவுகள்', 'No sleep entries yet.': 'தூக்க பதிவுகள் இல்லை.',
    'No mood entries yet.': 'மனநிலை பதிவுகள் இல்லை.', 'Journal entry': 'நாள்குறிப்பு பதிவு',
    'Tasks completed': 'முடிக்கப்பட்ட பணிகள்', 'Completed': 'முடிந்தது', 'Pending': 'நிலுவை',
    'Best streak': 'சிறந்த தொடர்ச்சி', 'Water logged': 'பதிவு செய்த தண்ணீர்',
    'Statistics are calculated from entries saved on this device. Empty periods remain zero.': 'இந்த சாதனத்தில் சேமித்த பதிவுகளிலிருந்து புள்ளிவிவரங்கள் கணக்கிடப்படுகின்றன.',
    'Your profile': 'உங்கள் சுயவிவரம்', 'Appearance': 'தோற்றம்', 'Theme': 'தீம்',
    'Language': 'மொழி', 'Reminders': 'நினைவூட்டல்கள்', 'Privacy & security': 'தனியுரிமை மற்றும் பாதுகாப்பு',
    'Data & backup': 'தரவு மற்றும் காப்புப்பிரதி', 'About': 'பற்றி',
    'Your name': 'உங்கள் பெயர்', 'Add your name for a personal greeting': 'தனிப்பட்ட வாழ்த்துக்கு உங்கள் பெயரைச் சேர்க்கவும்',
    'Light': 'ஒளி', 'Dark': 'இருள்', 'System': 'சாதன அமைப்பு',
    'Notifications': 'அறிவிப்புகள்', 'Allow local reminders for tasks, habits and events': 'பணிகள், பழக்கங்கள் மற்றும் நிகழ்வுகளுக்கான நினைவூட்டல்களை அனுமதி',
    'Test notification access': 'அறிவிப்பு அனுமதியைச் சோதிக்கவும்',
    'Open Android permission prompts': 'Android அனுமதி சாளரத்தைத் திறக்கவும்',
    'Change app PIN': 'செயலி PIN-ஐ மாற்று', 'Set app PIN': 'செயலி PIN அமை',
    'PIN lock is enabled': 'PIN பூட்டு இயக்கத்தில் உள்ளது', 'Add an optional PIN lock': 'விருப்ப PIN பூட்டைச் சேர்க்கவும்',
    'Biometric unlock': 'கைரேகை / முகம் மூலம் திறத்தல்',
    'Use fingerprint or face unlock when supported': 'ஆதரவு இருந்தால் கைரேகை அல்லது முகத்தைப் பயன்படுத்தவும்',
    'Remove app PIN': 'செயலி PIN-ஐ நீக்கு', 'Export backup': 'காப்புப்பிரதியை ஏற்றுமதி செய்',
    'Restore backup': 'காப்புப்பிரதியை மீட்டமை', 'Create a portable JSON copy of your records': 'உங்கள் பதிவுகளின் காப்பு நகலை உருவாக்கவும்',
    'Import a DayPilot JSON backup': 'DayPilot காப்புப்பிரதியை இறக்குமதி செய்',
    'Your personal data stays on this device unless you explicitly export a backup.': 'நீங்கள் ஏற்றுமதி செய்யாவிட்டால் உங்கள் தனிப்பட்ட தரவு இந்த சாதனத்திலேயே இருக்கும்.',
    'Search notes': 'குறிப்புகளைத் தேடு', 'No additional text': 'கூடுதல் உரை இல்லை',
    'New task': 'புதிய பணி', 'New habit': 'புதிய பழக்கம்', 'New event': 'புதிய நிகழ்வு',
    'Title': 'தலைப்பு', 'Description': 'விளக்கம்', 'Description (optional)': 'விளக்கம் (விருப்பம்)',
    'Priority': 'முன்னுரிமை', 'High': 'உயர்', 'Medium': 'நடுத்தரம்', 'Low': 'குறைவு',
    'Scheduled date': 'திட்டமிட்ட தேதி', 'Scheduled time': 'திட்டமிட்ட நேரம்',
    'Frequency': 'அடிக்கடி', 'Daily': 'தினமும்', 'Weekly': 'வாரந்தோறும்', 'Custom': 'தனிப்பயன்',
    'Habit icon': 'பழக்கக் குறியீடு', 'Habit colour': 'பழக்க நிறம்', 'Active days': 'செயலில் உள்ள நாட்கள்',
    'Weekly goal (days)': 'வார இலக்கு (நாட்கள்)', 'Habit reminder time': 'பழக்க நினைவூட்டல் நேரம்',
    'Category': 'வகை', 'Personal': 'தனிப்பட்டது', 'Work': 'வேலை', 'Health': 'ஆரோக்கியம்',
    'Family': 'குடும்பம்', 'Other': 'மற்றவை', 'Event date': 'நிகழ்வு தேதி',
    'Starts': 'தொடக்கம்', 'Ends': 'முடிவு', 'Repeat': 'மீண்டும்',
    'Does not repeat': 'மீண்டும் இல்லை', 'Monthly': 'மாதந்தோறும்',
    'Bedtime date': 'தூங்கிய தேதி', 'Bedtime': 'தூங்கிய நேரம்', 'Wake-up time': 'எழுந்த நேரம்',
    'How are you feeling today?': 'இன்று உங்கள் மனநிலை எப்படி உள்ளது?',
    'Amazing': 'மிக அருமை', 'Good': 'நன்று', 'Okay': 'பரவாயில்லை', 'Low mood': 'சோர்வு', 'Stressed': 'மன அழுத்தம்',
    'Water intake': 'தண்ணீர் அளவு', 'Amount (ml)': 'அளவு (மி.லி.)', 'Daily target (ml)': 'தினசரி இலக்கு (மி.லி.)',
    'Duration (minutes)': 'நேரம் (நிமிடங்கள்)', 'Set a reminder': 'நினைவூட்டலை அமை',
    'Reminder time': 'நினைவூட்டல் நேரம்', 'Save changes': 'மாற்றங்களைச் சேமி',
    'Please enter a title': 'தலைப்பை உள்ளிடவும்', 'Set time': 'நேரத்தை அமை',
    'Description / notes': 'விளக்கம் / குறிப்புகள்',
    'Save task': 'பணியைச் சேமி', 'Save habit': 'பழக்கத்தைச் சேமி',
    'Save event': 'நிகழ்வைச் சேமி', 'Save note': 'குறிப்பைச் சேமி',
    'Save date note': 'தேதி குறிப்பைச் சேமி', 'Save journal': 'நாள்குறிப்பைச் சேமி',
    'Save water entry': 'தண்ணீர் பதிவைச் சேமி', 'Save exercise': 'உடற்பயிற்சியைச் சேமி',
    'Save sleep log': 'தூக்க பதிவைச் சேமி', 'Save mood entry': 'மனநிலை பதிவைச் சேமி',
    'Today': 'இன்று', 'Mon': 'திங்', 'Tue': 'செவ்', 'Wed': 'புத', 'Thu': 'வியா', 'Fri': 'வெள்', 'Sat': 'சனி', 'Sun': 'ஞாயி',
    'W1': 'வா1', 'W2': 'வா2', 'W3': 'வா3', 'W4': 'வா4', 'W5': 'வா5',
    'Jan': 'ஜன', 'Feb': 'பிப்', 'Mar': 'மார்', 'Apr': 'ஏப்', 'May': 'மே', 'Jun': 'ஜூன்', 'Jul': 'ஜூலை', 'Aug': 'ஆக', 'Sep': 'செப்', 'Oct': 'அக்', 'Nov': 'நவ', 'Dec': 'டிச',
    'Save encrypted DayPilot backup': 'குறியாக்கப்பட்ட DayPilot காப்புப்பிரதியைச் சேமி',
    'Backup save cancelled.': 'காப்புப்பிரதி சேமிப்பு ரத்து செய்யப்பட்டது.',
    'Encrypted backup saved. Keep your password safe.': 'குறியாக்கப்பட்ட காப்புப்பிரதி சேமிக்கப்பட்டது. கடவுச்சொல்லை பாதுகாப்பாக வைத்திருங்கள்.',
    'Could not create backup': 'காப்புப்பிரதியை உருவாக்க முடியவில்லை',
    'Choose backup JSON file': 'காப்புப்பிரதி JSON கோப்பைத் தேர்ந்தெடுக்கவும்',
    'Selected file': 'தேர்ந்தெடுத்த கோப்பு',
    'Or paste backup JSON here': 'அல்லது காப்புப்பிரதி JSON-ஐ இங்கே ஒட்டவும்',
    'Could not read backup file': 'காப்புப்பிரதி கோப்பைப் படிக்க முடியவில்லை',
    'Choose a backup file or paste backup JSON.': 'காப்புப்பிரதி கோப்பைத் தேர்ந்தெடுக்கவும் அல்லது JSON-ஐ ஒட்டவும்',

  };
}

extension DayPilotText on BuildContext {
  String dp(String english) {
    final language = Localizations.localeOf(this).languageCode == 'ta' ? 'Tamil' : 'English';
    return AppStrings.translate(english, language);
  }
}
