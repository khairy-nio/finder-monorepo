/// Comprehensive location dataset: Country → State/Province → City → Area
class LocationDataService {
  static const String travelingState = 'Traveling / On the Move';
  static final List<String> travelingMethods = [
    'Plane',
    'Train',
    'Bus',
    'Car',
    'Ship / Boat',
    'Other'
  ];

  /// Structure: Map<Country, Map<State, Map<City, List<Area>>>>
  static final Map<String, Map<String, Map<String, List<String>>>> _database = {
    // ── Egypt (Comprehensive 27 Governorates) ───────────────────────────────
    'Egypt': {
      'Cairo': {
        'Cairo City': ['Downtown', 'Zamalek', 'Garden City', 'Shubra', 'Ain Shams', 'Abbaseya', 'Mokattam', 'Helwan', 'El Marg', 'Sayeda Zeinab', 'Dar El Salam'],
        'Nasr City': ['First Zone', 'Seventh Zone', 'Eighth Zone', 'Tayeer', 'Zahraa Nasr City'],
        'Maadi': ['Old Maadi', 'Maadi Digla', 'New Maadi', 'Zahraa Maadi', 'Sakanat El Maadi'],
        'Heliopolis': ['Korba', 'Roxy', 'Gesr El Suez', 'Sheraton', 'Merryland'],
        'New Cairo': ['First Settlement', 'Third Settlement', 'Fifth Settlement', 'El Rehab', 'Madinaty', 'Tagamoa'],
        'New Administrative Capital': ['R3', 'R7', 'Business District', 'Government District'],
      },
      'Alexandria': {
        'Alexandria City': ['Smouha', 'Miami', 'Sidi Bishr', 'Stanley', 'Glim', 'Roushdy', 'Mandara', 'Sidi Gaber', 'Camp Shizar', 'Cleopatra'],
        'Borg El Arab': ['Industrial Zone', 'Residential Zone', 'New Borg El Arab'],
        'Agami': ['Bitash', 'Hanoville', 'Abu Youssef'],
        'Montaza': ['Maamoura', 'Asafra', 'Tosson'],
        'Amreya': ['Amreya First', 'Amreya Second'],
      },
      'Giza': {
        'Giza City': ['Dokki', 'Agouza', 'Mohandessin', 'Haram', 'Faisal', 'Imbaba', 'Bulaq El Dakrour', 'Omrania'],
        '6th of October': ['First District', 'Second District', 'Hadayek October', 'Sheikh Zayed', 'Industrial Zone'],
        'Hawamdiya': ['Hawamdiya City'],
        'Badrashein': ['Badrashein City', 'Mit Rahina'],
      },
      'Qalyubia': {
        'Banha': ['Kafr El Gazar', 'Banha El Gedida', 'Atrib'],
        'Shubra El Kheima': ['Shubra West', 'Shubra East', 'Bahtim'],
        'Obour': ['First District', 'Second District', 'Industrial Zone'],
        'Qalyub': ['Qalyub City'],
        'Khanka': ['Khanka City', 'Abu Zaabal'],
      },
      'Monufia': {
        'Shibin El Kom': ['East District', 'West District'],
        'Sadat City': ['First Zone', 'Second Zone', 'Industrial Zone'],
        'Ashmoun': ['Ashmoun City'],
        'Menouf': ['Menouf City'],
      },
      'Beheira': {
        'Damanhour': ['Shoubra', 'Abou El Rish', 'Qartasa'],
        'Kafr El Dawwar': ['Sidi Shehata', 'El Senia'],
        'Rashid (Rosetta)': ['Rashid City'],
        'Edku': ['Edku City'],
      },
      'Kafr El Sheikh': {
        'Kafr El Sheikh City': ['Sakha', 'Qantara', 'Gharb'],
        'Desouk': ['Desouk City'],
        'Baltim': ['Baltim City', 'Masyaf Baltim'],
      },
      'Damietta': {
        'Damietta City': ['Old Damietta', 'Bab El Haras', 'El Shatt'],
        'New Damietta': ['First District', 'Second District', 'Third District'],
        'Ras El Bar': ['First Area', 'Second Area', 'El Gherby'],
      },
      'Dakahlia': {
        'Mansoura': ['Hay El Gamaa', 'Gedila', 'Talkha', 'Toriel', 'El Mashaya', 'Sandub'],
        'Mit Ghamr': ['Mit Ghamr City', 'Daqados'],
        'Senbellawein': ['Senbellawein City'],
        'Dikirnis': ['Dikirnis City'],
      },
      'Gharbia': {
        'Tanta': ['Said', 'Moheb', 'Galaa', 'Botrous', 'Siger'],
        'Mahalla Al Kubra': ['Samanoud', 'El Gomhoureya', 'Ghazl El Mahalla'],
        'Zifta': ['Zifta City'],
      },
      'Sharkia': {
        'Zagazig': ['El Qawmia', 'El Montaza', 'Hassan Saleh', 'Sheyba'],
        '10th of Ramadan': ['First District', 'Second District', 'Third District'],
        'Bilbeis': ['Bilbeis City'],
        'Minya El Qamh': ['Minya El Qamh City'],
      },
      'Port Said': {
        'Port Said City': ['El Sharq', 'El Arab', 'El Dawahy', 'El Zohour'],
        'Port Fouad': ['Port Fouad City'],
      },
      'Ismailia': {
        'Ismailia City': ['First District', 'Second District', 'Third District'],
        'Fayed': ['Fayed City'],
        'Qantara': ['Qantara West', 'Qantara East'],
      },
      'Suez': {
        'Suez City': ['Arbaeen', 'Suez', 'Ganayen', 'Faisal', 'Ataqah'],
      },
      'Fayoum': {
        'Fayoum City': ['El Mesalla', 'El Baroudiya', 'Hawaret El Makta'],
        'Itsa': ['Itsa City'],
        'Tamiya': ['Tamiya City'],
        'Senoures': ['Senoures City'],
      },
      'Beni Suef': {
        'Beni Suef City': ['Mokbel', 'Ghamrawi', 'El Gezira'],
        'Wasta': ['Wasta City'],
        'Biba': ['Biba City'],
      },
      'Minya': {
        'Minya City': ['Abu Hilal', 'El Shalaby', 'New Minya'],
        'Mallawi': ['Mallawi City'],
        'Maghagha': ['Maghagha City'],
        'Samalut': ['Samalut City'],
      },
      'Asyut': {
        'Asyut City': ['Al Walidiya', 'Al Sadat', 'New Asyut'],
        'Dayrut': ['Dayrut City'],
        'Manfalut': ['Manfalut City'],
        'Qusiya': ['Qusiya City'],
      },
      'Sohag': {
        'Sohag City': ['East District', 'West District', 'New Sohag'],
        'Akhmim': ['Akhmim City'],
        'Girga': ['Girga City'],
        'Tahta': ['Tahta City'],
      },
      'Qena': {
        'Qena City': ['El Heswaya', 'El Maana', 'New Qena'],
        'Nag Hammadi': ['Nag Hammadi City'],
        'Qus': ['Qus City'],
      },
      'Luxor': {
        'Luxor City': ['East Bank', 'West Bank', 'Karnak', 'Awamia'],
        'Esna': ['Esna City'],
        'Armant': ['Armant City'],
      },
      'Aswan': {
        'Aswan City': ['Downtown', 'El Khazzan', 'Sahari', 'Kima', 'Aswan Corniche', 'Sadat', 'Akad'],
        'Edfu': ['Edfu City', 'El Redesia'],
        'Kom Ombo': ['Kom Ombo City', 'Daraw'],
      },
      'Red Sea': {
        'Hurghada': ['El Dahar', 'Sekalla', 'El Memsha', 'Sahl Hasheesh', 'Makadi Bay'],
        'Safaga': ['Safaga City'],
        'Marsa Alam': ['Marsa Alam City', 'Port Ghalib'],
        'El Gouna': ['Abu Tig Marina', 'Downtown', 'Kafr El Gouna'],
      },
      'South Sinai': {
        'Sharm El Sheikh': ['Naama Bay', 'Nabq Bay', 'Sharks Bay', 'Hadaba', 'Old Market'],
        'Dahab': ['Mashraba', 'Masbat', 'Assalah'],
        'Nuweiba': ['Nuweiba City', 'Tarabin'],
      },
      'North Sinai': {
        'Arish': ['El Masaeed', 'El Fawakhriya', 'Downtown'],
        'Sheikh Zuweid': ['Sheikh Zuweid City'],
      },
      'Matrouh': {
        'Marsa Matrouh': ['El Awam', 'El Rommel', 'Cleopatra'],
        'El Alamein': ['El Alamein City', 'Marina', 'Sidi Abdel Rahman'],
        'Siwa': ['Siwa Oasis'],
      },
      'New Valley': {
        'Kharga': ['Kharga City'],
        'Dakhla': ['Mut', 'El Qasr'],
      },
      travelingState: {
        'Methods': travelingMethods,
      },
    },
    
    // ── Saudi Arabia ────────────────────────────────────────────────────────
    'Saudi Arabia': {
      'Riyadh': {
        'Riyadh City': ['Olaya', 'Malaz', 'Diplomatic Quarter', 'Al Rawdah'],
      },
      'Makkah': {
        'Jeddah': ['Al Balad', 'Al Hamra', 'Al Rawdah', 'Obhur'],
        'Makkah City': ['Al Aziziya', 'Al Shubaika'],
      },
      travelingState: {
        'Methods': travelingMethods,
      },
    },
    
    // ── USA ─────────────────────────────────────────────────────────────────
    'USA': {
      'New York': {
        'New York City': ['Manhattan', 'Brooklyn', 'Queens', 'Bronx', 'Staten Island'],
      },
      travelingState: {
        'Methods': travelingMethods,
      },
    },
  };

