# Reviews Rating Platform on Sui Blockchain

A decentralized, transparent review rating platform for the food service industry built on Sui blockchain.

[![Sui](https://img.shields.io/badge/Sui-Blockchain-blue)](https://sui.io)
[![Move](https://img.shields.io/badge/Language-Move-orange)](https://github.com/move-language/move)
[![License](https://img.shields.io/badge/License-Apache%202.0-green.svg)](LICENSE)

## 🌟 Overview

Unlike traditional review platforms that hide their rating algorithms, this platform publishes the rating algorithm on-chain for complete transparency and verification. Sui's low computational costs make it financially viable to submit, rate, and rank all reviews on-chain.

### Live Deployment

- **Network:** Sui Testnet
- **Package ID:** `0x38deb9fd20b2850f0b725d3d8fc0350515e600dce83332029123a9b5cf5510eb`
- **Platform Object ID:** `0x09ae1ec3f9f749a3ce46109ff0dd52f6821666bee1acf84a5d2ec0bb7c7b4446`
- **Explorer:** [View on Sui Explorer](https://suiscan.xyz/testnet/object/0x38deb9fd20b2850f0b725d3d8fc0350515e600dce83332029123a9b5cf5510eb)

## ✨ Key Features

- **Transparent On-Chain Reviews** - All reviews and ratings stored immutably on Sui blockchain
- **Sui Wallet Integration** - Easy connection with any Sui-compatible wallet
- **Proof of Review NFTs** - Users receive NFT proof for each review submitted
- **Multi-Dimensional Ratings** - Rate service, food quality, and ambiance separately
- **Restaurant Management** - Create and manage restaurant profiles on-chain
- **Owner Dashboard** - Restaurant owners can respond to reviews
- **Menu Management** - Add and update dishes with pricing
- **Verifiable Ratings** - Transparent average rating calculation

## 🏗️ Architecture

### Smart Contract (Move)
- **Platform** - Central registry of all restaurants and reviews
- **Restaurant** - Restaurant profiles with menu and review tracking
- **Review** - Individual review objects with detailed ratings
- **ProofOfReview** - NFT minted for each review as verification
- **RestaurantDashboard** - Owner management interface

### Frontend (React + TypeScript)
- **React 18** with TypeScript
- **@mysten/dapp-kit** for Sui Wallet integration
- **Sui SDK** for blockchain interactions
- **Tailwind CSS** for styling
- **React Router** for navigation

## 📋 Prerequisites

- Node.js >= 18.0.0
- npm >= 9.0.0
- Sui CLI >= 1.61.0
- Sui Wallet (browser extension)

## 🚀 Installation & Setup

### 1. Clone the Repository

```bash
git clone https://github.com/Yauheni-Ivashkevich/reviews_rating.git
cd reviews_rating
```

### 2. Smart Contract Setup

The contract is already deployed on Sui testnet. To deploy your own instance:

```bash
# Build the Move package
sui move build

# Run tests
sui move test

# Publish to testnet
sui client publish --gas-budget 100000000
```

Save the **Package ID** and **Platform Object ID** from the output.

### 3. Frontend Setup

```bash
cd frontend

# Install dependencies
npm install --legacy-peer-deps

# Create .env.local file
cat > .env.local << EOF
VITE_PACKAGE_ID=0x38deb9fd20b2850f0b725d3d8fc0350515e600dce83332029123a9b5cf5510eb
VITE_PLATFORM_ID=0x09ae1ec3f9f749a3ce46109ff0dd52f6821666bee1acf84a5d2ec0bb7c7b4446
VITE_NETWORK=testnet
EOF

# Start development server
npm run dev
```

The app will be available at `http://localhost:5173`

## 🎮 Usage

### For Users

1. **Connect Wallet** - Click "Connect Wallet" and select your Sui wallet (Sui Wallet, Suiet, Ethos, etc.)
2. **Browse Restaurants** - View all registered restaurants and their ratings
3. **Submit Reviews** - Click "Write Review" on any restaurant to submit your review with:
   - Overall rating (1-5 stars)
   - Service rating
   - Food rating
   - Ambiance rating
   - Written comment
4. **Receive NFT** - Get a Proof of Review NFT for each review submitted

### For Restaurant Owners

1. **Create Restaurant** - Click "Create Restaurant" to register your establishment
2. **Add Menu Items** - Add dishes with prices and descriptions
3. **Respond to Reviews** - Use your dashboard to reply to customer reviews
4. **Update Information** - Modify restaurant details and menu items

## 🧪 Testing

```bash
# Run Move tests
cd reviews_rating
sui move test

# Expected output:
# Test result: OK. Total tests: 9; passed: 9; failed: 0
```

### Test Coverage

- ✅ Platform initialization
- ✅ Restaurant creation
- ✅ Dish menu management
- ✅ Review submission with NFT minting
- ✅ Multi-user review aggregation
- ✅ Owner response functionality
- ✅ Rating validation (min/max bounds)
- ✅ Authorization checks
- ✅ Average rating calculation

## 📦 Smart Contract Details

### Key Functions

**create_restaurant**
```move
public fun create_restaurant(
    platform: &mut Platform,
    name: String,
    description: String,
    location: String,
    cuisine_type: String,
    ctx: &mut TxContext
)
```

**submit_review**
```move
public fun submit_review(
    platform: &mut Platform,
    restaurant: &mut Restaurant,
    rating: u8,
    comment: String,
    dishes_ordered: vector<String>,
    service_rating: u8,
    food_rating: u8,
    ambiance_rating: u8,
    clock: &Clock,
    ctx: &mut TxContext
): ProofOfReview
```

**add_dish_to_menu**
```move
public fun add_dish_to_menu(
    restaurant: &mut Restaurant,
    dish_name: String,
    price: u64,
    description: String,
    ctx: &mut TxContext
)
```

### Events

- `RestaurantCreated` - Emitted when a new restaurant is created
- `ReviewSubmitted` - Emitted when a review is posted
- `DishAdded` - Emitted when a dish is added to menu

## 🏆 Sui Warsaw X Wrocław Hackathon - Track 2

### Challenge: Preconfigured Challenges Track - Reviews Rating Platform

### Implementation Highlights

**✅ Complete Working Project**
- Smart contract deployed on testnet
- Frontend application functional with Sui Wallet integration
- All tests passing (9/9)

**✅ Quality Improvements**
- Removed `entry` modifiers for better composability
- Returns ProofOfReview NFT instead of self-transfer
- Follows Sui Move conventions
- Comprehensive error handling
- Clean, well-documented code

**✅ Extra Features**
- **Sui Wallet Integration** - Simple, secure wallet connection
- **Multi-dimensional Ratings** - Service, food, ambiance scores
- **NFT Proof System** - On-chain proof of review ownership
- **Restaurant Dashboard** - Owner response system
- **Menu Management** - Full dish catalog with pricing
- **Real-time Updates** - Event-driven state synchronization

### Technical Excellence

- **Code Quality**: Zero compilation warnings, all lints addressed
- **Testing**: 100% test coverage of critical paths
- **Security**: Proper authorization checks and input validation
- **UX**: Clean, modern interface with loading states and error handling

### Innovation

- **Transparent Algorithm**: Rating calculation is publicly verifiable on-chain
- **Wallet Integration**: Seamless connection with Sui ecosystem wallets
- **NFT Proofs**: Creates collectible proof of participation
- **Composability**: Public functions enable integration with other dApps

## 📂 Project Structure

```
reviews_rating/
├── Move.toml                 # Move package configuration
├── sources/
│   └── reviews_rating.move   # Main smart contract
├── tests/
│   └── reviews_rating_tests.move  # Comprehensive test suite
└── frontend/
    ├── src/
    │   ├── components/
    │   │   └── RestaurantList.tsx   # Main app interface
    │   ├── App.tsx              # Root component with routing
    │   ├── main.tsx             # Entry point with wallet provider
    │   └── index.css            # Global styles
    ├── package.json
    ├── tailwind.config.js
    ├── postcss.config.js
    └── vite.config.ts
```

## 🔧 Development

### Build Frontend

```bash
cd frontend
npm run build
```

### Preview Production Build

```bash
npm run preview
```

## 🌐 Deployment

### Smart Contract

Contract is deployed on Sui testnet. For mainnet deployment:

```bash
sui client publish --gas-budget 100000000
```

### Frontend

Deploy to Vercel, Netlify, or any static hosting:

```bash
cd frontend
npm run build
# Upload dist/ folder to your hosting provider
```

Update `.env` with production values before building.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is licensed under the Apache 2.0 License - see the LICENSE file for details.

## 🙏 Acknowledgments

- Mysten Labs for Sui blockchain and developer tools
- Sui Move documentation and examples
- Sui Warsaw X Wrocław Hackathon organizers

## 📞 Contact

- GitHub: [@Yauheni-Ivashkevich](https://github.com/Yauheni-Ivashkevich)
- Project Repository: [reviews_rating](https://github.com/Yauheni-Ivashkevich/reviews_rating)

## 🎯 Hackathon Judging Criteria Alignment

### Implementation ✅
- Working smart contract with 9 passing tests
- Fully functional frontend with Sui Wallet integration
- Deployed and testable on Sui testnet

### Design ✅
- Clean, modular Move code following best practices
- Composable public functions
- Event-driven architecture
- Responsive, modern UI with Tailwind CSS

### Idea ✅
- Solves real problem: lack of transparency in review platforms
- Novel use of blockchain for verifiable ratings
- Wallet integration reduces friction for mainstream users
- NFT proofs add gamification element

### Outcome (UX) ✅
- Intuitive interface requiring minimal blockchain knowledge
- Simple wallet connection via standard Sui wallets
- Fast transactions leveraging Sui's performance
- Clear feedback and error handling

---

**Built with ❤️ on Sui Blockchain**