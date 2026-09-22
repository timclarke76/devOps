<template>
  <div class="email-logs-page">
    <div class="navigation">
      <router-link to="/" class="nav-link">Home</router-link>
      <router-link to="/rooms" class="nav-link">Rooms</router-link>
      <router-link to="/bookings" class="nav-link">My Bookings</router-link>
      <button @click="logout" class="logout-btn">Logout</button>
    </div>
    
    <div class="email-logs-container">
      <h1>Email Logs</h1>
      
      <div class="controls">
        <button @click="refreshEmails" :disabled="loading" class="refresh-btn">
          {{ loading ? 'Loading...' : 'Refresh' }}
        </button>
        <div class="stats" v-if="emails.length > 0">
          {{ emails.length }} email{{ emails.length !== 1 ? 's' : '' }}
        </div>
      </div>
      
      <div v-if="loading" class="loading">
        <div class="spinner"></div>
        Loading email logs...
      </div>
      
      <div v-else-if="error" class="error">
        <p>{{ error }}</p>
        <button @click="loadEmails" class="retry-btn">Retry</button>
      </div>
      
      <div v-else-if="emails.length === 0" class="empty-state">
        No email logs found.
      </div>
      
      <div v-else class="emails-list">
        <div v-for="email in emails" :key="email.id" class="email-card">
          <div class="email-header">
            <span class="email-time">{{ email.time }}</span>
          </div>
          
          <div class="email-details">
            <div class="detail-row">
              <span class="label">To:</span>
              <span class="value recipient">{{ email.recipient }}</span>
            </div>
            
            <div class="detail-row">
              <span class="label">Subject:</span>
              <span class="value subject">{{ email.subject }}</span>
            </div>
            
            <div class="detail-row">
              <span class="label">Message:</span>
              <span class="value body">{{ email.body }}</span>
            </div>
            
            <div class="detail-row">
              <span class="label">Template:</span>
              <span class="value template">{{ email.templateName }}</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { authService } from '@/services/auth.service'
import { loggingService } from '@/services/logging.service'

const router = useRouter()
const emails = ref([])
const loading = ref(false)
const error = ref('')

const loadEmails = async () => {
  if (!authService.isAuthenticated()) {
    router.push('/login')
    return
  }
  
  loading.value = true
  error.value = ''
  
  try {
    const result = await loggingService.getEmails()
    
    if (result.success) {
      emails.value = result.data
    } else {
      error.value = result.error
    }
  } catch (err) {
    error.value = 'Failed to load email logs'
    console.error(err)
  } finally {
    loading.value = false
  }
}

const refreshEmails = () => {
  loadEmails()
}

const logout = () => {
  authService.logout()
  router.push('/login')
}

onMounted(() => {
  if (!authService.isAuthenticated()) {
    router.push('/login')
  } else {
    loadEmails()
  }
})
</script>

<style scoped>
.email-logs-page {
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
  padding: 8px 16px;
  text-decoration: none;
  color: #666;
  font-weight: 500;
}

.nav-link:hover {
  color: #0056b3;
}

.nav-link.router-link-active {
  color: #0056b3;
  font-weight: bold;
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

.email-logs-container {
  background: white;
  padding: 30px;
  border-radius: 8px;
  box-shadow: 0 2px 10px rgba(0,0,0,0.1);
}

.email-logs-container h1 {
  margin: 0 0 25px 0;
  color: #333;
  font-size: 28px;
  border-bottom: 2px solid #007bff;
  padding-bottom: 10px;
}

.controls {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 25px;
  padding: 15px;
  background: #f8f9fa;
  border-radius: 6px;
}

.refresh-btn {
  padding: 10px 20px;
  background: #007bff;
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  font-weight: 500;
  font-size: 14px;
}

.refresh-btn:hover:not(:disabled) {
  background: #0056b3;
}

.refresh-btn:disabled {
  background: #ccc;
  cursor: not-allowed;
}

.stats {
  color: #666;
  font-size: 14px;
  font-weight: 500;
}

.loading {
  padding: 40px;
  text-align: center;
  color: #666;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 15px;
}

.spinner {
  width: 40px;
  height: 40px;
  border: 3px solid #f3f3f3;
  border-top: 3px solid #007bff;
  border-radius: 50%;
  animation: spin 1s linear infinite;
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}

.error {
  padding: 30px;
  text-align: center;
  color: #c62828;
  background: #ffebee;
  border-radius: 6px;
  margin-bottom: 20px;
}

.error p {
  margin: 0 0 15px 0;
}

.retry-btn {
  padding: 8px 20px;
  background: #dc3545;
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
}

.retry-btn:hover {
  background: #c82333;
}

.empty-state {
  padding: 40px;
  text-align: center;
  color: #666;
  background: #f8f9fa;
  border-radius: 6px;
  border: 1px dashed #dee2e6;
  font-style: italic;
}

.emails-list {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.email-card {
  border: 1px solid #e0e0e0;
  border-radius: 8px;
  padding: 25px;
  background: white;
  box-shadow: 0 2px 4px rgba(0,0,0,0.05);
  transition: transform 0.2s, box-shadow 0.2s;
}

.email-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 8px rgba(0,0,0,0.1);
}

.email-header {
  display: flex;
  justify-content: flex-end;
  margin-bottom: 20px;
  padding-bottom: 15px;
  border-bottom: 1px solid #f0f0f0;
}

.email-time {
  font-size: 14px;
  color: #666;
  background: #f8f9fa;
  padding: 6px 12px;
  border-radius: 4px;
  font-weight: 500;
}

.email-details {
  display: flex;
  flex-direction: column;
  gap: 15px;
}

.detail-row {
  display: flex;
  align-items: flex-start;
}

.label {
  font-weight: 600;
  color: #333;
  min-width: 100px;
  margin-right: 15px;
  padding-top: 2px;
}

.value {
  color: #444;
  flex: 1;
  word-break: break-word;
  line-height: 1.5;
}

.value.recipient {
  color: #007bff;
  font-weight: 500;
}

.value.subject {
  color: #333;
  font-weight: 600;
  font-size: 16px;
}

.value.body {
  color: #555;
  font-style: italic;
}

.value.template {
  color: #28a745;
  font-weight: 500;
  background: #f8f9fa;
  padding: 4px 10px;
  border-radius: 4px;
  display: inline-block;
}
</style>