// Opcje sortowania
enum SortOption {
  lastName('Nazwisko'),
  firstName('Imię'),
  courseDuration('Czas trwania');

  final String label;
  const SortOption(this.label);
}

// Kolumny do wyświetlenia
enum DisplayColumn {
  phone('Telefon'),
  email('Email'),
  pkk('PKK'),
  theoryPassed('Teoria zdana'),
  coursePaid('Kurs opłacony'),
  hoursDriven('Wyjeżdżone godziny'),
  instructor('Instruktor'),
  courseDuration('Czas trwania'),
  activeOnly('Tylko aktywni');

  final String label;
  const DisplayColumn(this.label);
}