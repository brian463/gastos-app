const List<String> kCategories = [
  'comida',
  'hogar',
  'mascotas',
  'internet',
  'luz',
  'agua',
  'vestimenta',
  'combustible',
  'mercado',
  'gasto_extra',
];

String categoryLabel(String key) {
  switch (key) {
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
    case 'combustible':
      return 'Combustible';
    case 'mercado':
      return 'Mercado';
    case 'gasto_extra':
      return 'Gasto extra';
    default:
      return key;
  }
}