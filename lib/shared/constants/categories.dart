const List<String> kCategories = [
  'comida',
  'hogar',
  'mascotas',
  'internet',
  'luz',
  'agua',
  'vestimenta',
  'gusto_extra',
];

String categoryLabel(String c) {
  switch (c) {
    case 'comida':
      return 'Comida';
    case 'hogar':
      return 'Hogar';
    case 'mascotas':
      return 'Mascotas';
    case 'internet':
      return 'Internet';
    case 'luz':
      return 'Luz';
    case 'agua':
      return 'Agua';
    case 'vestimenta':
      return 'Vestimenta';
    case 'gusto_extra':
      return 'Gusto extra';
    default:
      return c;
  }
}