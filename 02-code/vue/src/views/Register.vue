<template>
  <div class="register-page">
    <div class="register-box">
      <h2>Register</h2>
      
      <form @submit.prevent="handleRegister" class="register-form">
        <div class="form-group">
          <label>Full Name</label>
          <input 
            type="text" 
            v-model="form.name"
            required
            placeholder="Enter your full name"
            :disabled="loading"
          />
        </div>
        
        <div class="form-group">
          <label>Email</label>
          <input 
            type="email" 
            v-model="form.email"
            required
            placeholder="Enter your email"
            :disabled="loading"
          />
        </div>
        
        <div class="form-group">
          <label>Password</label>
          <input 
            type="password" 
            v-model="form.password"
            required
            placeholder="Create a password"
            :disabled="loading"
            minlength="6"
          />
          <div class="hint">Minimum 6 characters</div>
        </div>
        
        <div class="form-group">
          <label>Confirm Password</label>
          <input 
            type="password" 
            v-model="form.confirmPassword"
            required
            placeholder="Confirm your password"
            :disabled="loading"
          />
          <div v-if="form.confirmPassword && !passwordsMatch" class="hint error">
            Passwords do not match
          </div>
        </div>
        
        <button type="submit" :disabled="loading || !passwordsMatch" class="submit-btn">
          {{ loading ? 'Creating account...' : 'Register' }}
        </button>
        
        <div v-if="error" class="error">
          {{ error }}
        </div>
        
        <div v-if="success" class="success">
          {{ success }}
        </div>
        
        <div class="login-link">
          <span>Already have an account?</span>
          <router-link to="/login">Login</router-link>
        </div>
      </form>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, computed } from 'vue'
import { useRouter } from 'vue-router'
import { authService } from '@/services/auth.service'

const router = useRouter()
const loading = ref(false)
const error = ref('')
const success = ref('')

const form = reactive({
  name: '',
  email: '',
  password: '',
  confirmPassword: ''
})

const passwordsMatch = computed(() => {
  return form.password === form.confirmPassword
})

const validateForm = () => {
  if (!form.name.trim()) {
    error.value = 'Name is required'
    return false
  }
  
  if (!form.email.trim()) {
    error.value = 'Email is required'
    return false
  }
  
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
  if (!emailRegex.test(form.email)) {
    error.value = 'Please enter a valid email'
    return false
  }
  
  if (form.password.length < 6) {
    error.value = 'Password must be at least 6 characters'
    return false
  }
  
  if (!passwordsMatch.value) {
    error.value = 'Passwords do not match'
    return false
  }
  
  return true
}

const handleRegister = async () => {
  if (!validateForm()) return
  
  loading.value = true
  error.value = ''
  success.value = ''
  
  const result = await authService.register(
    form.name,
    form.email,
    form.password
  )
  
  if (result.success) {
    success.value = result.message || 'Account created successfully'
    
    // Clear form
    form.name = ''
    form.email = ''
    form.password = ''
    form.confirmPassword = ''
    
    // Redirect after 2 seconds
    setTimeout(() => {
      router.push('/login')
    }, 2000)
  } else {
    error.value = result.error
  }
  
  loading.value = false
}
</script>

<style scoped>
.register-page {
  display: flex;
  justify-content: center;
  align-items: center;
  min-height: 100vh;
  background: #f5f5f5;
  padding: 20px;
}

.register-box {
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

.hint {
  font-size: 12px;
  color: #666;
  margin-top: 5px;
}

.hint.error {
  color: #c62828;
}

.submit-btn {
  width: 100%;
  padding: 12px;
  background: #28a745;
  color: white;
  border: none;
  border-radius: 4px;
  font-size: 16px;
  font-weight: 500;
  cursor: pointer;
  margin-top: 10px;
}

.submit-btn:hover:not(:disabled) {
  background: #218838;
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

.success {
  margin-top: 15px;
  padding: 10px;
  background: #e8f5e9;
  color: #2e7d32;
  border-radius: 4px;
  font-size: 14px;
  text-align: center;
}

.login-link {
  margin-top: 20px;
  text-align: center;
  color: #666;
  font-size: 14px;
}

.login-link a {
  color: #007bff;
  text-decoration: none;
  margin-left: 5px;
}

.login-link a:hover {
  text-decoration: underline;
}
</style>