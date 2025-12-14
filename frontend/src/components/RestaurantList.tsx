import { useState, useEffect } from 'react';
import { useSignAndExecuteTransaction, useSuiClient } from '@mysten/dapp-kit';
import { Transaction } from '@mysten/sui/transactions';

const PACKAGE_ID = import.meta.env.VITE_PACKAGE_ID;
const PLATFORM_ID = import.meta.env.VITE_PLATFORM_ID;

interface Restaurant {
  id: string;
  name: string;
  description: string;
  location: string;
  cuisineType: string;
  averageRating: number;
  reviewCount: number;
}

interface RestaurantListProps {
  userAddress: string;
}

export function RestaurantList({ userAddress }: RestaurantListProps) {
  const [restaurants, setRestaurants] = useState<Restaurant[]>([]);
  const [loading, setLoading] = useState(true);
  const [showCreateForm, setShowCreateForm] = useState(false);
  const [selectedRestaurant, setSelectedRestaurant] = useState<string | null>(null);

  const [formData, setFormData] = useState({
    name: '',
    description: '',
    location: '',
    cuisineType: '',
  });

  const [reviewData, setReviewData] = useState({
    rating: 5,
    comment: '',
    serviceRating: 5,
    foodRating: 5,
    ambianceRating: 5,
  });

  const suiClient = useSuiClient();
  const { mutate: signAndExecute } = useSignAndExecuteTransaction();

  useEffect(() => {
    loadRestaurants();
  }, []);

  const loadRestaurants = async () => {
    try {
      setLoading(true);
      
      const response = await suiClient.queryEvents({
        query: {
          MoveEventType: `${PACKAGE_ID}::reviews_rating::RestaurantCreated`
        }
      });

      const restaurantData: Restaurant[] = [];
      
      for (const event of response.data) {
        const parsedData = event.parsedJson as any;
        
        const restaurant = await suiClient.getObject({
          id: parsedData.restaurant_id,
          options: { showContent: true }
        });

        if (restaurant.data?.content?.dataType === 'moveObject') {
          const fields = restaurant.data.content.fields as any;
          
          restaurantData.push({
            id: parsedData.restaurant_id,
            name: fields.name || parsedData.name,
            description: fields.description || '',
            location: fields.location || '',
            cuisineType: fields.cuisine_type || '',
            averageRating: fields.review_count > 0 
              ? fields.total_rating / fields.review_count 
              : 0,
            reviewCount: Number(fields.review_count) || 0,
          });
        }
      }

      setRestaurants(restaurantData);
    } catch (error) {
      console.error('Error loading restaurants:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleCreateRestaurant = async (e: React.FormEvent) => {
    e.preventDefault();

    try {
      const tx = new Transaction();
      
      tx.moveCall({
        target: `${PACKAGE_ID}::reviews_rating::create_restaurant`,
        arguments: [
          tx.object(PLATFORM_ID),
          tx.pure.string(formData.name),
          tx.pure.string(formData.description),
          tx.pure.string(formData.location),
          tx.pure.string(formData.cuisineType),
        ],
      });

      signAndExecute(
        { transaction: tx },
        {
          onSuccess: () => {
            alert('Restaurant created successfully!');
            setShowCreateForm(false);
            setFormData({ name: '', description: '', location: '', cuisineType: '' });
            setTimeout(() => loadRestaurants(), 2000);
          },
          onError: (error) => {
            console.error('Error creating restaurant:', error);
            alert('Failed to create restaurant');
          },
        }
      );
    } catch (error) {
      console.error('Error creating restaurant:', error);
      alert('Failed to create restaurant');
    }
  };

  const handleSubmitReview = async (restaurantId: string) => {
    try {
      const tx = new Transaction();
      
      const [proof] = tx.moveCall({
        target: `${PACKAGE_ID}::reviews_rating::submit_review`,
        arguments: [
          tx.object(PLATFORM_ID),
          tx.object(restaurantId),
          tx.pure.u8(reviewData.rating),
          tx.pure.string(reviewData.comment),
          tx.pure.vector('string', []),
          tx.pure.u8(reviewData.serviceRating),
          tx.pure.u8(reviewData.foodRating),
          tx.pure.u8(reviewData.ambianceRating),
          tx.object('0x6'),
        ],
      });

      tx.transferObjects([proof], tx.pure.address(userAddress));

      signAndExecute(
        { transaction: tx },
        {
          onSuccess: () => {
            alert('Review submitted successfully! You received a Proof of Review NFT.');
            setSelectedRestaurant(null);
            setReviewData({
              rating: 5,
              comment: '',
              serviceRating: 5,
              foodRating: 5,
              ambianceRating: 5,
            });
            setTimeout(() => loadRestaurants(), 2000);
          },
          onError: (error) => {
            console.error('Error submitting review:', error);
            alert('Failed to submit review');
          },
        }
      );
    } catch (error) {
      console.error('Error submitting review:', error);
      alert('Failed to submit review');
    }
  };

  const renderStars = (rating: number) => {
    return '⭐'.repeat(Math.round(rating));
  };

  if (loading) {
    return (
      <div className="flex justify-center items-center min-h-screen">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-500"></div>
      </div>
    );
  }

  return (
    <div className="max-w-6xl mx-auto p-6">
      <div className="flex justify-between items-center mb-8">
        <div>
          <h1 className="text-3xl font-bold text-gray-800">Restaurants</h1>
          <p className="text-gray-600 mt-1">
            Connected: {userAddress.slice(0, 6)}...{userAddress.slice(-4)}
          </p>
        </div>
        <button
          onClick={() => setShowCreateForm(!showCreateForm)}
          className="bg-blue-500 text-white px-6 py-2 rounded-lg hover:bg-blue-600 transition-colors"
        >
          {showCreateForm ? 'Cancel' : 'Create Restaurant'}
        </button>
      </div>

      {showCreateForm && (
        <div className="bg-white p-6 rounded-lg shadow-md mb-8">
          <h2 className="text-xl font-semibold mb-4">Create New Restaurant</h2>
          <form onSubmit={handleCreateRestaurant} className="space-y-4">
            <input
              type="text"
              placeholder="Restaurant Name"
              value={formData.name}
              onChange={(e) => setFormData({ ...formData, name: e.target.value })}
              className="w-full p-3 border rounded-lg"
              required
            />
            <textarea
              placeholder="Description"
              value={formData.description}
              onChange={(e) => setFormData({ ...formData, description: e.target.value })}
              className="w-full p-3 border rounded-lg"
              rows={3}
              required
            />
            <input
              type="text"
              placeholder="Location"
              value={formData.location}
              onChange={(e) => setFormData({ ...formData, location: e.target.value })}
              className="w-full p-3 border rounded-lg"
              required
            />
            <input
              type="text"
              placeholder="Cuisine Type"
              value={formData.cuisineType}
              onChange={(e) => setFormData({ ...formData, cuisineType: e.target.value })}
              className="w-full p-3 border rounded-lg"
              required
            />
            <button
              type="submit"
              className="w-full bg-green-500 text-white py-3 rounded-lg hover:bg-green-600 transition-colors"
            >
              Create Restaurant
            </button>
          </form>
        </div>
      )}

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {restaurants.map((restaurant) => (
          <div key={restaurant.id} className="bg-white rounded-lg shadow-md p-6 hover:shadow-lg transition-shadow">
            <h3 className="text-xl font-semibold text-gray-800 mb-2">{restaurant.name}</h3>
            <p className="text-gray-600 text-sm mb-2">{restaurant.cuisineType}</p>
            <p className="text-gray-500 text-sm mb-3">{restaurant.location}</p>
            <p className="text-gray-700 mb-4">{restaurant.description}</p>
            
            <div className="flex items-center justify-between mb-4">
              <div>
                <div className="text-2xl">{renderStars(restaurant.averageRating)}</div>
                <p className="text-sm text-gray-600">{restaurant.reviewCount} reviews</p>
              </div>
            </div>

            <button
              onClick={() => setSelectedRestaurant(restaurant.id)}
              className="w-full bg-blue-500 text-white py-2 rounded-lg hover:bg-blue-600 transition-colors"
            >
              Write Review
            </button>
          </div>
        ))}
      </div>

      {selectedRestaurant && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-lg p-6 max-w-md w-full">
            <h2 className="text-2xl font-bold mb-4">Write a Review</h2>
            
            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium mb-2">Overall Rating</label>
                <select
                  value={reviewData.rating}
                  onChange={(e) => setReviewData({ ...reviewData, rating: Number(e.target.value) })}
                  className="w-full p-2 border rounded-lg"
                >
                  {[1, 2, 3, 4, 5].map(n => (
                    <option key={n} value={n}>{n} ⭐</option>
                  ))}
                </select>
              </div>

              <div>
                <label className="block text-sm font-medium mb-2">Service Rating</label>
                <select
                  value={reviewData.serviceRating}
                  onChange={(e) => setReviewData({ ...reviewData, serviceRating: Number(e.target.value) })}
                  className="w-full p-2 border rounded-lg"
                >
                  {[1, 2, 3, 4, 5].map(n => (
                    <option key={n} value={n}>{n} ⭐</option>
                  ))}
                </select>
              </div>

              <div>
                <label className="block text-sm font-medium mb-2">Food Rating</label>
                <select
                  value={reviewData.foodRating}
                  onChange={(e) => setReviewData({ ...reviewData, foodRating: Number(e.target.value) })}
                  className="w-full p-2 border rounded-lg"
                >
                  {[1, 2, 3, 4, 5].map(n => (
                    <option key={n} value={n}>{n} ⭐</option>
                  ))}
                </select>
              </div>

              <div>
                <label className="block text-sm font-medium mb-2">Ambiance Rating</label>
                <select
                  value={reviewData.ambianceRating}
                  onChange={(e) => setReviewData({ ...reviewData, ambianceRating: Number(e.target.value) })}
                  className="w-full p-2 border rounded-lg"
                >
                  {[1, 2, 3, 4, 5].map(n => (
                    <option key={n} value={n}>{n} ⭐</option>
                  ))}
                </select>
              </div>

              <div>
                <label className="block text-sm font-medium mb-2">Comment</label>
                <textarea
                  value={reviewData.comment}
                  onChange={(e) => setReviewData({ ...reviewData, comment: e.target.value })}
                  className="w-full p-2 border rounded-lg"
                  rows={4}
                  placeholder="Share your experience..."
                  required
                />
              </div>

              <div className="flex gap-3">
                <button
                  onClick={() => handleSubmitReview(selectedRestaurant)}
                  className="flex-1 bg-blue-500 text-white py-2 rounded-lg hover:bg-blue-600 transition-colors"
                >
                  Submit Review
                </button>
                <button
                  onClick={() => setSelectedRestaurant(null)}
                  className="flex-1 bg-gray-300 text-gray-700 py-2 rounded-lg hover:bg-gray-400 transition-colors"
                >
                  Cancel
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {restaurants.length === 0 && (
        <div className="text-center py-12">
          <p className="text-gray-500 text-lg">No restaurants yet. Be the first to create one!</p>
        </div>
      )}
    </div>
  );
}