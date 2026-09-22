import axios from 'axios'
import { authService } from './auth.service'

const API_GATEWAY_URL = import.meta.env.VITE_API_URL || 'http://localhost:8080'

export const roomService = {
  async getRooms(filters = {}) {
    try {
      const params = new URLSearchParams()
      
      if (filters.location) params.append('location', filters.location)
      if (filters.date) params.append('date', filters.date)
      
      const queryString = params.toString()
      const url = `${API_GATEWAY_URL}/room/${queryString ? '?' + queryString : ''}`
      
      console.log('Calling room API:', url)
      
      const response = await axios.get(url, {
        headers: authService.getAuthHeader()
      })
      
      return { success: true, data: response.data }
    } catch (error) {
      console.error('Room API error:', error)
      return { 
        success: false, 
        error: error.response?.data?.error || 'Failed to load rooms' 
      }
    }
  },

  async getRoom(location, name, date) {
    try {
      const params = new URLSearchParams()
      params.append('location', location)
      params.append('name', name)
      if (date) params.append('date', date)
      
      const url = `${API_GATEWAY_URL}/room/detail?${params.toString()}`
      
      console.log('Calling single room API:', url)
      
      const response = await axios.get(url, {
        headers: authService.getAuthHeader()
      })
      
      console.log('Single room response:', response.data)
      return { success: true, data: response.data }
    } catch (error) {
      console.error('Single room error:', error)
      return { 
        success: false, 
        error: error.response?.data?.error || 'Failed to load room' 
      }
    }
  },

  async bookRoom(location, name, date) {
    try {
      const response = await axios.post(`${API_GATEWAY_URL}/book`, {
        location,
        name,
        date
      }, {
        headers: authService.getAuthHeader()
      })
      
      return { success: true, data: response.data }
    } catch (error) {
      console.error('Failed to book room:', error)
      return { 
        success: false, 
        error: error.response?.data?.error || 'Booking failed' 
      }
    }
  }
}