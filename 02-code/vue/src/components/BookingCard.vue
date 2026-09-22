<template>
  <div class="booking-card">
    <div class="card-header">
      <h3>{{ booking.roomName }}</h3>
      <span class="price">£{{ booking.price }}/night</span>
    </div>

    <div class="card-body">
      <div class="info-row">
        <span class="label">Dates:</span>
        <span class="value">{{ formatDates(booking.startDate, booking.endDate) }}</span>
      </div>

      <div class="info-row">
        <span class="label">Capacity:</span>
        <span class="value">{{ booking.capacity }} people</span>
      </div>

      <div class="info-row">
        <span class="label">Amenities:</span>
        <span class="value">{{ booking.amenities.join(', ') }}</span>
      </div>
    </div>

    <div class="card-footer">
      <button @click="handleBook" class="book-btn">
        Book Now
      </button>
    </div>
  </div>
</template>

<script setup>
const props = defineProps({
  booking: {
    type: Object,
    required: true
  }
})

const emit = defineEmits(['book'])

const formatDates = (start, end) => {
  const startDate = new Date(start).toLocaleDateString()
  const endDate = new Date(end).toLocaleDateString()
  return `${startDate} - ${endDate}`
}

const handleBook = () => {
  emit('book', props.booking.id)
}
</script>

<style scoped>
.booking-card {
  background: white;
  border-radius: 10px;
  overflow: hidden;
  box-shadow: 0 4px 6px rgba(0,0,0,0.1);
  transition: transform 0.3s, box-shadow 0.3s;
}

.booking-card:hover {
  transform: translateY(-5px);
  box-shadow: 0 10px 15px rgba(0,0,0,0.1);
}

.card-header {
  padding: 1.5rem;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.price {
  font-size: 1.5rem;
  font-weight: 700;
}

.card-body {
  padding: 1.5rem;
}

.info-row {
  display: flex;
  justify-content: space-between;
  margin-bottom: 0.75rem;
  padding-bottom: 0.75rem;
  border-bottom: 1px solid #e2e8f0;
}

.info-row:last-child {
  margin-bottom: 0;
  border-bottom: none;
}

.label {
  font-weight: 600;
  color: #4a5568;
}

.value {
  color: #718096;
  text-align: right;
  max-width: 60%;
}

.card-footer {
  padding: 1rem 1.5rem;
  background: #f7fafc;
  border-top: 1px solid #e2e8f0;
}

.book-btn {
  width: 100%;
  padding: 0.75rem;
  background: #48bb78;
  color: white;
  border: none;
  border-radius: 5px;
  font-size: 1rem;
  font-weight: 600;
  cursor: pointer;
  transition: background 0.3s;
}

.book-btn:hover {
  background: #38a169;
}
</style>
