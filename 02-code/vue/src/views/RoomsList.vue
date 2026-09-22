<template>
  <div class="rooms-page">
    <div class="navigation">
      <router-link to="/" class="nav-link">Home</router-link>
      <router-link to="/rooms" class="nav-link active">Rooms</router-link>
      <router-link to="/emails" class="nav-link">Email Logs</router-link>
      <button @click="logout" class="logout-btn">Logout</button>
    </div>

    <div class="rooms-container">
      <h2>Available Rooms</h2>

      <div class="filters">
        <select v-model="filters.location" class="location-select">
          <option value="">All Locations</option>
          <option v-for="loc in locations" :key="loc" :value="loc">{{ loc }}</option>
        </select>

        <input
          type="date"
          v-model="filters.date"
          class="date-input"
        />

        <button @click="loadRooms" :disabled="loading" class="search-btn">
          {{ loading ? 'Loading...' : 'Search' }}
        </button>
      </div>

      <div v-if="loading" class="loading">
        Loading rooms...
      </div>

      <div v-else-if="error" class="error">
        {{ error }}
        <button @click="loadRooms">Retry</button>
      </div>

      <div v-else-if="rooms.length === 0" class="empty">
        No rooms found.
      </div>

      <div v-else class="rooms-grid">
        <div
          v-for="room in rooms"
          :key="`${room.location}-${room.name}`"
          class="room-card"
          @click="viewRoom(room)"
        >
          <div class="room-header">
            <h3>{{ room.name }}</h3>
            <span class="location">{{ room.location }}</span>
          </div>
          <div class="room-details">
            <div class="detail">
              <span class="label">Capacity:</span>
              <span class="value">{{ room.capacity }} people</span>
            </div>
            <div class="detail">
              <span class="label">Price:</span>
              <span class="value price">£{{ (room.price / 100).toFixed(2) }}</span>
            </div>
          </div>
          <button class="view-btn">View Details</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { authService } from '@/services/auth.service'
import { roomService } from '@/services/room.service'

const router = useRouter()
const rooms = ref([])
const loading = ref(false)
const error = ref('')

const filters = reactive({
  location: '',
  date: new Date().toISOString().split('T')[0]
})

// Common UK locations
const locations = ref([
  'Aberdeen',
  'Belfast',
  'Birmingham',
  'Bristol',
  'Cambridge',
  'Cardiff',
  'Edinburgh',
  'Glasgow',
  'Leeds',
  'Leicester',
  'Liverpool',
  'London',
  'Manchester',
  'Newcastle',
  'Nottingham',
  'Oxford',
  'Portsmouth',
  'Sheffield',
  'Southampton',
  'York',
])

const loadRooms = async () => {
  if (!authService.isAuthenticated()) {
    router.push('/login')
    return
  }

  loading.value = true
  error.value = ''

  try {
    const result = await roomService.getRooms(filters)

    if (result.success) {
      rooms.value = result.data
    } else {
      error.value = result.error
    }
  } catch (err) {
    error.value = 'Failed to load rooms'
    console.error(err)
  } finally {
    loading.value = false
  }
}

const viewRoom = (room) => {
  router.push({
    path: `/room/${encodeURIComponent(room.location)}/${encodeURIComponent(room.name)}`,
    query: { date: filters.date }
  })
}

const logout = () => {
  authService.logout()
  router.push('/login')
}

onMounted(() => {
  if (!authService.isAuthenticated()) {
    router.push('/login')
  } else {
    loadRooms()
  }
})
</script>

<style scoped>
.rooms-page {
  padding: 20px;
  max-width: 1200px;
  margin: 0 auto;
}

.navigation {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 30px;
  padding-bottom: 15px;
  border-bottom: 1px solid #ddd;
}

.nav-link {
  padding: 8px 16px;
  text-decoration: none;
  color: #666;
  font-weight: 500;
}

.nav-link.active {
  color: #007bff;
  border-bottom: 2px solid #007bff;
}

.nav-link:hover {
  color: #0056b3;
}

.logout-btn {
  padding: 8px 16px;
  background: #dc3545;
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  font-weight: 500;
}

.logout-btn:hover {
  background: #c82333;
}

.rooms-container {
  background: white;
  padding: 30px;
  border-radius: 8px;
  box-shadow: 0 2px 10px rgba(0,0,0,0.1);
}

h2 {
  margin: 0 0 20px 0;
  color: #333;
}

.filters {
  display: grid;
  grid-template-columns: 1fr auto auto;
  gap: 10px;
  margin-bottom: 30px;
  align-items: center;
}

.location-select {
  padding: 10px;
  border: 1px solid #ddd;
  border-radius: 4px;
  font-size: 14px;
  background: white;
}

.date-input {
  padding: 10px;
  border: 1px solid #ddd;
  border-radius: 4px;
  font-size: 14px;
}

.search-btn {
  padding: 10px 20px;
  background: #007bff;
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  font-weight: 500;
}

.search-btn:hover:not(:disabled) {
  background: #0056b3;
}

.search-btn:disabled {
  background: #ccc;
  cursor: not-allowed;
}

.loading, .error, .empty {
  padding: 40px;
  text-align: center;
  color: #666;
}

.error {
  color: #c62828;
}

.rooms-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  gap: 20px;
}

.room-card {
  border: 1px solid #ddd;
  border-radius: 8px;
  padding: 20px;
  cursor: pointer;
  transition: all 0.3s;
  background: white;
}

.room-card:hover {
  box-shadow: 0 4px 12px rgba(0,0,0,0.15);
  transform: translateY(-2px);
}

.room-header {
  margin-bottom: 15px;
}

.room-header h3 {
  margin: 0 0 5px 0;
  color: #333;
  font-size: 18px;
}

.location {
  display: inline-block;
  padding: 4px 8px;
  background: #f8f9fa;
  color: #666;
  border-radius: 4px;
  font-size: 12px;
}

.room-details {
  margin-bottom: 15px;
}

.detail {
  display: flex;
  justify-content: space-between;
  margin-bottom: 8px;
  font-size: 14px;
}

.label {
  color: #666;
}

.value {
  font-weight: 500;
  color: #333;
}

.value.price {
  color: #28a745;
  font-weight: bold;
}

.view-btn {
  width: 100%;
  padding: 8px;
  background: #28a745;
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  font-weight: 500;
}

.view-btn:hover {
  background: #218838;
}
</style>
