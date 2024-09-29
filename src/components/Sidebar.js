import React, { useState } from 'react';;

const Sidebar = ({ onFileUpload, isOpen, onLinkUpload }) => {
  const [file, setFile] = useState(null);
  const [imageOption, setImageOption] = useState(null);
  const [youtubeLink, setYoutubeLink] = useState('');

  const handleFileChange = (e) => {
    const selectedFile = e.target.files[0];
    setFile(selectedFile);
    setImageOption(null); // Reset the image option when a new file is selected
  };

  const handleImageOption = (option) => {
    setImageOption(option);
  };

  const handleUpload = () => {
    if (file && imageOption != null) {
      onFileUpload(file, imageOption);
      setFile(null);
      setImageOption(null);
    }
  };

  const handleYoutubeLinkChange = (e) => {
    setYoutubeLink(e.target.value);
  };

  const handleYoutubeLinkSubmit = async () => {
    onLinkUpload(youtubeLink);
    setYoutubeLink('');
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

      {file && (
        <div className="chunking-options">
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
      )}

      <button
        onClick={handleUpload}
        disabled={!file || imageOption == null}
        className={`upload-button ${(file && imageOption != null) ? 'active' : ''}`}
      >
        Upload
      </button>

      <h2>Upload YouTube Captions</h2>
      <input
        type="text"
        value={youtubeLink}
        onChange={handleYoutubeLinkChange}
        placeholder="Enter YouTube video link"
        className="youtube-link-input"
      />
      <button
        onClick={handleYoutubeLinkSubmit}
        disabled={!youtubeLink}
        className={`upload-button ${youtubeLink ? 'active' : ''}`}
      >
        Upload Captions
      </button>
    </div>
  );
};

export default Sidebar;