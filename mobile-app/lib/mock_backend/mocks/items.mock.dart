import '../../domain/entities/post.dart';
import 'users.mock.dart';

// ============================================================
// MOCK POSTS (ITEMS) — 20 realistic records
// user_id values map exactly to existing mock users
// ============================================================

final List<Post> mockPosts = [
  Post(
    id: "uuid-post-01",
    userId: mockUsers[0].id, // Ahmed Ali
    title: "Lost Black Leather Wallet",
    description: "Black leather bifold wallet containing national ID, credit cards, and about 500 EGP cash. Lost near Cairo University main gate.",
    category: "Wallet",
    postType: "lost",
    imageUrl: "https://images.unsplash.com/photo-1627123424574-724758594e93?w=600",
    country: "Egypt",
    state: "Cairo",
    city: "Cairo",
    createdAt: DateTime.now().subtract(const Duration(days: 2)),
    updatedAt: DateTime.now().subtract(const Duration(days: 2)),
  ),
  Post(
    id: "uuid-post-02",
    userId: mockUsers[2].id, // John Smith
    title: "Found iPhone 15 Pro Max",
    description: "Blue titanium iPhone 15 Pro Max with a clear MagSafe case. Found in Smouha district near the mall entrance. Screen has a small crack at the corner.",
    category: "Electronics",
    postType: "found",
    imageUrl: "https://images.unsplash.com/photo-1510557880182-3d4d3cba35a5?w=600",
    country: "Egypt",
    state: "Alexandria",
    city: "Alexandria",
    createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    updatedAt: DateTime.now().subtract(const Duration(hours: 5)),
  ),
  Post(
    id: "uuid-post-03",
    userId: mockUsers[4].id, // Omar Khaled
    title: "Lost Golden Retriever – Max",
    description: "Male Golden Retriever, 3 years old, answers to Max. Wearing a red collar with a blue tag. Very friendly. Lost near Maadi Corniche.",
    category: "Pets",
    postType: "lost",
    imageUrl: "https://images.unsplash.com/photo-1552053831-71594a27632d?w=600",
    country: "Egypt",
    state: "Cairo",
    city: "Cairo",
    createdAt: DateTime.now().subtract(const Duration(days: 14)),
    updatedAt: DateTime.now().subtract(const Duration(days: 10)),
  ),
  Post(
    id: "uuid-post-04",
    userId: mockUsers[6].id, // Karim
    title: "Found Tesla Model 3 Key Fob",
    description: "Found a Tesla Model 3 key fob in a black case in the parking garage of City Stars mall, Level B2. No name or contact info inside.",
    category: "Keys",
    postType: "found",
    imageUrl: "https://images.unsplash.com/photo-1584438784894-089d6a62b8fa?w=600",
    country: "Egypt",
    state: "Cairo",
    city: "Nasr City",
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
    updatedAt: DateTime.now().subtract(const Duration(days: 1)),
  ),
  Post(
    id: "uuid-post-05",
    userId: mockUsers[7].id, // Layla
    title: "Lost Blue JanSport Backpack",
    description: "Dark blue JanSport backpack with my laptop (MacBook Air M2), notebooks, and my passport inside. Lost at Cairo International Airport Terminal 2.",
    category: "Bags",
    postType: "lost",
    imageUrl: "https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=600",
    country: "Egypt",
    state: "Cairo",
    city: "Cairo",
    createdAt: DateTime.now().subtract(const Duration(days: 3)),
    updatedAt: DateTime.now().subtract(const Duration(days: 3)),
  ),
  Post(
    id: "uuid-post-06",
    userId: mockUsers[8].id, // Alex Johnson
    title: "Lost Silver MacBook Pro 14",
    description: "Space gray MacBook Pro 14-inch with M3 chip. Has a sticker of the NYC skyline on the lid. Lost at JFK Airport, Terminal 4.",
    category: "Electronics",
    postType: "lost",
    imageUrl: "https://images.unsplash.com/photo-1496181133206-80ce9b88a853?w=600",
    country: "USA",
    state: "New York",
    city: "New York City",
    createdAt: DateTime.now().subtract(const Duration(days: 4)),
    updatedAt: DateTime.now().subtract(const Duration(days: 4)),
  ),
  Post(
    id: "uuid-post-07",
    userId: mockUsers[1].id, // Sarah
    title: "Found Gold Women's Watch",
    description: "Found an elegant ladies gold watch – appears to be a Rolex Datejust – near the bench in front of Al-Azhar Park. No scratches.",
    category: "Accessories",
    postType: "found",
    imageUrl: "https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=600",
    country: "Egypt",
    state: "Cairo",
    city: "Cairo",
    createdAt: DateTime.now().subtract(const Duration(hours: 10)),
    updatedAt: DateTime.now().subtract(const Duration(hours: 10)),
  ),
  Post(
    id: "uuid-post-08",
    userId: mockUsers[3].id, // Emily Chen
    title: "Lost Prescription Glasses",
    description: "Black-frame rectangular glasses with -3.5 prescription. Lost in a soft navy blue case. Lost somewhere in Downtown Cairo near Tahrir Square.",
    category: "Other",
    postType: "lost",
    imageUrl: "https://images.unsplash.com/photo-1591076482161-42ce6da69f67?w=600",
    country: "Egypt",
    state: "Cairo",
    city: "Cairo",
    createdAt: DateTime.now().subtract(const Duration(days: 6)),
    updatedAt: DateTime.now().subtract(const Duration(days: 6)),
  ),
  Post(
    id: "uuid-post-09",
    userId: mockUsers[0].id, // Ahmed Ali (another post)
    title: "Found Child's Toy – Red Fire Truck",
    description: "Found a red metal toy fire truck near the children's play area in Orman Garden. Looks like a collectible. No child was nearby.",
    category: "Other",
    postType: "found",
    imageUrl: "https://images.unsplash.com/photo-1566576912321-d58ddd7a6088?w=600",
    country: "Egypt",
    state: "Giza",
    city: "Giza",
    createdAt: DateTime.now().subtract(const Duration(days: 7)),
    updatedAt: DateTime.now().subtract(const Duration(days: 7)),
  ),
  Post(
    id: "uuid-post-10",
    userId: mockUsers[4].id, // Omar
    title: "Lost Car Keys – Honda Civic",
    description: "Honda Civic 2021 car key with a black keychain that has a small red tag. Lost in Mall of Egypt parking area. Also has a house key attached.",
    category: "Keys",
    postType: "lost",
    imageUrl: "https://images.unsplash.com/photo-1541899481282-d53bffe3c35d?w=600",
    country: "Egypt",
    state: "Giza",
    city: "6th of October",
    createdAt: DateTime.now().subtract(const Duration(days: 5)),
    updatedAt: DateTime.now().subtract(const Duration(days: 5)),
  ),
  Post(
    id: "uuid-post-11",
    userId: mockUsers[2].id, // John Smith
    title: "Found Brown Leather Briefcase",
    description: "Found a quality brown leather briefcase containing some documents (in Arabic) and a charger. Found at a coffee shop in New Cairo.",
    category: "Bags",
    postType: "found",
    imageUrl: "https://images.unsplash.com/photo-1547949003-9792a18a2601?w=600",
    country: "Egypt",
    state: "Cairo",
    city: "New Cairo",
    createdAt: DateTime.now().subtract(const Duration(hours: 20)),
    updatedAt: DateTime.now().subtract(const Duration(hours: 20)),
  ),
  Post(
    id: "uuid-post-12",
    userId: mockUsers[6].id, // Karim
    title: "Lost Samsung Galaxy S24 Ultra",
    description: "Black Samsung Galaxy S24 Ultra with a transparent cover. Screen lock PIN only. Lost at Kempinski Hotel lobby, New Cairo.",
    category: "Electronics",
    postType: "lost",
    imageUrl: "https://images.unsplash.com/photo-1610945265064-0e34e5519bbf?w=600",
    country: "Egypt",
    state: "Cairo",
    city: "New Cairo",
    createdAt: DateTime.now().subtract(const Duration(days: 9)),
    updatedAt: DateTime.now().subtract(const Duration(days: 9)),
  ),
  Post(
    id: "uuid-post-13",
    userId: mockUsers[7].id, // Layla
    title: "Found Passport – Egyptian Nationality",
    description: "Found an Egyptian passport in front of the Mogamma building in Tahrir. The owner's name is visible. Please reach out if it's yours.",
    category: "Documents",
    postType: "found",
    imageUrl: "https://images.unsplash.com/photo-1606768666853-403c90a981ad?w=600",
    country: "Egypt",
    state: "Cairo",
    city: "Cairo",
    createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    updatedAt: DateTime.now().subtract(const Duration(hours: 3)),
  ),
  Post(
    id: "uuid-post-14",
    userId: mockUsers[8].id, // Alex
    title: "Lost AirPods Pro 2nd Gen",
    description: "Lost my AirPods Pro 2nd generation in their white MagSafe case. Custom engraving 'AJ2024' on the case. Lost at Central Park, NYC.",
    category: "Electronics",
    postType: "lost",
    imageUrl: "https://images.unsplash.com/photo-1600294037681-c80b4cb5b434?w=600",
    country: "USA",
    state: "New York",
    city: "New York City",
    createdAt: DateTime.now().subtract(const Duration(days: 8)),
    updatedAt: DateTime.now().subtract(const Duration(days: 8)),
  ),
  Post(
    id: "uuid-post-15",
    userId: mockUsers[1].id, // Sarah
    title: "Found Men's Silver Ring",
    description: "Found a large silver ring with Arabic calligraphy inscription on the inside. Found on the prayer area carpet of Al-Hussein Mosque.",
    category: "Accessories",
    postType: "found",
    imageUrl: "https://images.unsplash.com/photo-1605100804763-247f67b3557e?w=600",
    country: "Egypt",
    state: "Cairo",
    city: "Cairo",
    createdAt: DateTime.now().subtract(const Duration(days: 11)),
    updatedAt: DateTime.now().subtract(const Duration(days: 11)),
  ),
];

// ============================================================
// HELPERS
// ============================================================

/// Filter mock posts by post type: 'lost' or 'found'
List<Post> getMockPostsByType(String postType) =>
    mockPosts.where((p) => p.postType == postType).toList();

/// Filter mock posts by user ID
List<Post> getMockPostsByUser(String userId) =>
    mockPosts.where((p) => p.userId == userId).toList();

/// Get a single mock post by ID
Post? getMockPostById(String id) {
  try {
    return mockPosts.firstWhere((p) => p.id == id);
  } catch (_) {
    return null;
  }
}

/// Get the current user's mock posts
List<Post> get currentUserMockPosts {
  const currentUserId = "uuid-user-01"; // Ahmed Ali (the mock logged-in user)
  return getMockPostsByUser(currentUserId);
}
