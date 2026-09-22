<template>
  <div class="room-detail-page">
    <div class="navigation">
      <router-link to="/" class="nav-link">Home</router-link>
      <router-link to="/rooms" class="nav-link">Rooms</router-link>
      <router-link to="/bookings" class="nav-link">My Bookings</router-link>
      <router-link to="/emails" class="nav-link">Email Logs</router-link>
      <button @click="logout" class="logout-btn">Logout</button>
    </div>

    <div class="room-detail-container">
      <button @click="goBack" class="back-btn">← Back to Rooms</button>

      <div v-if="loading" class="loading">
        Loading room details...
      </div>

      <div v-else-if="error" class="error">
        {{ error }}
        <button @click="loadRoom">Retry</button>
      </div>

      <div v-else-if="room" class="room-content">
        <div class="room-header">
          <h2>{{ room.name }}</h2>
          <div class="location-badge">{{ room.location }}</div>
        </div>

        <div class="room-info">
          <div class="info-item">
            <span class="label">Location:</span>
            <span class="value">{{ room.location }}</span>
          </div>
          <div class="info-item">
            <span class="label">Capacity:</span>
            <span class="value">{{ room.capacity }} people</span>
          </div>
          <div class="info-item" v-if="room.temperature !== undefined">
            <span class="label">Outdoor Temperature:</span>
            <span class="value">{{ room.temperature.toFixed(1) }}°C</span>
          </div>
          <div class="info-item">
            <span class="label">Booking Date:</span>
            <span class="value">{{ formatDate(selectedDate) }}</span>
          </div>
          <div class="info-item">
            <span class="label">Availability:</span>
            <span class="value" :class="availabilityClass">
              {{ availabilityText }}
            </span>
          </div>
        </div>

        <div class="pricing-section">
          <h3>Pricing Details</h3>
          <div class="pricing-info">
            <div class="price-item">
              <span class="label">Base Price:</span>
              <span class="value base-price">£{{ formatPrice(room.base_price) }}</span>
            </div>

            <div class="price-item" v-if="room.temp_percent_adjust !== undefined">
              <span class="label">Temperature Adjustment:</span>
              <span class="value" :class="getAdjustmentClass(room.temp_percent_adjust)">
                {{ formatAdjustment(room.temp_percent_adjust) }}
              </span>
            </div>

            <div class="price-item" v-if="room.temp_adjust !== undefined">
              <span class="label">Price Change:</span>
              <span class="value" :class="getAdjustmentClass(room.temp_adjust)">
                {{ formatPriceChange(room.temp_adjust) }}
              </span>
            </div>

            <div class="price-divider"></div>

            <div class="price-item final-price">
              <span class="label">Final Price:</span>
              <span class="value price">£{{ formatPrice(room.price) }}</span>
            </div>

            <div class="price-note" v-if="room.temp_adjust !== undefined && room.temp_adjust !== 0">
              <p>
                <strong>Note:</strong>
                {{ getAdjustmentExplanation(room.temp_percent_adjust, room.temperature) }}
              </p>
            </div>
          </div>
        </div>

        <div class="booking-section">
          <h3>Book This Room</h3>
          <div class="booking-info">
            <p><strong>Room:</strong> {{ room.name }}</p>
            <p><strong>Date:</strong> {{ formatDate(selectedDate) }}</p>
            <p><strong>Price:</strong>
              <span class="final-price-text">£{{ formatPrice(room.price) }}</span>
            </p>
            <p><strong>Status:</strong>
              <span :class="availabilityClass">
                {{ availabilityText }}
              </span>
            </p>
          </div>

          <div v-if="!isAvailable" class="availability-warning">
            <p>This room is not available for booking on {{ formatDate(selectedDate) }}.</p>
            <p>Please select a different date or room.</p>
          </div>

          <button
            @click="bookRoom"
            :disabled="!isAvailable || bookingLoading || checkingAvailability"
            class="book-btn"
            :class="{ 'disabled': !isAvailable }"
          >
            {{ getButtonText() }}
          </button>

          <div v-if="bookingSuccess" class="success">
            Booking successful for {{ formatDate(selectedDate) }}!
          </div>
          <div v-if="bookingError" class="error">
            {{ bookingError }}
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, computed, onMounted, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { authService } from '@/services/auth.service'
import { roomService } from '@/services/room.service'
import { bookingService } from '@/services/booking.service'

const route = useRoute()
const router = useRouter()
const room = ref(null)
const loading = ref(false)
const error = ref('')
const checkingAvailability = ref(false)
const availability = ref(null)
const bookingLoading = ref(false)
const bookingSuccess = ref(false)
const bookingError = ref('')

const location = decodeURIComponent(route.params.location)
const name = decodeURIComponent(route.params.name)

