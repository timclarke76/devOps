import axios from 'axios'
import { authService } from './auth.service'

const API_GATEWAY_URL = import.meta.env.VITE_API_URL || 'http://localhost:8080'

export const loggingService = {
  async getEmails() {
    try {
      const response = await axios.get(
        `${API_GATEWAY_URL}/logging/emails`,
        { headers: authService.getAuthHeader() }
      )
      
      // Filter out empty emails and format timestamps
      const emails = response.data
        .filter(item => item.TemplateName && item.Recipient) // Only show emails with content
        .map(item => {
          return {
            id: item.ID,
            templateName: item.TemplateName,
            recipient: item.Recipient,
            subject: item.Subject,
            body: item.Body,
            time: new Date(item.Time).toLocaleString(),
            sentAt: item.SentAt ? new Date(item.SentAt).toLocaleString() : 'Not sent'
          }
        })
        .sort((a, b) => new Date(b.time) - new Date(a.time)) // Sort by most recent first
      
      return { success: true, data: emails }
    } catch (error) {
      console.error('Failed to fetch emails:', error)
      return { 
        success: false, 
        error: error.response?.data?.message || 'Failed to load emails' 
      }
    }
  }
}