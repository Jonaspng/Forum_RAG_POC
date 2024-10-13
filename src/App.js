import React, { useState, useEffect, useRef } from 'react';
import axios from 'axios';
import 'react-markdown-editor-lite/lib/index.css';
import 'highlight.js/styles/vs2015.css';
import './App.css';
import MarkdownRenderer from './components/MarkdownRenderer';
import Sidebar from './components/Sidebar';
import { Menu, Paperclip, File, X } from 'lucide-react';

function App() {
  const [messages, setMessages] = useState([]);
  const [input, setInput] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [selectedFile, setSelectedFile] = useState(null);
  const messagesEndRef = useRef(null);
  const [isSidebarOpen, setIsSidebarOpen] = useState(true);
  const inputRef = useRef(null);
  const fileInputRef = useRef(null);
  const [filePreview, setFilePreview] = useState(null);

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  useEffect(scrollToBottom, [messages]);
  useEffect(() => {
    inputRef.current.focus();
  }, []);

  const evaluation_result_to_text = (data) => {
    const faithfulness = data["faithfulness_score"]
    const answerRelevance = data["answer_relevance_score"]
    const contextRelevance = data["context_relevance_score"]

    const text = `
    context_relevance_score: ${contextRelevance}
    answer_relevance_score: ${answerRelevance}
    faithfulness_score ${faithfulness}
    `
    return text
  }

  const sendMessage = async (e) => {
    e.preventDefault();
    if (!input.trim() && !selectedFile) return;

    let userMessage = { role: 'user', content: input };
    userMessage.image = filePreview;
    setMessages((prevMessages) => [...prevMessages, userMessage]);
    setInput('');
    setSelectedFile(null);
    setFilePreview(null);
    setIsLoading(true);

    try {

      const formData = new FormData();
      if (selectedFile) {
        formData.append('file', selectedFile);
      }
      formData.append('query', input);

      if (input.trim()) {
        const response = await axios.post('http://localhost:3000/queries', formData, {
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        });

        const assistantMessage = response.data["response"];
        const evaluation = evaluation_result_to_text(response.data["evaluation"])
        setMessages((prevMessages) => [...prevMessages, { role: 'assistant', content: assistantMessage }]);
        setMessages((prevMessages) => [...prevMessages, { role: 'assistant', content: evaluation }])
      }
    } catch (error) {
      console.error('Error:', error);
    } finally {
      setIsLoading(false);
    }
  };

  const handleFileUpload = async (file, chunking_method) => {
    const formData = new FormData();
    formData.append('file', file);
    formData.append('option', chunking_method)
    const userMessage = { role: 'user', content: `Uploaded file: ${file.name}` };
    setMessages((prevMessages) => [...prevMessages, userMessage]);
    setIsLoading(true);

    try {
      const response = await axios.post('http://localhost:3000/upload_course_material', formData, {
        headers: {
          'Content-Type': 'multipart/form-data',
        },
      });
      const assistantMessage = { role: 'assistant', content: `Success: ${response.data.message}` };
      setMessages((prevMessages) => [...prevMessages, assistantMessage]);
    } catch (error) {
      const errorMessage = { role: 'assistant', content: error.response.data.error };
      setMessages((prevMessages) => [...prevMessages, errorMessage]);
    } finally {
      setIsLoading(false);
    }
  };

  const toggleSidebar = () => {
    setIsSidebarOpen(!isSidebarOpen);
  };

  const handleFileSelect = (e) => {
    const file = e.target.files[0];
    setSelectedFile(file);

    if (file) {
      if (file.type.startsWith('image/')) {
        const reader = new FileReader();
        reader.onload = (e) => setFilePreview(e.target.result);
        reader.readAsDataURL(file);
      } else {
        setFilePreview(null);
      }
    } else {
      setFilePreview(null);
    }
  };

  const triggerFileInput = () => {
    fileInputRef.current.click();
  };

  const removeSelectedFile = () => {
    setSelectedFile(null);
    setFilePreview(null);
    if (fileInputRef.current) {
      fileInputRef.current.value = '';
    }
  };

  const formatFileSize = (bytes) => {
    if (bytes < 1024) return bytes + ' bytes';
    else if (bytes < 1048576) return (bytes / 1024).toFixed(1) + ' KB';
    else return (bytes / 1048576).toFixed(1) + ' MB';
  };

  const renderMessage = (message, index) => {
    return (
      <div key={index} className={`message ${message.role}`}>
        <div className="message-content">
          {message.image && (
            <img src={message.image} alt="Uploaded" className="message-image" />
          )}
          {message.role === 'user' ? (
            <p>{message.content}</p>
          ) : (
            <MarkdownRenderer content={message.content} />
          )}
        </div>
      </div>
    );
  };

  const onYoutubeLinkUpload = async (youtubeLink) => {
    if (youtubeLink) {
      const userMessage = { role: 'user', content: `Submitted Video Link: ${youtubeLink}` };
      setMessages((prevMessages) => [...prevMessages, userMessage]);
      setIsLoading(true);
      try {
        const response = await axios.post('http://localhost:3000/upload_video_captions', {
          link: youtubeLink
        });
        const assistantMessage = { role: 'assistant', content: `Success: ${response.data.message}` };
        setMessages((prevMessages) => [...prevMessages, assistantMessage]);
      } catch (error) {
        const errorMessage = { role: 'assistant', content: error.response.data.error };
        setMessages((prevMessages) => [...prevMessages, errorMessage]);
      } finally {
        setIsLoading(false);
      }
    }
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
          onLinkUpload={onYoutubeLinkUpload}
          isOpen={isSidebarOpen}
        />
        <div className={`chat-container ${!isSidebarOpen ? 'sidebar-closed' : ''}`}>
          {messages.map(renderMessage)}
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
        <button type="button" onClick={triggerFileInput} disabled={isLoading}>
          <Paperclip size={24} />
        </button>
        <input
          type="file"
          ref={fileInputRef}
          style={{ display: 'none' }}
          onChange={handleFileSelect}
        />
        <button type="submit" disabled={isLoading || (!input.trim() && !selectedFile)}>
          <svg viewBox="0 0 24 24" width="24" height="24">
            <path fill="currentColor" d="M2.01 21L23 12 2.01 3 2 10l15 2-15 2z" />
          </svg>
        </button>
      </form>
      {selectedFile && (
        <div className="file-preview">
          {filePreview ? (
            <img src={filePreview} alt="File preview" className="file-preview-image" />
          ) : (
            <div className="file-preview-icon">
              <File size={30} />
            </div>
          )}
          <div className="file-preview-details">
            <span className="file-preview-name">{selectedFile.name}</span>
            <span className="file-preview-size">{formatFileSize(selectedFile.size)}</span>
          </div>
          <button onClick={removeSelectedFile} className="file-preview-remove">
            <X size={24} />
          </button>
        </div>
      )}
    </div>
  );
}

export default App;