const formatDate = (dateString) => {
  const date = new Date(dateString)
  return date.toLocaleDateString('en-GB', {
    weekday: 'long',
    year: 'numeric',
    month: 'long',
    day: 'numeric'
  })
}

const formatPrice = (priceInPence) => {
  return (priceInPence / 100).toFixed(2)
}

const formatAdjustment = (percent) => {
  const sign = percent >= 0 ? '+' : ''
  return `${sign}${percent.toFixed(1)}%`
}

const formatPriceChange = (adjustmentInPence) => {
  const sign = adjustmentInPence >= 0 ? '+' : ''
  return `${sign}£${formatPrice(adjustmentInPence)}`
}

const getAdjustmentClass = (value) => {
  if (value > 0) return 'positive'
  if (value < 0) return 'negative'
  return 'neutral'
}

const getAdjustmentExplanation = (percent, temperature) => {
  if (percent > 0) {
    return `The price has increased by ${percent.toFixed(1)}% because the outdoor temperature is ${temperature.toFixed(1)}°C.`
  } else if (percent < 0) {
    return `The price has decreased by ${Math.abs(percent).toFixed(1)}% because the outdoor temperature is ${temperature.toFixed(1)}°C.`
  } else {
    return `The price is unchanged as the outdoor temperature is ${temperature.toFixed(1)}°C.`
  }
}

// Get the date from the route query parameters or use today's date as fallback
const selectedDate = computed(() => {
  return route.query.date || new Date().toISOString().split('T')[0]
})

const filters = reactive({
  location: location,
  date: selectedDate.value
})

// Watch for date changes in the URL
watch(selectedDate, (newDate) => {
  filters.date = newDate
  if (room.value) {
    checkAvailability()
  }
})

const isAvailable = computed(() => {
  return availability.value === true
})

const availabilityText = computed(() => {
  if (checkingAvailability.value) return 'Checking...'
  if (availability.value === true) return 'Available'
  if (availability.value === false) return 'Not Available'
  return 'Unknown'
})

const availabilityClass = computed(() => {
  if (availability.value === true) return 'available'
  if (availability.value === false) return 'unavailable'
  return ''
})

const getButtonText = () => {
  if (checkingAvailability.value) return 'Checking Availability...'
  if (bookingLoading.value) return 'Booking...'
  if (!isAvailable.value) return 'Room Unavailable'
  return `Book Now - £${formatPrice(room.value.price)}`
}

const checkAvailability = async () => {
  if (!room.value) return

  checkingAvailability.value = true

  try {
    const result = await bookingService.checkAvailability(location, name, selectedDate.value)

    if (result.success) {
      availability.value = result.data.available
    } else {
      availability.value = false
    }
  } catch (err) {
    console.error('Error checking availability:', err)
    availability.value = false
  } finally {
    checkingAvailability.value = false
  }
}

const loadRoom = async () => {
  if (!authService.isAuthenticated()) {
    router.push('/login')
    return
  }

  loading.value = true
  error.value = ''

  try {
    const result = await roomService.getRoom(location, name, filters.date)

    if (result.success && result.data.length > 0) {
      room.value = result.data[0]
      console.log('Room data loaded:', room.value)
      // After loading room, check availability
      await checkAvailability()
    } else {
      error.value = 'Room not found'
    }
  } catch (err) {
    error.value = 'Failed to load room details'
    console.error(err)
  } finally {
    loading.value = false
  }
}

const bookRoom = async () => {
  if (!isAvailable.value) {
    bookingError.value = 'Cannot book an unavailable room'
    return
  }

  bookingLoading.value = true
  bookingError.value = ''
  bookingSuccess.value = false

  try {
    // First, double-check availability
    await checkAvailability()

    if (!isAvailable.value) {
      bookingError.value = 'Room is no longer available for booking'
      bookingLoading.value = false
      return
    }

    // Get current user's email from auth service or localStorage
    const userEmail = authService.getCurrentUsername() || ''

    if (!userEmail) {
      bookingError.value = 'User email not found. Please login again.'
      bookingLoading.value = false
      return
    }

    // Create booking using the correct API endpoint
    const bookingResult = await bookingService.createBooking({
      customerEmail: userEmail,
      location: location,
      roomName: name,
      bookingDate: selectedDate.value
    })

    if (bookingResult.success) {
      bookingSuccess.value = true
      // Refresh availability after successful booking
      await checkAvailability()
    } else {
      bookingError.value = bookingResult.error
    }
  } catch (err) {
    bookingError.value = 'Booking failed'
    console.error(err)
  } finally {
    bookingLoading.value = false
  }
}

const goBack = () => {
  router.push('/rooms')
}

const logout = () => {
  authService.logout()
  router.push('/login')
}

onMounted(() => {
  if (!authService.isAuthenticated()) {
    router.push('/login')
  } else {
    loadRoom()
  }
})
</script>

