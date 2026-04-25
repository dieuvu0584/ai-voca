// Danh sách từ vựng tiếng Anh theo chủ đề — dùng để filter Session Preview
// Chỉ áp dụng cho en-US / en-GB
// Từ được chọn từ danh sách tần suất cao (en_50k) thuộc từng nhóm chủ đề

const Map<String, List<String>> kEnTopics = {
  // ── Thức ăn ──────────────────────────────────────────────────
  'food': [
    'bread', 'butter', 'cheese', 'milk', 'eggs', 'meat', 'fish',
    'chicken', 'beef', 'pork', 'rice', 'pasta', 'soup', 'salad', 'sandwich',
    'cake', 'cookie', 'pizza', 'burger', 'apple', 'banana', 'orange',
    'grape', 'lemon', 'potato', 'tomato', 'onion', 'carrot', 'corn', 'pepper',
    'salt', 'sugar', 'sauce', 'honey', 'chocolate', 'candy',
    'cream', 'flour', 'dough', 'dish', 'meal', 'taste', 'flavor', 'sweet',
    'sour', 'spicy', 'bitter', 'fresh', 'frozen', 'bake', 'roast',
    'grill', 'boil', 'slice', 'chop', 'recipe', 'ingredient', 'seasoning',
    'appetizer', 'dessert', 'breakfast', 'lunch', 'dinner', 'snack', 'feast',
    'diet', 'nutrition', 'calorie', 'protein', 'vegetarian', 'organic',
    'cherry', 'strawberry', 'peach', 'mango', 'pineapple', 'coconut',
    'mushroom', 'spinach', 'broccoli', 'cucumber', 'lettuce', 'garlic',
    'ginger', 'cinnamon', 'vanilla', 'mustard', 'vinegar', 'ketchup',
    'mayo', 'dressing', 'steak', 'sausage', 'bacon', 'shrimp',
    'crab', 'lobster', 'oyster', 'tuna', 'salmon', 'lamb', 'turkey',
    'tofu', 'noodle', 'dumpling', 'kebab', 'taco', 'sushi', 'curry',
  ],

  // ── Đồ uống ──────────────────────────────────────────────────
  'drink': [
    'water', 'coffee', 'juice', 'wine', 'beer', 'soda', 'alcohol',
    'cocktail', 'whiskey', 'vodka', 'champagne', 'liquor', 'smoothie',
    'shake', 'lemonade', 'beverage', 'drink', 'thirsty', 'pour',
    'glass', 'bottle', 'straw', 'refreshing',
    'sparkling', 'still', 'cold', 'warm', 'brew', 'blend', 'filter',
    'espresso', 'latte', 'cappuccino', 'mocha', 'herbal',
    'cider', 'sake', 'mead',
    'syrup', 'concentrate', 'decaf', 'hydrate', 'quench',
  ],

  // ── Đồ vật trong nhà ─────────────────────────────────────────
  'household': [
    'house', 'home', 'room', 'floor', 'ceiling', 'wall', 'door', 'window',
    'kitchen', 'bathroom', 'bedroom', 'furniture', 'chair', 'table', 'desk',
    'sofa', 'couch', 'shelf', 'cabinet', 'drawer', 'lamp', 'mirror',
    'carpet', 'curtain', 'shower', 'toilet', 'sink', 'stove', 'oven',
    'refrigerator', 'dishwasher', 'vacuum', 'broom', 'bucket',
    'brush', 'soap', 'towel', 'lock', 'stairs', 'garage', 'garden',
    'yard', 'roof', 'basement', 'attic', 'hallway', 'balcony', 'fence',
    'gate', 'fireplace', 'heater', 'laundry', 'clean', 'tidy',
    'organize', 'repair', 'paint', 'decorate', 'rent', 'apartment', 'flat',
    'pillow', 'blanket', 'mattress', 'wardrobe', 'closet', 'hanger',
    'laundry', 'washing', 'detergent', 'bleach', 'sponge', 'cloth',
    'trash', 'recycle', 'switch', 'outlet', 'socket', 'plug',
    'pipe', 'faucet', 'drain', 'roof', 'chimney', 'radiator',
  ],

  // ── Quần áo ──────────────────────────────────────────────────
  'clothing': [
    'shirt', 'pants', 'dress', 'skirt', 'jacket', 'coat', 'shoes', 'boots',
    'socks', 'glove', 'scarf', 'belt', 'sweater',
    'jeans', 'suit', 'uniform', 'underwear', 'pocket', 'button', 'zipper',
    'sleeve', 'collar', 'fashion', 'wear', 'size', 'cloth', 'fabric',
    'cotton', 'wool', 'leather', 'silk', 'wash', 'iron', 'wardrobe',
    'casual', 'formal', 'comfortable', 'elegant', 'outfit', 'accessory',
    'jewelry', 'necklace', 'bracelet', 'ring', 'earring', 'sunglasses',
    'purse', 'wallet', 'backpack', 'hoodie', 'blouse', 'cardigan',
    'vest', 'shorts', 'leggings', 'tights', 'swimsuit', 'pajama', 'robe',
    'sneakers', 'sandals', 'heels', 'slippers', 'loafers',
    'beanie', 'beret', 'helmet', 'mask', 'apron', 'gloves', 'mittens',
    'style', 'trend', 'brand', 'designer', 'vintage', 'secondhand',
  ],

  // ── Cơ thể ───────────────────────────────────────────────────
  'body': [
    'head', 'face', 'nose', 'mouth', 'tooth', 'teeth',
    'tongue', 'neck', 'shoulder', 'hand', 'finger', 'thumb', 'chest',
    'stomach', 'back', 'knee', 'foot', 'feet', 'skin', 'hair',
    'heart', 'brain', 'blood', 'bone', 'muscle', 'joint', 'spine', 'lung',
    'liver', 'kidney', 'nerve', 'breath', 'pulse', 'height', 'weight',
    'voice', 'sight', 'hearing', 'smell', 'taste', 'touch', 'sense',
    'sweat', 'tear', 'sneeze', 'cough', 'yawn', 'blink', 'swallow',
    'digest', 'absorb', 'breathe', 'heartbeat', 'circulation', 'immune',
    'hormone', 'cell', 'tissue', 'organ', 'skeleton', 'posture', 'gesture',
    'wrist', 'elbow', 'ankle', 'chin', 'cheek', 'forehead', 'eyebrow',
    'eyelash', 'pupil', 'iris', 'nostril', 'temple', 'nape',
  ],

  // ── Gia đình ─────────────────────────────────────────────────
  'family': [
    'mother', 'father', 'daughter', 'sister', 'brother', 'wife',
    'husband', 'family', 'parent', 'child', 'children', 'baby', 'grandmother',
    'grandfather', 'uncle', 'aunt', 'cousin', 'nephew', 'niece', 'relative',
    'married', 'wedding', 'divorce', 'birth', 'death', 'love', 'relationship',
    'bond', 'care', 'raise', 'grow', 'adult', 'teenager', 'infant', 'toddler',
    'twin', 'sibling', 'stepmother', 'stepfather', 'stepsister', 'stepbrother',
    'godmother', 'godfather', 'grandparent', 'grandchild',
    'heritage', 'tradition', 'generation', 'lineage', 'ancestry', 'surname',
    'home', 'household', 'domestic', 'nurture', 'support', 'trust',
  ],

  // ── Phương tiện giao thông ────────────────────────────────────
  'transport': [
    'train', 'plane', 'airplane', 'bike', 'bicycle',
    'motorcycle', 'truck', 'boat', 'ship', 'subway', 'taxi', 'ferry',
    'helicopter', 'walk', 'drive', 'ride', 'travel', 'road', 'street',
    'highway', 'bridge', 'tunnel', 'station', 'airport', 'port', 'parking',
    'traffic', 'accident', 'fuel', 'engine', 'wheel', 'tire', 'seat',
    'ticket', 'passenger', 'driver', 'pilot', 'speed', 'distance', 'route',
    'direction', 'navigate', 'depart', 'arrive', 'delay', 'schedule',
    'vehicle', 'transport', 'journey', 'trip', 'voyage', 'commute', 'cruise',
    'freight', 'cargo', 'container', 'railway', 'tram', 'yacht',
    'canoe', 'kayak', 'scooter', 'skateboard', 'ambulance',
    'bulldozer', 'excavator', 'crane', 'forklift',
    'petrol', 'diesel', 'electric', 'hybrid', 'horsepower', 'brake', 'gear',
    'accelerate', 'overtake', 'lane', 'junction', 'roundabout', 'toll',
  ],

  // ── Thiên nhiên ──────────────────────────────────────────────
  'nature': [
    'tree', 'flower', 'grass', 'forest', 'mountain', 'river', 'lake',
    'ocean', 'beach', 'island', 'desert', 'moon', 'star',
    'cloud', 'rain', 'snow', 'wind', 'storm', 'fire', 'earth', 'rock',
    'stone', 'soil', 'plant', 'leaf', 'root', 'seed', 'season', 'spring',
    'summer', 'autumn', 'winter', 'weather', 'temperature', 'warm', 'cold',
    'flood', 'earthquake', 'volcano', 'climate', 'environment',
    'horizon', 'sunset', 'sunrise', 'rainbow', 'thunder', 'lightning',
    'mist', 'frost', 'wave', 'tide', 'waterfall', 'valley', 'hill',
    'cliff', 'cave', 'meadow', 'jungle', 'swamp', 'reef', 'glacier',
    'atmosphere', 'ecosystem', 'habitat', 'landscape', 'scenery', 'nature',
    'wild', 'wilderness', 'fertile', 'arid', 'tropical', 'polar', 'temperate',
    'humidity', 'pressure', 'altitude', 'depth', 'current', 'spring', 'well',
    'sand', 'pebble', 'cliff', 'canyon', 'plateau', 'plain', 'delta',
    'peninsula', 'cape', 'gulf', 'strait', 'channel', 'lake', 'pond',
  ],

  // ── Động vật ─────────────────────────────────────────────────
  'animals': [
    'bird', 'fish', 'horse', 'sheep', 'chicken',
    'duck', 'rabbit', 'mouse', 'snake', 'frog', 'lion', 'tiger',
    'bear', 'wolf', 'deer', 'elephant', 'monkey', 'eagle',
    'parrot', 'whale', 'dolphin', 'shark', 'butterfly',
    'spider', 'worm', 'crab', 'penguin', 'giraffe', 'zebra', 'crocodile',
    'turtle', 'lizard', 'hamster', 'squirrel', 'camel', 'kangaroo',
    'koala', 'panda', 'gorilla', 'chimpanzee', 'baboon', 'peacock', 'flamingo',
    'swan', 'goose', 'pigeon', 'sparrow', 'crow', 'hawk', 'falcon', 'vulture',
    'salmon', 'tuna', 'goldfish', 'jellyfish', 'lobster', 'oyster', 'clam',
    'mosquito', 'dragonfly', 'grasshopper', 'cricket', 'beetle', 'ladybug',
    'wild', 'domestic', 'farm', 'breed', 'mammal', 'reptile',
    'amphibian', 'insect', 'feather', 'scale', 'claw', 'wing',
    'tail', 'beak', 'horn', 'tusk', 'nest', 'burrow', 'herd', 'pack',
    'flock', 'swarm', 'hunt', 'prey', 'predator', 'hibernate', 'migrate',
  ],

  // ── Công việc ────────────────────────────────────────────────
  'work': [
    'work', 'office', 'company', 'business', 'meeting', 'project',
    'task', 'deadline', 'manager', 'boss', 'employee', 'team', 'salary',
    'wage', 'hire', 'fire', 'retire', 'career', 'profession',
    'doctor', 'teacher', 'lawyer', 'engineer', 'nurse', 'police', 'soldier',
    'artist', 'writer', 'farmer', 'cook', 'driver', 'secretary', 'intern',
    'experience', 'skill', 'training', 'promotion', 'resign', 'interview',
    'resume', 'colleague', 'client', 'customer', 'service', 'product',
    'market', 'industry', 'department', 'organization', 'government',
    'strategy', 'leadership', 'management', 'performance', 'review',
    'feedback', 'award', 'bonus', 'contract', 'agreement', 'negotiate',
    'collaborate', 'delegate', 'supervise', 'report', 'present', 'submit',
    'approve', 'reject', 'budget', 'resource', 'productivity', 'efficiency',
    'innovation', 'entrepreneur', 'startup', 'corporation', 'factory',
    'workshop', 'laboratory', 'studio', 'clinic', 'hospital', 'school',
    'court', 'firm', 'agency', 'bureau', 'ministry', 'council', 'union',
    'accountant', 'architect', 'designer', 'developer', 'analyst', 'consultant',
    'pharmacist', 'dentist', 'surgeon', 'therapist', 'counselor', 'librarian',
  ],

  // ── Công nghệ ────────────────────────────────────────────────
  'technology': [
    'computer', 'phone', 'mobile', 'tablet', 'laptop', 'screen', 'keyboard',
    'mouse', 'internet', 'website', 'email', 'software', 'program',
    'data', 'file', 'download', 'upload', 'search', 'password', 'account',
    'camera', 'video', 'photo', 'battery', 'charge', 'wifi', 'bluetooth',
    'robot', 'machine', 'device', 'digital', 'electronic', 'code', 'network',
    'server', 'cloud', 'database', 'security', 'update', 'install', 'stream',
    'broadcast', 'satellite', 'radar', 'sensor', 'chip', 'processor', 'memory',
    'storage', 'disk', 'cable', 'connector', 'port', 'browser', 'platform',
    'algorithm', 'automation',
    'drone', 'printer', 'scanner',
    'monitor', 'projector', 'speaker', 'microphone',
    'charger', 'modem', 'router', 'firewall', 'decrypt',
    'hack', 'virus', 'malware', 'spam', 'backup', 'restore', 'format', 'delete',
    'copy', 'paste', 'scroll', 'click', 'swipe', 'zoom', 'share', 'sync',
    'register', 'subscribe', 'notify', 'alert', 'update',
    'version', 'release', 'launch', 'deploy', 'test', 'crash',
  ],

  // ── Sức khỏe ─────────────────────────────────────────────────
  'health': [
    'health', 'sick', 'pain', 'hurt', 'medicine', 'drug', 'pill',
    'hospital', 'doctor', 'nurse', 'disease', 'virus', 'infection', 'fever',
    'cold', 'headache', 'heart', 'blood', 'pressure', 'exercise', 'diet',
    'sleep', 'rest', 'tired', 'energy', 'strong', 'weak', 'symptom',
    'treatment', 'surgery', 'vaccine', 'therapy', 'recovery', 'prevent',
    'diagnose', 'cure', 'heal', 'injury', 'wound', 'bruise', 'allergy',
    'mental', 'stress', 'anxiety', 'depression', 'nutrition', 'fitness',
    'obesity', 'diabetes', 'cancer', 'emergency', 'ambulance', 'pharmacy',
    'prescription', 'patient', 'clinic', 'checkup', 'exam',
    'scan', 'urine', 'temperature', 'pulse', 'breathing',
    'cough', 'sneeze', 'nausea', 'vomit', 'diarrhea', 'constipation',
    'rash', 'itch', 'swelling', 'inflammation', 'chronic', 'acute',
    'disability', 'disorder', 'syndrome', 'condition', 'symptom',
    'antibiotic', 'painkiller', 'vitamin', 'supplement', 'mineral',
    'calories', 'protein', 'fiber', 'hydration',
    'meditation', 'yoga', 'stretch', 'cardio',
  ],

  // ── Giáo dục ─────────────────────────────────────────────────
  'education': [
    'school', 'university', 'college', 'class', 'lesson', 'study', 'learn',
    'teach', 'student', 'teacher', 'book', 'notebook', 'pencil',
    'homework', 'exam', 'test', 'grade', 'degree', 'knowledge', 'subject',
    'math', 'science', 'history', 'language', 'library', 'lecture', 'essay',
    'research', 'graduate', 'diploma', 'certificate', 'curriculum', 'semester',
    'tuition', 'scholarship', 'campus', 'dormitory', 'laboratory', 'experiment',
    'theory', 'practice', 'skill', 'quiz', 'assignment', 'presentation',
    'discussion', 'question', 'answer', 'understand', 'memory', 'intelligent',
    'creative', 'discipline', 'attendance', 'academic', 'professor', 'lecturer',
    'principal', 'dean', 'faculty', 'department', 'major', 'minor', 'elective',
    'compulsory', 'optional', 'enroll', 'register', 'apply', 'accept', 'reject',
    'fail', 'pass', 'score', 'rank', 'honor', 'award', 'kindergarten',
    'elementary', 'secondary', 'undergraduate',
    'doctorate', 'thesis', 'dissertation', 'publication', 'journal', 'article',
    'reference', 'citation', 'plagiarism', 'analysis',
  ],

  // ── Tiền bạc & mua sắm ───────────────────────────────────────
  'money': [
    'money', 'cash', 'bank', 'price', 'cost', 'sell', 'shop',
    'store', 'market', 'cheap', 'expensive', 'rich', 'poor', 'save', 'spend',
    'invest', 'loan', 'debt', 'credit', 'coin', 'bill', 'dollar', 'euro',
    'budget', 'economy', 'profit', 'loss', 'discount', 'sale',
    'receipt', 'income', 'expense', 'salary', 'account', 'transaction',
    'transfer', 'deposit', 'withdraw', 'currency', 'exchange', 'interest',
    'mortgage', 'insurance', 'rent', 'contract', 'value', 'afford', 'wealth',
    'financial', 'economic', 'trade', 'import', 'export', 'stock', 'share',
    'bond', 'fund', 'asset', 'liability', 'equity', 'dividend', 'portfolio',
    'inflation', 'recession', 'growth', 'poverty', 'prosperity',
    'wage', 'earn', 'refund', 'charge', 'commission',
    'bargain', 'negotiate', 'auction', 'purchase', 'order', 'delivery',
    'shipping', 'return', 'exchange', 'warranty', 'guarantee', 'counterfeit',
    'checkout', 'cashier', 'register', 'invoice', 'subscription',
  ],

  // ── Thể thao ─────────────────────────────────────────────────
  'sports': [
    'sport', 'game', 'play', 'lose', 'team', 'player', 'ball', 'goal',
    'score', 'match', 'competition', 'race', 'swim', 'jump', 'kick',
    'throw', 'catch', 'exercise', 'coach', 'training', 'champion',
    'medal', 'olympic', 'football', 'basketball', 'tennis', 'baseball',
    'golf', 'boxing', 'skiing', 'cycling', 'track', 'court', 'stadium',
    'arena', 'cheer', 'referee', 'foul', 'penalty', 'tournament', 'league',
    'season', 'fitness', 'strength', 'endurance', 'agility', 'speed',
    'stretch', 'sprint', 'marathon', 'triathlon', 'wrestling',
    'judo', 'karate', 'taekwondo', 'gymnastics', 'volleyball', 'rugby',
    'cricket', 'hockey', 'polo', 'archery', 'shooting', 'weightlifting',
    'rowing', 'sailing', 'surfing', 'diving', 'climbing', 'hiking',
    'skateboarding', 'snowboarding',
    'fencing', 'equestrian', 'triathlon', 'relay', 'hurdle', 'decathlon',
    'dribble', 'tackle', 'serve', 'volley', 'smash', 'backhand',
    'defense', 'offense', 'substitute', 'halftime', 'overtime', 'draw',
  ],

  // ── Cảm xúc ──────────────────────────────────────────────────
  'emotions': [
    'happy', 'angry', 'fear', 'love', 'hate', 'surprise',
    'nervous', 'excited', 'worried', 'confused', 'proud', 'shame', 'guilty',
    'lonely', 'hopeful', 'jealous', 'grateful', 'bored', 'curious', 'calm',
    'anxious', 'depressed', 'frustrated', 'embarrassed', 'confident',
    'brave', 'mood', 'feeling', 'emotion', 'cheerful', 'content', 'pleased',
    'delighted', 'thrilled', 'ecstatic', 'miserable', 'gloomy', 'grief',
    'sorrow', 'regret', 'remorse', 'disappointed', 'furious', 'irritated',
    'annoyed', 'disgusted', 'horrified', 'terrified', 'scared', 'relieved',
    'satisfied', 'fulfilled', 'inspired', 'motivated', 'enthusiastic',
    'passionate', 'compassionate', 'empathetic', 'sympathetic', 'affectionate',
    'tender', 'fond', 'adore', 'cherish', 'admire', 'respect', 'trust',
    'doubt', 'suspect', 'envy', 'bitter', 'resentful', 'overwhelmed',
    'numb', 'indifferent', 'apathetic', 'melancholy', 'nostalgic', 'hopeless',
  ],
};

/// Map từ → danh sách topic chứa từ đó (lookup ngược)
/// Được tạo 1 lần khi app khởi động
final Map<String, List<String>> kWordToTopics = () {
  final map = <String, List<String>>{};
  for (final entry in kEnTopics.entries) {
    for (final word in entry.value) {
      map.putIfAbsent(word, () => []).add(entry.key);
    }
  }
  return map;
}();
