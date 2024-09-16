import React, { useState } from 'react';

const Sidebar = ({ onFileUpload, isOpen }) => {
  const [file, setFile] = useState(null);

  const handleFileChange = (e) => {
    const selectedFile = e.target.files[0];
    setFile(selectedFile);
  };

  const handleUpload = () => {
    if (file) {
      onFileUpload(file);
      setFile(null);
    }
  };

  return (
    <div className={`sidebar ${isOpen ? 'open' : 'closed'}`}>
      <h2>Upload Document</h2>
      <input
        type="file"
        id="file-upload"
        onChange={handleFileChange}
        accept=".txt,.pdf,.doc,.docx"
        style={{ display: 'none' }}
      />
      <label htmlFor="file-upload" className="file-upload-label">
        Choose File
      </label>
      {file && <p className="file-name">{file.name}</p>}
      <button 
        onClick={handleUpload} 
        disabled={!file}
        className={file ? 'upload-button active' : 'upload-button'}
      >
        Upload
      </button>
    </div>
  );
};

export default Sidebar;