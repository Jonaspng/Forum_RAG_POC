import React, { useState } from 'react';

const Sidebar = ({ onFileUpload, isOpen }) => {
  const [file, setFile] = useState(null);
  const [imageOption, setimageOption] = useState(null);

  const handleFileChange = (e) => {
    const selectedFile = e.target.files[0];
    setFile(selectedFile);
  };

  const handleImageOption = (option) => {
    setimageOption(option);
  };

  const handleUpload = () => {
    if (file && imageOption!=null) {
      onFileUpload(file, imageOption);
      setFile(null);
      setimageOption(null);
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

      <div className="chunking-options">
        <h3>Choose Chunking Method</h3>
        <button
          onClick={() => handleImageOption(false)}
          className={imageOption === false ? 'active' : ''}
        >
          Text only
        </button>
        <button
          onClick={() => handleImageOption(true)}
          className={imageOption === true ? 'active' : ''}
        >
          Text & Image
        </button>
      </div>

      <button
        onClick={handleUpload}
        disabled={!file || imageOption==null}
        className={`upload-button ${(file && imageOption!=null) ? 'active' : ''}`}
      >
        Upload
      </button>
    </div>
  );
};

export default Sidebar;