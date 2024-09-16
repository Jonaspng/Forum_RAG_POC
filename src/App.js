import React, { useState, useEffect, useRef } from 'react';
import axios from 'axios';
import 'react-markdown-editor-lite/lib/index.css';
import 'highlight.js/styles/vs2015.css';
import './App.css';
import MarkdownRenderer from './components/MarkdownRenderer';
import Sidebar from './components/Sidebar';
import { Menu } from 'lucide-react';

function App() {
  const [messages, setMessages] = useState([]);
  const [input, setInput] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const messagesEndRef = useRef(null);
  const [isSidebarOpen, setIsSidebarOpen] = useState(true);
  const inputRef = useRef(null);

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  useEffect(scrollToBottom, [messages]);
  useEffect(() => {
    inputRef.current.focus();
  }, []);

  const sendMessage = async (e) => {
    e.preventDefault();
    if (!input.trim()) return;

    const userMessage = { role: 'user', content: input };
    setMessages((prevMessages) => [...prevMessages, userMessage]);
    setInput('');
    setIsLoading(true);

    try {
      const response = await axios.post('http://localhost:3000/forum_data', {
        question: input,
      });
      
      const assistantMessage = response.data["openai/gpt-4o"].generated_text;

      setMessages((prevMessages) => [...prevMessages, { role: 'assistant', content: assistantMessage }]);
    } catch (error) {
      console.error('Error:', error);
    } finally {
      setIsLoading(false);
    }
  };

  const handleFileUpload = async (file) => {
    const formData = new FormData();
    formData.append('file', file);

    try {
      const response = await axios.post('http://localhost:3000/upload_course_material', formData, {
        headers: {
          'Content-Type': 'multipart/form-data',
        },
      });

      const userMessage = { role: 'user', content: `Uploaded file: ${file.name}` };
      console.log(response.data)
      const assistantMessage = { role: 'assistant', content: `File uploaded successfully: ${response.data.message}` };
      setMessages((prevMessages) => [...prevMessages, userMessage, assistantMessage]);
    } catch (error) {
      console.error('Error uploading file:', error);
      const errorMessage = { role: 'assistant', content: 'Error uploading file. Please try again.' };
      setMessages((prevMessages) => [...prevMessages, errorMessage]);
    }
  };

  const toggleSidebar = () => {
    setIsSidebarOpen(!isSidebarOpen);
  };

  return (
    <div className="App">
      <header className="App-header">
        <button onClick={toggleSidebar} className="sidebar-toggle">
          <Menu size={24} />
        </button>
        <h1>AI Chat</h1>
      </header>
      <div className="main-container">
        <Sidebar 
          onFileUpload={handleFileUpload} 
          isOpen={isSidebarOpen}
        />
        <div className={`chat-container ${!isSidebarOpen ? 'sidebar-closed' : ''}`}>
          {messages.map((message, index) => (
            <div key={index} className={`message ${message.role}`}>
              <div className="message-content">
                {message.role === 'user' ? (
                  <p>{message.content}</p>
                ) : (
                  <MarkdownRenderer content={message.content} />
                )}
              </div>
            </div>
          ))}
          {isLoading && (
            <div className="message assistant">
              <div className="message-content">
                <div className="typing-indicator">
                  <span></span>
                  <span></span>
                  <span></span>
                </div>
              </div>
            </div>
          )}
          <div ref={messagesEndRef} />
        </div>
      </div>
      <form onSubmit={sendMessage} className="input-form">
        <input
          ref={inputRef}
          type="text"
          value={input}
          onChange={(e) => setInput(e.target.value)}
          placeholder="Type a message..."
          disabled={isLoading}
        />
        <button type="submit" disabled={isLoading || !input.trim()}>
          <svg viewBox="0 0 24 24" width="24" height="24">
            <path fill="currentColor" d="M2.01 21L23 12 2.01 3 2 10l15 2-15 2z" />
          </svg>
        </button>
      </form>
    </div>
  );
}

export default App;