  /// Get all countries matching the query
  static List<String> getCountries(String query) {
    final keys = _database.keys.toList()..sort();
    if (query.isEmpty) return keys;
    final q = query.toLowerCase();
    return keys.where((c) => c.toLowerCase().contains(q)).toList();
  }

  /// Get all states/provinces for a country matching the query
  static List<String> getStates(String country, String query) {
    if (!_database.containsKey(country)) return [];
    final states = _database[country]!.keys.toList();
    
    states.sort((a, b) {
      if (a == travelingState) return 1;
      if (b == travelingState) return -1;
      return a.compareTo(b);
    });

    if (query.isEmpty) return states;
    final q = query.toLowerCase();
    return states.where((s) => s.toLowerCase().contains(q)).toList();
  }

  /// Get cities for a country and state
  static List<String> getCities(String country, String state, String query) {
    if (country.isEmpty || !_database.containsKey(country)) return [];
    if (state.isEmpty || !_database[country]!.containsKey(state)) return [];

    if (state == travelingState) {
      if (query.isEmpty) return travelingMethods;
      final q = query.toLowerCase();
      return travelingMethods.where((m) => m.toLowerCase().contains(q)).toList();
    }

    final cities = _database[country]![state]!.keys.toList()..sort();
    
    if (query.isEmpty) return cities;
    final q = query.toLowerCase();
    return cities.where((city) => city.toLowerCase().contains(q)).toList();
  }

  /// Get areas for a country, state, and city
  static List<String> getAreas(String country, String state, String city, String query) {
    if (country.isEmpty || !_database.containsKey(country)) return [];
    if (state.isEmpty || !_database[country]!.containsKey(state)) return [];
    if (city.isEmpty || !_database[country]![state]!.containsKey(city)) return [];

    final areas = _database[country]![state]![city]!;
    
    if (query.isEmpty) return areas;
    final q = query.toLowerCase();
    return areas.where((area) => area.toLowerCase().contains(q)).toList();
  }

  static String getCountryFlag(String country) {
    const flags = {
      'Egypt': '🇪🇬',
      'Saudi Arabia': '🇸🇦',
      'UAE': '🇦🇪',
      'USA': '🇺🇸',
      'UK': '🇬🇧',
    };
    return flags[country] ?? '🌍';
  }
}
