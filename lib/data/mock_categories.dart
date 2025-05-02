// This file provides mock data for product categories
// It's used to ensure the app displays a diverse range of categories with unique images

class CategoryData {
  final String name;
  final String image;
  final String description;
  
  CategoryData({
    required this.name,
    required this.image,
    required this.description,
  });
}

// List of categories with sample featured images
final List<CategoryData> categories = [
  CategoryData(
    name: 'Electronics',
    image: 'https://images.unsplash.com/photo-1593344484962-796055d4a3a4?q=80&w=2574&auto=format&fit=crop',
    description: 'Latest gadgets and electronic devices',
  ),
  CategoryData(
    name: 'Clothing',
    image: 'https://images.unsplash.com/photo-1441986300917-64674bd600d8?q=80&w=2670&auto=format&fit=crop',
    description: 'Fashionable apparel for all occasions',
  ),
  CategoryData(
    name: 'Home & Kitchen',
    image: 'https://images.unsplash.com/photo-1551516594-56cb78394645?q=80&w=2426&auto=format&fit=crop',
    description: 'Everything you need for your home',
  ),
  CategoryData(
    name: 'Books',
    image: 'https://images.unsplash.com/photo-1495446815901-a7297e633e8d?q=80&w=2670&auto=format&fit=crop',
    description: 'Bestsellers and classic literature',
  ),
  CategoryData(
    name: 'Beauty & Personal Care',
    image: 'https://images.unsplash.com/photo-1596462502278-27bfdc403348?q=80&w=2670&auto=format&fit=crop',
    description: 'Skincare, makeup, and personal care products',
  ),
  CategoryData(
    name: 'Sports & Outdoors',
    image: 'https://images.unsplash.com/photo-1517649763962-0c623066013b?q=80&w=2670&auto=format&fit=crop',
    description: 'Equipment and gear for sports and outdoor activities',
  ),
  CategoryData(
    name: 'Toys & Games',
    image: 'https://images.unsplash.com/photo-1566576912321-d58ddd7a6088?q=80&w=2670&auto=format&fit=crop',
    description: 'Fun toys and games for all ages',
  ),
  CategoryData(
    name: 'Jewelry',
    image: 'https://images.unsplash.com/photo-1515562141207-7a88fb7ce338?q=80&w=2670&auto=format&fit=crop',
    description: 'Elegant jewelry and accessories',
  ),
];

