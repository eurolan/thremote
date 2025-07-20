String getDisplayName(String name) {
  const keyword = 'TH300';
  final index = name.indexOf(keyword);
  if (index != -1) {
    return name.substring(0, index + keyword.length).trim();
  }
  return name; // If TH300 not found, show full name
}
