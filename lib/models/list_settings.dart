// Opcje sortowania
enum SortOption {
  lastNameAsc('Nazwisko ↑'),
  lastNameDesc('Nazwisko ↓'),
  firstNameAsc('Imię ↑'),
  firstNameDesc('Imię ↓'),
  courseStartAsc('Data rozpoczęcia ↑'),
  courseStartDesc('Data rozpoczęcia ↓');

  final String label;
  const SortOption(this.label);
}

// Kolumny do wyświetlenia
enum DisplayColumn {
  phone('Telefon'),
  email('Email'),
  pkk('PKK'),
  hoursDriven('Wyjeżdżone godziny'),
  instructor('Instruktor'),
  courseDuration('Czas trwania');

  final String label;
  const DisplayColumn(this.label);
}

enum FilterOption {
  theoryPassed('Teoria zdana'),
  coursePaid('Kurs opłacony'),
  courseUnpaid('Kurs nieopłacony'),
  showInactive('Pokaż nieaktywnych');

  final String label;
  const FilterOption(this.label);
}