// Sample products for each category
final Map<String, List<Map<String, dynamic>>> categoryProducts = {
  'Electronics': [
    {
      'name': 'Wireless Earbuds',
      'description': 'High-quality wireless earbuds with noise cancellation',
      'price': 25197.20,
      'images': ['https://images.unsplash.com/photo-1590658006821-04f4128ddbc1?q=80&w=2533&auto=format&fit=crop'],
      'stockQuantity': 50,
      'isFeatured': true,
    },
    {
      'name': 'Smart Watch',
      'description': 'Feature-rich smartwatch with health monitoring',
      'price': 55997.20,
      'images': ['https://images.unsplash.com/photo-1579586337278-3befd40fd17a?q=80&w=2672&auto=format&fit=crop'],
      'stockQuantity': 30,
      'isFeatured': true,
    },
    {
      'name': 'Bluetooth Speaker',
      'description': 'Portable bluetooth speaker with superior sound quality',
      'price': 22397.20,
      'images': ['https://images.unsplash.com/photo-1608043152269-423dbba4e7e1?q=80&w=2670&auto=format&fit=crop'],
      'stockQuantity': 45,
      'isFeatured': false,
    },
  ],
  'Clothing': [
    {
      'name': 'Men\'s Casual Shirt',
      'description': 'Comfortable cotton shirt for casual wear',
      'price': 11197.20,
      'images': ['https://images.unsplash.com/photo-1626497764746-6dc36546b388?q=80&w=2626&auto=format&fit=crop'],
      'stockQuantity': 100,
      'isFeatured': true,
    },
    {
      'name': 'Women\'s Summer Dress',
      'description': 'Elegant summer dress for casual and formal occasions',
      'price': 16797.20,
      'images': ['https://images.unsplash.com/photo-1612336307429-8a898d10e223?q=80&w=2670&auto=format&fit=crop'],
      'stockQuantity': 80,
      'isFeatured': true,
    },
  ],
  'Home & Kitchen': [
    {
      'name': 'Coffee Maker',
      'description': 'Automatic coffee maker with programmable settings',
      'price': 36397.20,
      'images': ['https://images.unsplash.com/photo-1585827552668-d0728b355e3d?q=80&w=2574&auto=format&fit=crop'],
      'stockQuantity': 25,
      'isFeatured': true,
    },
    {
      'name': 'Cookware Set',
      'description': '10-piece non-stick cookware set',
      'price': 41997.20,
      'images': ['https://images.unsplash.com/photo-1584824388170-83bb4d33e10f?q=80&w=2574&auto=format&fit=crop'],
      'stockQuantity': 20,
      'isFeatured': false,
    },
  ],
  'Books': [
    {
      'name': 'Bestselling Novel',
      'description': 'Award-winning fiction novel',
      'price': 6997.20,
      'images': ['https://images.unsplash.com/photo-1544947950-fa07a98d237f?q=80&w=2574&auto=format&fit=crop'],
      'stockQuantity': 200,
      'isFeatured': true,
    },
    {
      'name': 'Cookbook',
      'description': 'Collection of gourmet recipes',
      'price': 9797.20,
      'images': ['https://images.unsplash.com/photo-1589998059171-988d887df646?q=80&w=2676&auto=format&fit=crop'],
      'stockQuantity': 150,
      'isFeatured': false,
    },
  ],
  'Beauty & Personal Care': [
    {
      'name': 'Skincare Set',
      'description': 'Complete skincare routine set',
      'price': 22397.20,
      'images': ['https://images.unsplash.com/photo-1571781926291-c477ebfd024b?q=80&w=2688&auto=format&fit=crop'],
      'stockQuantity': 60,
      'isFeatured': true,
    },
    {
      'name': 'Perfume',
      'description': 'Luxury fragrance for men and women',
      'price': 25197.20,
      'images': ['https://images.unsplash.com/photo-1523293182086-7651a899d37f?q=80&w=2670&auto=format&fit=crop'],
      'stockQuantity': 40,
      'isFeatured': false,
    },
  ],
  'Sports & Outdoors': [
    {
      'name': 'Yoga Mat',
      'description': 'Non-slip yoga mat for home workouts',
      'price': 8397.20,
      'images': ['https://images.unsplash.com/photo-1518611012118-696072aa579a?q=80&w=2670&auto=format&fit=crop'],
      'stockQuantity': 120,
      'isFeatured': true,
    },
    {
      'name': 'Hiking Backpack',
      'description': 'Durable hiking backpack with multiple compartments',
      'price': 19597.20,
      'images': ['https://images.unsplash.com/photo-1622260614927-208cfe3f5bed?q=80&w=2670&auto=format&fit=crop'],
      'stockQuantity': 35,
      'isFeatured': false,
    },
  ],
  'Toys & Games': [
    {
      'name': 'Board Game',
      'description': 'Family board game for all ages',
      'price': 11197.20,
      'images': ['https://images.unsplash.com/photo-1610890716171-6b1bb98ffd09?q=80&w=2531&auto=format&fit=crop'],
      'stockQuantity': 90,
      'isFeatured': true,
    },
    {
      'name': 'RC Car',
      'description': 'Remote-controlled car for kids',
      'price': 13997.20,
      'images': ['https://images.unsplash.com/photo-1594787318286-3d835c1d207f?q=80&w=2670&auto=format&fit=crop'],
      'stockQuantity': 50,
      'isFeatured': false,
    },
  ],
  'Jewelry': [
    {
      'name': 'Silver Necklace',
      'description': 'Elegant sterling silver necklace',
      'price': 36397.20,
      'images': ['https://images.unsplash.com/photo-1599643478518-a784e5dc4c8f?q=80&w=2670&auto=format&fit=crop'],
      'stockQuantity': 30,
      'isFeatured': true,
    },
    {
      'name': 'Gold Bracelet',
      'description': '18K gold bracelet with unique design',
      'price': 83997.20,
      'images': ['https://images.unsplash.com/photo-1611652022419-a9419f74343d?q=80&w=2588&auto=format&fit=crop'],
      'stockQuantity': 15,
      'isFeatured': true,
    },
  ],
}; 