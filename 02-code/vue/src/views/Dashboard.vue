<template>
  <div class="dashboard">
    <header class="header">
      <h1>Available Room Bookings</h1>
      <button @click="handleLogout" class="logout-btn">Logout</button>
    </header>
    
    <main class="main-content">
      <div v-if="loading" class="loading">
        Loading bookings...
      </div>
      
      <div v-else-if="error" class="error">
        {{ error }}
        <button @click="loadBookings" class="retry-btn">Retry</button>
      </div>
      
      <div v-else-if="bookings.length === 0" class="empty-state">
        No available bookings found.
      </div>
      
      <div v-else class="bookings-grid">
        <BookingCard 
          v-for="booking in bookings" 
          :key="booking.id"
          :booking="booking"
          @book="handleBook"
        />
      </div>
    </main>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { authService } from '@/services/auth.service'
import { bookingService } from '@/services/booking.service'
import BookingCard from '@/components/BookingCard.vue'

const router = useRouter()
const bookings = ref([])
const loading = ref(true)
const error = ref('')

const loadBookings = async () => {
  loading.value = true
  error.value = ''
  
  const result = await bookingService.getAvailableBookings()
  
  if (result.success) {
    bookings.value = result.data
  } else {
    error.value = result.error
  }
  
  loading.value = false
}

const handleBook = async (bookingId) => {
  const result = await bookingService.bookRoom(bookingId)
  
  if (result.success) {
    alert('Booking successful!')
    loadBookings() // Refresh the list
  } else {
    alert(`Booking failed: ${result.error}`)
  }
}

const handleLogout = () => {
  authService.logout()
  router.push('/login')
}

onMounted(() => {
  if (!authService.isAuthenticated()) {
    router.push('/login')
  } else {
    loadBookings()
  }
})
</script>

<style scoped>
.dashboard {
  min-height: 100vh;
  background: #f7fafc;
}

.header {
  background: white;
  padding: 1rem 2rem;
  display: flex;
  justify-content: space-between;
  align-items: center;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
}

.logout-btn {
  padding: 0.5rem 1rem;
  background: #e53e3e;
  color: white;
  border: none;
  border-radius: 5px;
  cursor: pointer;
  font-weight: 600;
}

.logout-btn:hover {
  background: #c53030;
}

.main-content {
  padding: 2rem;
  max-width: 1200px;
  margin: 0 auto;
}

.loading, .error, .empty-state {
  text-align: center;
  padding: 3rem;
  font-size: 1.25rem;
  color: #718096;
}

.error {
  color: #e53e3e;
}

.retry-btn {
  margin-top: 1rem;
  padding: 0.5rem 1rem;
  background: #4299e1;
  color: white;
  border: none;
  border-radius: 5px;
  cursor: pointer;
}

.bookings-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  gap: 1.5rem;
}
</style>