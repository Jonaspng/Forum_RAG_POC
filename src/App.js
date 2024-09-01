import React, { useState, useEffect, useRef } from 'react';
import axios from 'axios';
import './App.css';

function App() {
  const [messages, setMessages] = useState([]);
  const [input, setInput] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const messagesEndRef = useRef(null);
  const inputRef = useRef(null);

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: "smooth" });
  }

  useEffect(scrollToBottom, [messages]);
  useEffect(() => {
    inputRef.current.focus();
  }, []);

  const fetchEmbedding = async (question) => {
    const options = {
      method: 'POST',
      url: 'https://api.edenai.run/v2/text/embeddings',
      headers: {
        accept: 'application/json',
        'content-type': 'application/json',
        authorization: process.env.REACT_APP_EMBEDDING_API
      },
      data: {
        response_as_dict: true,
        attributes_as_list: false,
        show_base_64: true,
        show_original_response: false,
        providers: ['openai/1536__text-embedding-ada-002'],
        texts: [question]
      }
    };
  
    try {
      const response = await axios.request(options);
      const result = response.data;  // Store the result in a const
      console.log(result);  // Use the result as needed
      return result;  // Optionally return the result for further use
    } catch (error) {
      console.error(error);
    }
  };

  const sendMessage = async (e) => {
    e.preventDefault();
    if (!input.trim()) return;

    const userMessage = { role: 'user', content: input };
    setMessages(prevMessages => [...prevMessages, userMessage]);
    setInput('');
    setIsLoading(true);

    const embedding = await fetchEmbedding(userMessage.content);
    try {
      const nearest_qna = await axios.post('http://localhost:3000/forum_data', {
        question_embedding: embedding['openai/1536__text-embedding-ada-002']['items'][0]['embedding']
      });
      console.log(nearest_qna)
      let assistantMessage = nearest_qna.data.map((item, index) => `${index + 1}) ${item.data.question}`)
        .join('\n');
      
      console.log(assistantMessage)
      assistantMessage = "Here are the semantically nearest questions that I found: \n" + assistantMessage

      setMessages(prevMessages => [...prevMessages, { role: 'assistant', content: assistantMessage }]);
    } catch (error) {
      console.error('Error:', error);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="App">
      <header className="App-header">
        <h1>AI Forum RAG</h1>
      </header>
      <div className="chat-container">
        {messages.map((message, index) => (
          <div key={index} className={`message ${message.role}`}>
            <div className="message-content">{message.content}</div>
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