<style scoped>
.room-detail-page {
  padding: 20px;
  max-width: 800px;
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
  padding: 8px 12px;
  text-decoration: none;
  color: #666;
  font-weight: 500;
  font-size: 14px;
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

.room-detail-container {
  background: white;
  padding: 30px;
  border-radius: 8px;
  box-shadow: 0 2px 10px rgba(0,0,0,0.1);
}

.back-btn {
  background: none;
  border: none;
  color: #007bff;
  cursor: pointer;
  font-size: 16px;
  margin-bottom: 20px;
  padding: 0;
}

.back-btn:hover {
  text-decoration: underline;
}

.loading, .error {
  padding: 40px;
  text-align: center;
  color: #666;
}

.error {
  color: #c62828;
}

.room-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 30px;
}

.room-header h2 {
  margin: 0;
  color: #333;
  font-size: 28px;
}

.location-badge {
  background: #007bff;
  color: white;
  padding: 8px 20px;
  border-radius: 20px;
  font-size: 16px;
  font-weight: 500;
}

.room-info {
  margin-bottom: 30px;
  padding: 20px;
  background: #f8f9fa;
  border-radius: 8px;
}

.info-item {
  display: flex;
  justify-content: space-between;
  padding: 12px 0;
  border-bottom: 1px solid #dee2e6;
}

.info-item:last-child {
  border-bottom: none;
}

.label {
  color: #666;
  font-weight: 500;
  font-size: 15px;
}

.value {
  color: #333;
  font-size: 15px;
}

.value.available {
  color: #28a745;
  font-weight: bold;
}

.value.unavailable {
  color: #dc3545;
  font-weight: bold;
}

.pricing-section {
  margin-bottom: 30px;
  padding: 25px;
  background: #f8f9fa;
  border-radius: 8px;
  border: 1px solid #dee2e6;
}

.pricing-section h3 {
  margin: 0 0 20px 0;
  color: #333;
  font-size: 20px;
  border-bottom: 1px solid #dee2e6;
  padding-bottom: 10px;
}

.pricing-info {
  background: white;
  padding: 20px;
  border-radius: 6px;
}

.price-item {
  display: flex;
  justify-content: space-between;
  padding: 12px 0;
  border-bottom: 1px solid #f0f0f0;
}

.price-item:last-child {
  border-bottom: none;
}

.price-item.final-price {
  border-top: 2px solid #dee2e6;
  margin-top: 10px;
  padding-top: 15px;
}

.base-price {
  color: #666;
  text-decoration: line-through;
}

.positive {
  color: #dc3545;
  font-weight: bold;
}

.negative {
  color: #28a745;
  font-weight: bold;
}

.neutral {
  color: #666;
}

.price {
  font-size: 24px;
  font-weight: bold;
  color: #28a745;
}

.price-divider {
  height: 1px;
  background: linear-gradient(to right, transparent, #dee2e6, transparent);
  margin: 15px 0;
}

.price-note {
  margin-top: 15px;
  padding: 12px;
  background: #e7f3ff;
  border-radius: 4px;
  border-left: 4px solid #007bff;
  font-size: 14px;
  color: #333;
}

.price-note p {
  margin: 0;
  line-height: 1.5;
}

.booking-section {
  padding: 25px;
  background: #f8f9fa;
  border-radius: 8px;
}

.booking-section h3 {
  margin: 0 0 20px 0;
  color: #333;
  font-size: 20px;
}

.booking-info {
  margin-bottom: 20px;
  padding: 15px;
  background: white;
  border-radius: 4px;
  border: 1px solid #dee2e6;
}

.booking-info p {
  margin: 10px 0;
  color: #333;
  font-size: 15px;
}

.booking-info .available {
  color: #28a745;
  font-weight: bold;
}

.booking-info .unavailable {
  color: #dc3545;
  font-weight: bold;
}

.booking-info .final-price-text {
  color: #28a745;
  font-weight: bold;
  font-size: 16px;
}

.availability-warning {
  margin-bottom: 20px;
  padding: 15px;
  background: #fff3cd;
  color: #856404;
  border: 1px solid #ffeaa7;
  border-radius: 4px;
}

.availability-warning p {
  margin: 5px 0;
}

.book-btn {
  width: 100%;
  padding: 14px;
  background: #28a745;
  color: white;
  border: none;
  border-radius: 4px;
  font-size: 16px;
  font-weight: 500;
  cursor: pointer;
}

.book-btn:hover:not(:disabled):not(.disabled) {
  background: #218838;
}

.book-btn:disabled,
.book-btn.disabled {
  background: #6c757d;
  cursor: not-allowed;
}

.book-btn:disabled:hover,
.book-btn.disabled:hover {
  background: #6c757d;
}

.success {
  margin-top: 15px;
  padding: 12px;
  background: #d4edda;
  color: #155724;
  border-radius: 4px;
  text-align: center;
  font-weight: 500;
}
</style>
