class AppConstants {
  AppConstants._();

  static const String appName = 'RCM OS';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Complete Content Agency Operating System';

  // Content Pipeline Stages
  static const List<String> contentStages = [
    'Raw Thought',
    'Idea',
    'Hook',
    'Script',
    'Recording',
    'Editing',
    'Review',
    'Scheduled',
    'Posted',
    'Repurposed',
  ];

  // Content Formats
  static const List<String> contentFormats = [
    'Carousel',
    'Reel (Short Form)',
    'Long Form',
    'Static Post',
  ];

  // CRM Pipeline Stages
  static const List<String> crmStages = [
    'New Lead',
    'Contacted',
    'Discovery Call',
    'Proposal Sent',
    'Negotiation',
    'Won',
    'Lost',
  ];

  // Knowledge Categories
  static const List<String> knowledgeCategories = [
    'Hooks',
    'Content Frameworks',
    'Copywriting Formulas',
    'SOPs',
    'Templates',
    'Research Notes',
    'Business Ideas',
    'Marketing Insights',
    'Swipe Files',
  ];

  // Resource Types
  static const List<String> resourceTypes = [
    'Software',
    'Equipment',
    'Templates',
    'Courses',
    'Assets',
    'Tools',
  ];

  // Expense Categories
  static const List<String> expenseCategories = [
    'Software',
    'Marketing',
    'Equipment',
    'Subscriptions',
    'Office',
    'Travel',
    'Employee Payment',
    'Freelancer Payment',
    'Miscellaneous',
  ];

  // Priority Levels
  static const List<String> priorityLevels = [
    'Critical',
    'High',
    'Medium',
    'Low',
  ];

  // Content Platforms
  static const List<String> contentPlatforms = [
    'YouTube',
    'Instagram',
    'TikTok',
    'LinkedIn',
    'Twitter/X',
    'Facebook',
    'Blog',
    'Podcast',
    'Newsletter',
    'Other',
  ];

  // Pomodoro Durations (in minutes)
  static const Map<String, List<int>> pomodoroModes = {
    'Short': [25, 5],
    'Long': [50, 10],
  };

  // Deep Work Durations (in minutes)
  static const List<int> deepWorkDurations = [60, 90, 120, 180];

  // Lead Sources
  static const List<String> leadSources = [
    'Referral',
    'Social Media',
    'Cold Outreach',
    'Website',
    'Networking',
    'Advertisement',
    'Other',
  ];
}
