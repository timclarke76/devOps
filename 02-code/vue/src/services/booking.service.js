import axios from 'axios'
import { authService } from './auth.service'

const API_GATEWAY_URL = import.meta.env.VITE_API_URL || 'http://localhost:8080'

export const bookingService = {
  async createBooking(bookingData) {
    try {
      const response = await axios.post(
        `${API_GATEWAY_URL}/booking/createBooking`,
        {
          customer_email: bookingData.customerEmail,
          location: bookingData.location,
          room_name: bookingData.roomName,
          booking_date: bookingData.bookingDate
        },
        { headers: authService.getAuthHeader() }
      )
      return { success: true, data: response.data }
    } catch (error) {
      console.error('Booking failed:', error)
      return { 
        success: false, 
        error: error.response?.data?.error || error.response?.data?.message || 'Booking failed' 
      }
    }
  },

  async checkAvailability(location, roomName, bookingDate) {
    try {
      console.log('Checking availability with params:', { 
        location, 
        roomName, 
        bookingDate
      });
      
      const response = await axios.get(
        `${API_GATEWAY_URL}/booking/checkAvailability`,
        {
          params: {
            Location: location,           // Capital L
            RoomName: roomName,           // Capital R, N
            BookingDate: bookingDate      // Capital B, D
          },
          headers: authService.getAuthHeader()
        }
      )
      
      console.log('Availability response:', response.data);
      return { success: true, data: response.data }
    } catch (error) {
      console.error('Availability check failed:', error);
      console.error('Error details:', {
        status: error.response?.status,
        data: error.response?.data,
        config: error.config
      });
      
      // Try with lowercase parameters as fallback
      if (error.response?.status === 400) {
        console.log('Trying with lowercase parameters...');
        try {
          const fallbackResponse = await axios.get(
            `${API_GATEWAY_URL}/booking/checkAvailability`,
            {
              params: {
                location: location,
                room_name: roomName,
                booking_date: bookingDate
              },
              headers: authService.getAuthHeader()
            }
          )
          return { success: true, data: fallbackResponse.data }
        } catch (fallbackError) {
          console.error('Fallback also failed:', fallbackError);
        }
      }
      
      return { 
        success: false, 
        error: error.response?.data?.error || error.response?.data?.message || 'Availability check failed',
        status: error.response?.status
      }
    }
  }
}