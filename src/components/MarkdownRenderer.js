import React from 'react';
import ReactMarkdown from 'react-markdown';
import { Prism as SyntaxHighlighter } from 'react-syntax-highlighter';
import { vscDarkPlus } from 'react-syntax-highlighter/dist/esm/styles/prism';

const MarkdownRenderer = ({ content }) => {
  return (
    <ReactMarkdown
      components={{
        code({ node, inline, className, children, ...props }) {
          const match = /language-(\w+)/.exec(className || '');

          const handleCopy = () => {
            navigator.clipboard.writeText(children);
          };

          return !inline && match ? (
            <div style={{ position: 'relative', backgroundColor: '#2d2d2d', borderRadius: '5px', overflow: 'hidden' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '0.5em 1em', backgroundColor: '#333', color: '#ddd', fontSize: '0.9em' }}>
                <span>{match[1]}</span>
                <button onClick={handleCopy} style={{ background: 'none', border: 'none', color: '#ddd', cursor: 'pointer', fontSize: '0.9em' }}>
                  Copy code
                </button>
              </div>
              <SyntaxHighlighter
                style={vscDarkPlus}
                language={match[1]}
                PreTag="div"
                {...props}
                customStyle={{ margin: 0 }}
              >
                {String(children).replace(/\n$/, '')}
              </SyntaxHighlighter>
            </div>
          ) : (
            <code className={className} {...props}>
              {children}
            </code>
          );
        },
      }}
    >
      {content}
    </ReactMarkdown>
  );
};

export default MarkdownRenderer;
