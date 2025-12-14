import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { ConnectButton, useCurrentAccount } from '@mysten/dapp-kit';
import { RestaurantList } from './components/RestaurantList';

function App() {
  const currentAccount = useCurrentAccount();

  return (
    <BrowserRouter>
      <div className="min-h-screen bg-gray-50">
        <nav className="bg-white shadow-sm border-b">
          <div className="max-w-6xl mx-auto px-6 py-4 flex justify-between items-center">
            <div className="flex items-center gap-3">
              <h1 className="text-xl font-bold text-gray-800">🍽️ Reviews Rating</h1>
              <span className="text-sm text-gray-500">on Sui Blockchain</span>
            </div>
            <ConnectButton />
          </div>
        </nav>

        <Routes>
          <Route
            path="/"
            element={
              currentAccount ? (
                <RestaurantList userAddress={currentAccount.address} />
              ) : (
                <div className="flex flex-col items-center justify-center min-h-[calc(100vh-200px)]">
                  <div className="text-center max-w-md">
                    <h2 className="text-3xl font-bold text-gray-800 mb-4">
                      Welcome to Reviews Rating Platform
                    </h2>
                    <p className="text-gray-600 mb-8">
                      A decentralized review platform for restaurants on Sui blockchain.
                      Connect your wallet to get started.
                    </p>
                    <ConnectButton />
                  </div>
                </div>
              )
            }
          />
          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>

        <footer className="bg-white border-t mt-12">
          <div className="max-w-6xl mx-auto px-6 py-6 text-center text-gray-600">
            <p className="mb-2">
              Decentralized Review Rating Platform | Built on Sui Blockchain
            </p>
            <p className="text-sm text-gray-500">
              Transparent, On-chain Reviews with Sui Wallet
            </p>
          </div>
        </footer>
      </div>
    </BrowserRouter>
  );
}

export default App;