import axios from 'axios'

const API_GATEWAY_URL = import.meta.env.VITE_API_URL || 'http://localhost:8080'

export const authService = {
  async register(name, email, password) {
    try {
      const response = await axios.post(`${API_GATEWAY_URL}/auth/register`, {
        name: name,
        email: email,
        password: password
      }, {
        headers: {
          'Content-Type': 'application/json'
        }
      })

      // Your API returns 201 Created with no body on success
      if (response.status === 201) {
        return {
          success: true,
          message: 'Registration successful! Please login.'
        }
      }

      return { success: false, error: 'Registration failed' }

    } catch (error) {
      console.error('Registration failed:', error)

      if (error.response) {
        switch (error.response.status) {
          case 400:
            return {
              success: false,
              error: 'Invalid request data'
            }
          case 409:
            return {
              success: false,
              error: 'User already exists with this email'
            }
          case 500:
            return {
              success: false,
              error: 'Server error. Please try again later.'
            }
          default:
            return {
              success: false,
              error: error.response.data?.error || 'Registration failed'
            }
        }
      }

      return {
        success: false,
        error: 'Network error. Please check your connection.'
      }
    }
  },

  async login(username, password) {
    try {
      const response = await axios.post(`${API_GATEWAY_URL}/auth/login`, {
        username: username,
        password: password
      }, {
        headers: {
          'Content-Type': 'application/json'
        }
      })

      if (response.status === 200 && response.data.token) {
        // Store token
        localStorage.setItem('auth_token', response.data.token)
        localStorage.setItem('username', username)

        return {
          success: true,
          data: response.data,
          message: 'Login successful!'
        }
      }

      return { success: false, error: 'Login failed' }

    } catch (error) {
      console.error('Login failed:', error)

      if (error.response) {
        switch (error.response.status) {
          case 400:
            return {
              success: false,
              error: 'Invalid request data'
            }
          case 401:
            return {
              success: false,
              error: 'Invalid username or password'
            }
          case 500:
            return {
              success: false,
              error: 'Server error. Please try again later.'
            }
          default:
            return {
              success: false,
              error: error.response.data?.error || 'Login failed'
            }
        }
      }

      return {
        success: false,
        error: 'Network error. Please check your connection.'
      }
    }
  },

  logout() {
    localStorage.removeItem('auth_token')
    localStorage.removeItem('username')
  },

  isAuthenticated() {
    return !!localStorage.getItem('auth_token')
  },

  getAuthHeader() {
    const token = localStorage.getItem('auth_token')
    return token ? {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json'
    } : {}
  },

  getCurrentUsername() {
    return localStorage.getItem('username')
  }
}
