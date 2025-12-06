import ReactMarkdown from 'react-markdown'
import remarkGfm from 'remark-gfm'
import rehypeHighlight from 'rehype-highlight'
import 'highlight.js/styles/github-dark.css'
import { Button } from './ui/button'
import { Check, CopySimple } from '@phosphor-icons/react'
import { useState, ReactNode } from 'react'
import { cn } from '@/lib/utils'

interface MarkdownViewerProps {
  content: string
}

// Helper function to extract text content from React children
function extractTextContent(children: ReactNode): string {
  if (typeof children === 'string') {
    return children
  }
  if (typeof children === 'number') {
    return String(children)
  }
  if (Array.isArray(children)) {
    return children.map(extractTextContent).join('')
  }
  if (children && typeof children === 'object' && 'props' in children) {
    return extractTextContent((children as any).props?.children)
  }
  return ''
}

function CodeBlock({ children, className, rawText }: { children: ReactNode; className?: string; rawText: string }) {
  const [copied, setCopied] = useState(false)

  const handleCopy = async () => {
    await navigator.clipboard.writeText(rawText)
    setCopied(true)
    setTimeout(() => setCopied(false), 2000)
  }

  return (
    <div className="code-block-wrapper">
      <pre className={className}>
        <code>{children}</code>
      </pre>
      <Button
        size="sm"
        variant="ghost"
        onClick={handleCopy}
        className={cn(
          "copy-button h-7 text-xs",
          copied 
            ? "bg-success hover:bg-success text-success-foreground" 
            : "bg-accent hover:bg-accent/90 text-accent-foreground"
        )}
      >
        {copied ? (
          <>
            <Check size={14} weight="bold" className="mr-1.5" />
            Copied
          </>
        ) : (
          <>
            <CopySimple size={14} weight="bold" className="mr-1.5" />
            Copy
          </>
        )}
      </Button>
    </div>
  )
}

export function MarkdownViewer({ content }: MarkdownViewerProps) {
  return (
    <div className="markdown-content prose prose-slate max-w-none">
      <ReactMarkdown
        remarkPlugins={[remarkGfm]}
        rehypePlugins={[rehypeHighlight]}
        components={{
          code({ node, className, children, ...props }) {
            const match = /language-(\w+)/.exec(className || '')
            const isInline = !match

            if (isInline) {
              return (
                <code className={className} {...props}>
                  {children}
                </code>
              )
            }

            // Extract raw text for copy functionality
            const rawText = extractTextContent(children).replace(/\n$/, '')

            return (
              <CodeBlock className={className} rawText={rawText}>
                {children}
              </CodeBlock>
            )
          },
        }}
      >
        {content}
      </ReactMarkdown>
    </div>
  )
}
