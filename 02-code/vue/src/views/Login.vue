<template>
  <div class="login-page">
    <div class="login-box">
      <h2>Login</h2>
      
      <form @submit.prevent="handleLogin" class="login-form">
        <div class="form-group">
          <label>Email</label>
          <input 
            type="text" 
            v-model="username"
            required
            placeholder="Enter your email"
            :disabled="loading"
          />
        </div>
        
        <div class="form-group">
          <label>Password</label>
          <input 
            type="password" 
            v-model="password"
            required
            placeholder="Enter your password"
            :disabled="loading"
          />
        </div>
        
        <button type="submit" :disabled="loading" class="submit-btn">
          {{ loading ? 'Logging in...' : 'Login' }}
        </button>
        
        <div v-if="error" class="error">
          {{ error }}
        </div>
        
        <div class="register-link">
          <span>Need an account?</span>
          <router-link to="/register">Register</router-link>
        </div>
      </form>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { authService } from '@/services/auth.service'

const router = useRouter()
const username = ref('')
const password = ref('')
const loading = ref(false)
const error = ref('')

onMounted(() => {
  if (authService.isAuthenticated()) {
    router.push('/dashboard')
  }
})

const handleLogin = async () => {
  error.value = ''
  
  if (!username.value.trim() || !password.value) {
    error.value = 'Please enter email and password'
    return
  }
  
  loading.value = true
  
  try {
    const result = await authService.login(username.value, password.value)
    
    if (result.success) {
      router.push('/dashboard')
    } else {
      error.value = result.error || 'Login failed'
    }
  } catch (err) {
    error.value = 'Login error. Please try again.'
  } finally {
    loading.value = false
  }
}
</script>

<style scoped>
.login-page {
  display: flex;
  justify-content: center;
  align-items: center;
  min-height: 100vh;
  background: #f5f5f5;
  padding: 20px;
}

.login-box {
  width: 100%;
  max-width: 400px;
  background: white;
  padding: 40px;
  border-radius: 8px;
  box-shadow: 0 2px 10px rgba(0,0,0,0.1);
}

h2 {
  text-align: center;
  margin: 0 0 30px 0;
  color: #333;
  font-size: 24px;
}

.form-group {
  margin-bottom: 20px;
}

label {
  display: block;
  margin-bottom: 8px;
  font-weight: 500;
  color: #555;
}

input {
  width: 100%;
  padding: 12px;
  border: 1px solid #ddd;
  border-radius: 4px;
  font-size: 16px;
  box-sizing: border-box;
}

input:focus {
  outline: none;
  border-color: #007bff;
}

input:disabled {
  background: #f8f8f8;
}

.submit-btn {
  width: 100%;
  padding: 12px;
  background: #007bff;
  color: white;
  border: none;
  border-radius: 4px;
  font-size: 16px;
  font-weight: 500;
  cursor: pointer;
  margin-top: 10px;
}

.submit-btn:hover:not(:disabled) {
  background: #0056b3;
}

.submit-btn:disabled {
  background: #ccc;
  cursor: not-allowed;
}

.error {
  margin-top: 15px;
  padding: 10px;
  background: #ffebee;
  color: #c62828;
  border-radius: 4px;
  font-size: 14px;
  text-align: center;
}

.register-link {
  margin-top: 20px;
  text-align: center;
  color: #666;
  font-size: 14px;
}

.register-link a {
  color: #007bff;
  text-decoration: none;
  margin-left: 5px;
}

.register-link a:hover {
  text-decoration: underline;
}
</style>